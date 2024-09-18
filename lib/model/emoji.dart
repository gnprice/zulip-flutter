import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';

/// An emoji, described by how to display it in the UI.
sealed class EmojiDisplay {
}

/// An emoji to display as Unicode text, relying on an emoji font.
class UnicodeEmojiDisplay extends EmojiDisplay {
  /// The actual Unicode text representing this emoji; for example, "🙂".
  final String emojiUnicode;

  UnicodeEmojiDisplay({required this.emojiUnicode});
}

/// An emoji to display as an image.
class ImageEmojiDisplay extends EmojiDisplay {
  /// An absolute URL for the emoji's image file.
  final Uri resolvedUrl;

  ImageEmojiDisplay({required this.resolvedUrl});
}

/// An emoji to display as its name, in plain text.
///
/// We do this based on a user preference,
/// and as a fallback when the Unicode or image approaches fail.
class TextEmojiDisplay extends EmojiDisplay {
  /// The emoji's name, as in [Reaction.emojiName].
  final String emojiName;

  TextEmojiDisplay({required this.emojiName});
}

/// The portion of [PerAccountStore] describing what emoji exist.
mixin EmojiStore {
  /// The realm's custom emoji (for [ReactionType.realmEmoji],
  /// indexed by [Reaction.emojiCode].
  Map<String, RealmEmojiItem> get realmEmoji;

  EmojiDisplay displayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
    required bool doNotAnimate,
  });
}

/// The implementation of [EmojiStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [EmojiStore] which describes its interface.
class EmojiStoreImpl with EmojiStore {
  EmojiStoreImpl({
    required this.realmUrl,
    required this.userSettings,
    required this.realmEmoji,
  });

  /// The same as [PerAccountStore.realmUrl].
  final Uri realmUrl;

  /// The same object as [PerAccountStore.userSettings].
  final UserSettings? userSettings;

  @override
  Map<String, RealmEmojiItem> realmEmoji;

  @override
  EmojiDisplay displayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
    required bool doNotAnimate,
  }) {
    if (userSettings?.emojiset == Emojiset.text) {
      return TextEmojiDisplay(emojiName: emojiName);
    }

    Uri? url;
    switch (emojiType) {
      case ReactionType.unicodeEmoji:
        final parsed = tryParseEmojiCodeToUnicode(emojiCode);
        if (parsed == null) break;
        return UnicodeEmojiDisplay(emojiUnicode: parsed);

      case ReactionType.realmEmoji:
        final item = realmEmoji[emojiCode];
        if (item == null) break;
        final src = doNotAnimate ? (item.stillUrl ?? item.sourceUrl)
          : item.sourceUrl;
        url = Uri.tryParse(src);
        break;

      case ReactionType.zulipExtraEmoji:
        url = Uri.parse('/static/generated/emoji/images/emoji/unicode/zulip.png');
        break;
    }
    if (url == null) return TextEmojiDisplay(emojiName: emojiName);
    return ImageEmojiDisplay(resolvedUrl: realmUrl.resolveUri(url));
  }

  void handleRealmEmojiUpdateEvent(RealmEmojiUpdateEvent event) {
    realmEmoji = event.realmEmoji;
  }
}
