import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/model.dart';
import '../api/route/messages.dart';
import 'content.dart';
import 'narrow.dart';
import 'store.dart';

/// The number of messages to fetch in each request.
const kMessageListFetchBatchSize = 100; // TODO tune

/// A message, or one of its siblings shown in the message list.
///
/// See [MessageListView.items], which is a list of these.
sealed class MessageListItem {
  const MessageListItem();
}

/// A message to show in the message list.
class MessageListMessageItem extends MessageListItem {
  final Message message;
  final ZulipContent content;

  MessageListMessageItem(this.message, this.content);
}

/// Indicates the app is loading more messages at the top or bottom.
class MessageListLoadingItem extends MessageListItem {
  const MessageListLoadingItem();
}

/// Indicates we've reached the oldest message in the narrow.
class MessageListHistoryStartItem extends MessageListItem {
  const MessageListHistoryStartItem();
}

/// The sequence of messages in a message list, and how to display them.
///
/// This comprises much of the guts of [MessageListView].
mixin _MessageSequence {
  /// The messages.
  ///
  /// See also [contents] and [items].
  final List<Message> messages = [];

  /// Whether [messages] and [items] represent the results of a fetch.
  ///
  /// This allows the UI to distinguish "still working on fetching messages"
  /// from "there are in fact no messages here".
  bool get fetched => _fetched;
  bool _fetched = false;

  /// Whether we know we have the oldest messages for this narrow.
  ///
  /// (Currently we always have the newest messages for the narrow,
  /// once [fetched] is true, because we start from the newest.)
  bool get haveOldest => _haveOldest;
  bool _haveOldest = false;

  /// Whether we are currently fetching the next batch of older messages.
  bool get fetchingOlder => _fetchingOlder;
  bool _fetchingOlder = false;

  /// The parsed message contents, as a list parallel to [messages].
  ///
  /// The i'th element is the result of parsing the i'th element of [messages].
  ///
  /// This information is completely derived from [messages].
  /// It exists as an optimization, to memoize the work of parsing.
  final List<ZulipContent> contents = [];

  /// The messages and their siblings in the UI, in order.
  ///
  /// This has a [MessageListMessageItem] corresponding to each element
  /// of [messages], in order.  It may have additional items interspersed
  /// before, between, or after the messages.
  ///
  /// This information is completely derived from [messages] and
  /// the flags [haveOldest] and [fetchingOlder].
  /// It exists as an optimization, to memoize that computation.
  final QueueList<MessageListItem> items = QueueList();

  /// Append [message] to [messages], and update derived data accordingly.
  ///
  /// The caller is responsible for ensuring this is an appropriate thing to do
  /// given [narrow], our state of being caught up, and other concerns.
  void _addMessage(Message message) {
    assert(contents.length == messages.length);
    messages.add(message);
    contents.add(parseContent(message.content));
    assert(contents.length == messages.length);
    _processMessage(messages.length - 1);
  }

  void _insertAllMessages(int index, Iterable<Message> toInsert) {
    // TODO parse/process messages in smaller batches, to not drop frames.
    //   On a Pixel 5, a batch of 100 messages takes ~15-20ms in _insertAllMessages.
    //   (Before that, ~2-5ms in jsonDecode and 0ms in fromJson,
    //   so skip worrying about those steps.)
    assert(contents.length == messages.length);
    messages.insertAll(index, toInsert);
    contents.insertAll(index, toInsert.map(
      (message) => parseContent(message.content)));
    assert(contents.length == messages.length);
    _reprocessAll();
  }

  /// Redo all computations from scratch, based on [messages].
  void _recompute() {
    assert(contents.length == messages.length);
    contents.clear();
    contents.addAll(messages.map((message) => parseContent(message.content)));
    assert(contents.length == messages.length);
    _reprocessAll();
  }

  /// Append to [items] based on the index-th message and its content.
  ///
  /// The previous messages in the list must already have been processed.
  /// This message must already have been parsed and reflected in [contents].
  void _processMessage(int index) {
    // This will get more complicated to handle the ways that messages interact
    // with the display of neighboring messages: sender headings #175,
    // recipient headings #174, and date separators #173.
    items.add(MessageListMessageItem(messages[index], contents[index]));
  }

  /// Update [items] to include markers at start and end as appropriate.
  void _updateEndMarkers() {
    assert(!(haveOldest && fetchingOlder));
    switch ((items.firstOrNull, fetchingOlder, haveOldest)) {
      case (MessageListLoadingItem(),      true, _): break;
      case (MessageListLoadingItem(),      _, true): items[0] = const MessageListHistoryStartItem();
      case (MessageListLoadingItem(),      _,    _): items.removeFirst();

      case (MessageListHistoryStartItem(), true, _): items[0] = const MessageListLoadingItem();
      case (MessageListHistoryStartItem(), _, true): break;
      case (MessageListHistoryStartItem(), _,    _): items.removeFirst();

      case (_,                             true, _): items.addFirst(const MessageListLoadingItem());
      case (_,                             _, true): items.addFirst(const MessageListHistoryStartItem());
      case (_,                             _,    _): break;
    }
  }

  /// Recompute [items] from scratch, based on [messages], [contents], and flags.
  void _reprocessAll() {
    items.clear();
    for (var i = 0; i < messages.length; i++) {
      _processMessage(i);
    }
    _updateEndMarkers();
  }
}

