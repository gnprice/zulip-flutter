import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/realm.dart';

/// An emoji, described by how to display it in the UI.
sealed class EmojiDisplay {
  /// The emoji's name, as in [Reaction.emojiName].
  final String emojiName;

  EmojiDisplay({required this.emojiName});

  EmojiDisplay resolve(UserSettings? userSettings) { // TODO(server-5)
    if (this is TextEmojiDisplay) return this;
    if (userSettings?.emojiset == Emojiset.text) {
      return TextEmojiDisplay(emojiName: emojiName);
    }
    return this;
  }
}

/// An emoji to display as Unicode text, relying on an emoji font.
class UnicodeEmojiDisplay extends EmojiDisplay {
  /// The actual Unicode text representing this emoji; for example, "🙂".
  final String emojiUnicode;

  UnicodeEmojiDisplay({required super.emojiName, required this.emojiUnicode});
}

/// An emoji to display as an image.
class ImageEmojiDisplay extends EmojiDisplay {
  /// An absolute URL for the emoji's image file.
  final Uri resolvedUrl;

  /// An absolute URL for a still version of the emoji's image file;
  /// compare [RealmEmojiItem.stillUrl].
  final Uri? resolvedStillUrl;

  ImageEmojiDisplay({
    required super.emojiName,
    required this.resolvedUrl,
    required this.resolvedStillUrl,
  });
}

/// An emoji to display as its name, in plain text.
///
/// We do this based on a user preference,
/// and as a fallback when the Unicode or image approaches fail.
class TextEmojiDisplay extends EmojiDisplay {
  TextEmojiDisplay({required super.emojiName});
}

/// An emoji that might be offered in an emoji picker UI.
final class EmojiCandidate {
  /// The Zulip "emoji type" for this emoji.
  final ReactionType emojiType;

  /// The Zulip "emoji code" for this emoji.
  ///
  /// This is the value that would appear in [Reaction.emojiCode].
  final String emojiCode;

  /// The Zulip "emoji name" to use for this emoji.
  ///
  /// This might not be the only name this emoji has; see [aliases].
  final String emojiName;

  /// Additional Zulip "emoji name" values for this emoji,
  /// to show in the emoji picker UI.
  List<String> get aliases => _aliases ?? const [];
  List<String>? _aliases;

  void addAlias(String alias) => (_aliases ??= []).add(alias);

  final EmojiDisplay emojiDisplay;

  EmojiCandidate({
    required this.emojiType,
    required this.emojiCode,
    required this.emojiName,
    required List<String>? aliases,
    required this.emojiDisplay,
  }) : _aliases = aliases;
}

/// The portion of [PerAccountStore] describing what emoji exist.
mixin EmojiStore {
  /// The realm's custom emoji (for [ReactionType.realmEmoji],
  /// indexed by [Reaction.emojiCode].
  Map<String, RealmEmojiItem> get realmEmoji;

  EmojiDisplay emojiDisplayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
  });

  Iterable<EmojiCandidate> emojiCandidatesMatching(String query);

  void setServerEmojiData(ServerEmojiData data);
}

/// The implementation of [EmojiStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [EmojiStore] which describes its interface.
class EmojiStoreImpl with EmojiStore {
  EmojiStoreImpl({
    required this.realmUrl,
    required this.realmEmoji,
  }) : _serverEmojiData = {}; // TODO start with a built-in list; TODO fetch to update

  /// The same as [PerAccountStore.realmUrl].
  final Uri realmUrl;

  @override
  Map<String, RealmEmojiItem> realmEmoji;

  /// The realm-relative URL of the unique "Zulip extra emoji", :zulip:.
  static const _kZulipEmojiUrl = '/static/generated/emoji/images/emoji/unicode/zulip.png';

