import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../stdlib_checks.dart';
import 'content_checks.dart';

void main() {
  late PerAccountStore store;
  late FakeApiConnection connection;
  late MessageListView model;
  late int notifiedCount;

  void checkNotified({required int count}) {
    check(notifiedCount).equals(count);
    notifiedCount = 0;
  }
  void checkNotNotified() => checkNotified(count: 0);
  void checkNotifiedOnce() => checkNotified(count: 1);

  void prepare({required Narrow narrow}) {
    store = eg.store();
    connection = store.connection as FakeApiConnection;
    notifiedCount = 0;
    model = MessageListView.init(store: store, narrow: narrow)
      ..addListener(() {
        checkInvariants(model);
        notifiedCount++;
      });
    check(model).fetched.isFalse();
    checkInvariants(model);
    checkNotNotified();
  }

  Future<void> prepareMessages({
    required bool foundOldest,
    required List<Message> messages,
  }) async {
    connection.prepare(json:
      newestResult(foundOldest: foundOldest, messages: messages).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
  }

  void checkLastRequest({
    required ApiNarrow narrow,
    required String anchor,
    bool? includeAnchor,
    required int numBefore,
    required int numAfter,
  }) {
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('GET')
      ..url.path.equals('/api/v1/messages')
      ..url.queryParameters.deepEquals({
        'narrow': jsonEncode(narrow),
        'anchor': anchor,
        if (includeAnchor != null) 'include_anchor': includeAnchor.toString(),
        'num_before': numBefore.toString(),
        'num_after': numAfter.toString(),
      });
  }

  test('fetchInitial', () async {
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
    connection.prepare(json: newestResult(
      foundOldest: false,
      messages: List.generate(kMessageListFetchBatchSize,
        (i) => eg.streamMessage(id: 1000 + i)),
    ).toJson());
    final fetchFuture = model.fetchInitial();
    check(model).fetched.isFalse();
    checkInvariants(model);

    checkNotNotified();
    await fetchFuture;
    checkNotifiedOnce();
    check(model)
      ..messages.length.equals(kMessageListFetchBatchSize)
      ..haveOldest.isFalse();
    checkLastRequest(
      narrow: narrow.apiEncode(),
      anchor: 'newest',
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
  });

  test('fetchInitial, short history', () async {
    prepare(narrow: const AllMessagesNarrow());
    connection.prepare(json: newestResult(
      foundOldest: true,
      messages: List.generate(30, (i) => eg.streamMessage(id: 1000 + i)),
    ).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
    check(model)
      ..messages.length.equals(30)
      ..haveOldest.isTrue();
  });

  test('fetchInitial, no messages found', () async {
    prepare(narrow: const AllMessagesNarrow());
    connection.prepare(json: newestResult(
      foundOldest: true,
      messages: [],
    ).toJson());
    await model.fetchInitial();
    checkNotifiedOnce();
    check(model)
      ..fetched.isTrue()
      ..messages.isEmpty()
      ..haveOldest.isTrue();
  });

  test('fetchOlder', () async {
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
    await prepareMessages(foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

    connection.prepare(json: olderResult(
      anchor: 1000, foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 900 + i)),
    ).toJson());
    final fetchFuture = model.fetchOlder();
    checkNotifiedOnce();
    check(model).fetchingOlder.isTrue();

    await fetchFuture;
    checkNotifiedOnce();
    check(model)
      ..fetchingOlder.isFalse()
      ..messages.length.equals(200);
    checkLastRequest(
      narrow: narrow.apiEncode(),
      anchor: '1000',
      includeAnchor: false,
      numBefore: kMessageListFetchBatchSize,
      numAfter: 0,
    );
  });

  test('fetchOlder nop when already fetching', () async {
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
    await prepareMessages(foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

    connection.prepare(json: olderResult(
      anchor: 1000, foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 900 + i)),
    ).toJson());
    final fetchFuture = model.fetchOlder();
    checkNotifiedOnce();
    check(model).fetchingOlder.isTrue();

    // Don't prepare another response.
    final fetchFuture2 = model.fetchOlder();
    checkNotNotified();
    checkInvariants(model);
    check(model).fetchingOlder.isTrue();

    await fetchFuture;
    await fetchFuture2;
    // We must not have made another request, because we didn't
    // prepare another response and didn't get an exception.
    checkNotifiedOnce();
    check(model)
      ..fetchingOlder.isFalse()
      ..messages.length.equals(200);
  });

  test('fetchOlder nop when already haveOldest true', () async {
    prepare(narrow: const AllMessagesNarrow());
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i)));
    check(model)
      ..haveOldest.isTrue()
      ..messages.length.equals(30);

    await model.fetchOlder();
    // We must not have made a request, because we didn't
    // prepare a response and didn't get an exception.
    checkNotNotified();
    checkInvariants(model);
    check(model)
      ..haveOldest.isTrue()
      ..messages.length.equals(30);
  });

  test('fetchOlder handles servers not understanding includeAnchor', () async {
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
    await prepareMessages(foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)));

    // The old behavior is to include the anchor message regardless of includeAnchor.
    connection.prepare(json: olderResult(
      anchor: 1000, foundOldest: false, foundAnchor: true,
      messages: List.generate(101, (i) => eg.streamMessage(id: 900 + i)),
    ).toJson());
    await model.fetchOlder();
    checkNotified(count: 2);
    check(model)
      ..fetchingOlder.isFalse()
      ..messages.length.equals(200);
  });

  test('maybeAddMessage', () async {
    final stream = eg.stream();
    prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i, stream: stream)));

    check(model).messages.length.equals(30);
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: stream));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
  });

  test('maybeAddMessage, not in narrow', () async {
    final stream = eg.stream(streamId: 123);
    prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i, stream: stream)));

    check(model).messages.length.equals(30);
    final otherStream = eg.stream(streamId: 234);
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: otherStream));
    checkNotNotified();
    check(model).messages.length.equals(30);
  });

  test('maybeAddMessage, before fetch', () async {
    final stream = eg.stream();
    prepare(narrow: StreamNarrow(stream.streamId));
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: stream));
    checkNotNotified();
    check(model).fetched.isFalse();
    checkInvariants(model);
  });

  test('reassemble', () async {
    final stream = eg.stream();
    prepare(narrow: StreamNarrow(stream.streamId));
    await prepareMessages(foundOldest: true, messages:
      List.generate(30, (i) => eg.streamMessage(id: 1000 + i, stream: stream)));
    model.maybeAddMessage(eg.streamMessage(id: 1100, stream: stream));
    checkNotifiedOnce();
    check(model).messages.length.equals(31);

    // Mess with model.contents, to simulate it having come from
    // a previous version of the code.
    final correctContent = parseContent(model.messages[0].content);
    model.contents[0] = const ZulipContent(nodes: [
      ParagraphNode(links: null, nodes: [TextNode('something outdated')])
    ]);
    check(model.contents[0]).not(it()..equalsNode(correctContent));

    model.reassemble();
    checkNotifiedOnce();
    check(model).messages.length.equals(31);
    check(model.contents[0]).equalsNode(correctContent);
  });
}

