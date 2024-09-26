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

  @override
  Iterable<EmojiCandidate> emojiCandidatesMatching(String query) {
    if (query.isEmpty) {
      return (_allEmojiCandidates ??= [
        // TODO fix this logic for when realm emoji overrides Unicode emoji
        for (final entry in _serverEmojiData.entries)
          _emojiCandidateFor(
            emojiType: ReactionType.unicodeEmoji,
            emojiCode: entry.key, emojiName: entry.value.first,
            aliases: entry.value.length > 1 ? entry.value.sublist(1) : null),
        for (final entry in realmEmoji.entries)
          _emojiCandidateFor(
            emojiType: ReactionType.realmEmoji,
            emojiCode: entry.key, emojiName: entry.value.name,
            aliases: null),
        _emojiCandidateFor(emojiType: ReactionType.zulipExtraEmoji,
          emojiCode: 'zulip', emojiName: 'zulip',
          aliases: null),
      ]);
    }
    throw UnimplementedError(); // TODO filter emoji candidates
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
