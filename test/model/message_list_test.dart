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

  void checkNotNotified() {
    check(notifiedCount).equals(0);
  }

  void checkNotifiedOnce() {
    check(notifiedCount).equals(1);
    notifiedCount = 0;
  }

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
    await model.fetch();
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

  test('fetch', () async {
    const narrow = AllMessagesNarrow();
    prepare(narrow: narrow);
    connection.prepare(json: newestResult(
      foundOldest: false,
      messages: List.generate(100, (i) => eg.streamMessage(id: 1000 + i)),
    ).toJson());
    final fetchFuture = model.fetch();
    check(model).fetched.isFalse();
    checkInvariants(model);

    checkNotNotified();
    await fetchFuture;
    checkNotifiedOnce();
    check(model).messages.length.equals(100);
    checkLastRequest(
      narrow: narrow.apiEncode(),
      anchor: 'newest',
      numBefore: 100,
      numAfter: 10,
    );
  });

  test('fetch, short history', () async {
    prepare(narrow: const AllMessagesNarrow());
    connection.prepare(json: newestResult(
      foundOldest: true,
      messages: List.generate(30, (i) => eg.streamMessage(id: 1000 + i)),
    ).toJson());
    await model.fetch();
    checkNotifiedOnce();
    check(model).messages.length.equals(30);
  });

  test('fetch, no messages found', () async {
    prepare(narrow: const AllMessagesNarrow());
    connection.prepare(json: newestResult(
      foundOldest: true,
      messages: [],
    ).toJson());
    await model.fetch();
    checkNotifiedOnce();
    check(model)
      ..fetched.isTrue()
      ..messages.isEmpty();
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
    check(model).messages.isEmpty();
  }

  for (int i = 0; i < model.messages.length - 1; i++) {
    check(model.messages[i].id).isLessThan(model.messages[i+1].id);
  }

  check(model).contents.length.equals(model.messages.length);
  for (int i = 0; i < model.contents.length; i++) {
    check(model.contents[i])
      .equalsNode(parseContent(model.messages[i].content));
  }
}

extension MessageListViewChecks on Subject<MessageListView> {
  Subject<PerAccountStore> get store => has((x) => x.store, 'store');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
  Subject<List<Message>> get messages => has((x) => x.messages, 'messages');
  Subject<List<ZulipContent>> get contents => has((x) => x.contents, 'contents');
  Subject<bool> get fetched => has((x) => x.fetched, 'fetched');
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