/// A view-model for a message list.
///
/// The owner of one of these objects must call [dispose] when the object
/// will no longer be used, in order to free resources on the [PerAccountStore].
///
/// Lifecycle:
///  * Create with [init].
///  * Add listeners with [addListener].
///  * Fetch messages with [fetchInitial].  When the fetch completes, this object
///    will notify its listeners (as it will any other time the data changes.)
///  * Fetch more messages as needed with [fetchOlder].
///  * On reassemble, call [reassemble].
///  * When the object will no longer be used, call [dispose] to free
///    resources on the [PerAccountStore].
class MessageListView with ChangeNotifier, _MessageSequence {
  MessageListView._({required this.store, required this.narrow});

  factory MessageListView.init(
      {required PerAccountStore store, required Narrow narrow}) {
    final view = MessageListView._(store: store, narrow: narrow);
    store.registerMessageList(view);
    return view;
  }

  @override
  void dispose() {
    store.unregisterMessageList(this);
    super.dispose();
  }

  final PerAccountStore store;
  final Narrow narrow;

  /// Fetch messages, starting from scratch.
  Future<void> fetchInitial() async {
    // TODO(#80): fetch from anchor firstUnread, instead of newest
    // TODO(#82): fetch from a given message ID as anchor
    assert(!fetched && !haveOldest && !fetchingOlder);
    assert(messages.isEmpty && contents.isEmpty);
    // TODO schedule all this in another isolate
    final result = await getMessages(store.connection,
      narrow: narrow.apiEncode(),
      anchor: AnchorCode.newest,
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
    for (final message in result.messages) {
      _addMessage(message);
    }
    _fetched = true;
    _haveOldest = result.foundOldest;
    _updateEndMarkers();
    notifyListeners();
  }

  /// Fetch the next batch of older messages, if applicable.
  Future<void> fetchOlder() async {
    if (haveOldest) return;
    if (fetchingOlder) return;
    assert(fetched);
    assert(messages.isNotEmpty);
    final stopwatch = Stopwatch()..start();
    _fetchingOlder = true;
    _updateEndMarkers();
    notifyListeners();
    try {
      final result = await getMessages(store.connection,
        narrow: narrow.apiEncode(),
        anchor: NumericAnchor(messages[0].id),
        includeAnchor: false,
        numBefore: kMessageListFetchBatchSize,
        numAfter: 0,
      );
      debugPrint("fetching: ${stopwatch.elapsed.inMilliseconds}ms for request");
      stopwatch.reset();

      if (result.messages.isNotEmpty
          && result.messages.last.id == messages[0].id) {
        // TODO(server-6): includeAnchor should make this impossible
        result.messages.removeLast();
      }

      _insertAllMessages(0, result.messages);
      _haveOldest = result.foundOldest;
      debugPrint("fetching: ${stopwatch.elapsed.inMilliseconds}ms for processing");
      stopwatch.stop();
      debugPrint("fetched older -> ${messages.length} messages in list");
    } finally {
      _fetchingOlder = false;
      _updateEndMarkers();
      notifyListeners();
    }
  }

  /// Add [message] to this view, if it belongs here.
  ///
  /// Called in particular when we get a [MessageEvent].
  void maybeAddMessage(Message message) {
    if (!narrow.containsMessage(message)) {
      return;
    }
    if (!_fetched) {
      // TODO mitigate this fetch/event race: save message to add to list later
      return;
    }
    // TODO insert in middle instead, when appropriate
    _addMessage(message);
    notifyListeners();
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo from scratch any computations we can, such as parsing
  /// message contents.  It won't repeat network requests.
  void reassemble() {
    _recompute();
    notifyListeners();
  }
}