  @override
  EmojiDisplay emojiDisplayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
  }) {
    switch (emojiType) {
      case ReactionType.unicodeEmoji:
        final parsed = tryParseEmojiCodeToUnicode(emojiCode);
        if (parsed == null) break;
        return UnicodeEmojiDisplay(emojiName: emojiName, emojiUnicode: parsed);

      case ReactionType.realmEmoji:
        final item = realmEmoji[emojiCode];
        if (item == null) break;
        return _tryImageEmojiDisplay(
          sourceUrl: item.sourceUrl, stillUrl: item.stillUrl,
          emojiName: emojiName);

      case ReactionType.zulipExtraEmoji:
        return _tryImageEmojiDisplay(
          sourceUrl: _kZulipEmojiUrl, stillUrl: null, emojiName: emojiName);
    }
    return TextEmojiDisplay(emojiName: emojiName);
  }

  EmojiDisplay _tryImageEmojiDisplay({
    required String sourceUrl,
    required String? stillUrl,
    required String emojiName,
  }) {
    final source = Uri.tryParse(sourceUrl);
    if (source == null) return TextEmojiDisplay(emojiName: emojiName);

    Uri? still;
    if (stillUrl != null) {
      still = Uri.tryParse(stillUrl);
      if (still == null) return TextEmojiDisplay(emojiName: emojiName);
    }

    return ImageEmojiDisplay(
      emojiName: emojiName,
      resolvedUrl: realmUrl.resolveUri(source),
      resolvedStillUrl: still == null ? null : realmUrl.resolveUri(still),
    );
  }

  // (Note this may be out of date; [UpdateMachine.fetchEmojiData]
  // sets it only after the store has been created.)
  Map<String, List<String>> _serverEmojiData;

  List<EmojiCandidate>? _allEmojiCandidates;

  EmojiCandidate _emojiCandidateFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
    required List<String>? aliases,
  }) {
    return EmojiCandidate(
      emojiType: emojiType, emojiCode: emojiCode, emojiName: emojiName,
      aliases: aliases,
      emojiDisplay: emojiDisplayFor(
        emojiType: emojiType, emojiCode: emojiCode, emojiName: emojiName));
  }

  List<EmojiCandidate> _generateAllCandidates() {
    final byEmojiName = <String, EmojiCandidate>{};
    for (final entry in _serverEmojiData.entries) {
      final emojiName = entry.value.first;
      byEmojiName[emojiName] = _emojiCandidateFor(
        emojiType: ReactionType.unicodeEmoji,
        emojiCode: entry.key, emojiName: emojiName,
        aliases: entry.value.length > 1 ? entry.value.sublist(1) : null);
    }
    for (final entry in realmEmoji.entries) {
      final emojiName = entry.value.name;
      byEmojiName[emojiName] = _emojiCandidateFor(
        emojiType: ReactionType.realmEmoji,
        emojiCode: entry.key, emojiName: emojiName,
        aliases: null);
    }
    // TODO does 'zulip' really override realm emoji?
    //   (This is copied from zulip-mobile's behavior.)
    byEmojiName['zulip'] = _emojiCandidateFor(
      emojiType: ReactionType.zulipExtraEmoji,
      emojiCode: 'zulip', emojiName: 'zulip',
      aliases: null);
    return byEmojiName.values.toList(growable: false);
  }

  // Compare query_matches_string_in_order in Zulip web:shared/src/typeahead.ts .
  bool _nameMatches(String emojiName, String adjustedQuery) {
    // TODO this assumes emojiName is already lower-case (and no diacritics)
    const String separator = '_';

    if (!adjustedQuery.contains(separator)) {
      // If the query is a single token (doesn't contain a separator),
      // the match can be anywhere in the string.
      return emojiName.contains(adjustedQuery);
    }

    // If there is a separator in the query, then we
    // require the match to start at the start of a token.
    // (E.g. for 'ab_cd_ef', query could be 'ab_c' or 'cd_ef',
    // but not 'b_cd_ef'.)
    return emojiName.startsWith(adjustedQuery)
      || emojiName.contains(separator + adjustedQuery);
  }

  // Compare get_emoji_matcher in Zulip web:shared/src/typeahead.ts .
  bool _candidateMatches(EmojiCandidate candidate, String adjustedQuery) {
    if (candidate.emojiDisplay case UnicodeEmojiDisplay(:var emojiUnicode)) {
      if (adjustedQuery == emojiUnicode) return true;
    }
    return _nameMatches(candidate.emojiName, adjustedQuery)
      || candidate.aliases.any((alias) => _nameMatches(alias, adjustedQuery));
  }

  @override
  Iterable<EmojiCandidate> emojiCandidatesMatching(String query) {
    _allEmojiCandidates ??= _generateAllCandidates();
    if (query.isEmpty) {
      return _allEmojiCandidates!;
    }

    final adjustedQuery = query.toLowerCase().replaceAll(' ', '_'); // TODO remove diacritics too
    final results = <EmojiCandidate>[];
    for (final candidate in _allEmojiCandidates!) {
      if (!_candidateMatches(candidate, adjustedQuery)) continue;
      results.add(candidate); // TODO reduce aliases to just matches
    }
    return results;
  }

  @override
  void setServerEmojiData(ServerEmojiData data) {
    _serverEmojiData = data.codeToNames;
    _allEmojiCandidates = null;
  }

  void handleRealmEmojiUpdateEvent(RealmEmojiUpdateEvent event) {
    realmEmoji = event.realmEmoji;
  }
}