void checkInvariants(MessageListView model) {
  if (!model.fetched) {
    check(model)
      ..messages.isEmpty()
      ..haveOldest.isFalse()
      ..fetchingOlder.isFalse();
  }
  if (model.haveOldest) {
    check(model).fetchingOlder.isFalse();
  }

  for (int i = 0; i < model.messages.length - 1; i++) {
    check(model.messages[i].id).isLessThan(model.messages[i+1].id);
  }

  check(model).contents.length.equals(model.messages.length);
  for (int i = 0; i < model.contents.length; i++) {
    check(model.contents[i])
      .equalsNode(parseContent(model.messages[i].content));
  }

  check(model).items.length.equals(
    ((model.haveOldest || model.fetchingOlder) ? 1 : 0)
    + model.messages.length);
  int i = 0;
  if (model.haveOldest) {
    check(model.items[i++]).isA<MessageListHistoryStartItem>();
  }
  if (model.fetchingOlder) {
    check(model.items[i++]).isA<MessageListLoadingItem>();
  }
  for (int j = 0; j < model.messages.length; j++) {
    check(model.items[i++]).isA<MessageListMessageItem>()
      ..message.identicalTo(model.messages[j])
      ..content.identicalTo(model.contents[j]);
  }
}

extension MessageListMessageItemChecks on Subject<MessageListMessageItem> {
  Subject<Message> get message => has((x) => x.message, 'message');
  Subject<ZulipContent> get content => has((x) => x.content, 'content');
}

extension MessageListViewChecks on Subject<MessageListView> {
  Subject<PerAccountStore> get store => has((x) => x.store, 'store');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
  Subject<List<Message>> get messages => has((x) => x.messages, 'messages');
  Subject<List<ZulipContent>> get contents => has((x) => x.contents, 'contents');
  Subject<List<MessageListItem>> get items => has((x) => x.items, 'items');
  Subject<bool> get fetched => has((x) => x.fetched, 'fetched');
  Subject<bool> get haveOldest => has((x) => x.haveOldest, 'haveOldest');
  Subject<bool> get fetchingOlder => has((x) => x.fetchingOlder, 'fetchingOlder');
}

/// A GetMessagesResult the server might return on an `anchor=newest` request.
GetMessagesResult newestResult({
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    // These anchor, foundAnchor, and foundNewest values are what the server
    // appears to always return when the request had `anchor=newest`.
    anchor: 10000000000000000, // that's 16 zeros
    foundAnchor: false,
    foundNewest: true,

    foundOldest: foundOldest,
    historyLimited: historyLimited,
    messages: messages,
  );
}

/// A GetMessagesResult the server might return when we request older messages.
GetMessagesResult olderResult({
  required int anchor,
  bool foundAnchor = false, // the value if the server understood includeAnchor false
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    anchor: anchor,
    foundAnchor: foundAnchor,
    foundNewest: false, // empirically always this, even when anchor happens to be latest
    foundOldest: foundOldest,
    historyLimited: historyLimited,
    messages: messages,
  );
}
