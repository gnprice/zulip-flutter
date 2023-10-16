import 'dart:async';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notif.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../stdlib_checks.dart';
import 'binding.dart';
import 'test_store.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  final account1 = eg.selfAccount.copyWith(id: 1);
  final account2 = eg.otherAccount.copyWith(id: 2);

  test('GlobalStore.perAccount sequential case', () async {
    final accounts = [account1, account2];
    final globalStore = LoadingTestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
      globalStore.completers[accounts[accountId - 1]]!;

    final future1 = globalStore.perAccount(1);
    final store1 = PerAccountStore.fromInitialSnapshot(
      account: account1,
      connection: FakeApiConnection.fromAccount(account1),
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(1).single.complete(store1);
    check(await future1).identicalTo(store1);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(completers(1)).length.equals(1);

    final future2 = globalStore.perAccount(2);
    final store2 = PerAccountStore.fromInitialSnapshot(
      account: account2,
      connection: FakeApiConnection.fromAccount(account2),
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(2).single.complete(store2);
    check(await future2).identicalTo(store2);
    check(await globalStore.perAccount(2)).identicalTo(store2);
    check(await globalStore.perAccount(1)).identicalTo(store1);

    // Only one loadPerAccount call was made per account.
    check(completers(1)).length.equals(1);
    check(completers(2)).length.equals(1);
  });

  test('GlobalStore.perAccount concurrent case', () async {
    final accounts = [account1, account2];
    final globalStore = LoadingTestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
      globalStore.completers[accounts[accountId - 1]]!;

    final future1a = globalStore.perAccount(1);
    final future1b = globalStore.perAccount(1);
    // These should produce just one loadPerAccount call.
    check(completers(1)).length.equals(1);

    final future2 = globalStore.perAccount(2);
    final store1 = PerAccountStore.fromInitialSnapshot(
      account: account1,
      connection: FakeApiConnection.fromAccount(account1),
      initialSnapshot: eg.initialSnapshot(),
    );
    final store2 = PerAccountStore.fromInitialSnapshot(
      account: account2,
      connection: FakeApiConnection.fromAccount(account2),
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(1).single.complete(store1);
    completers(2).single.complete(store2);
    check(await future1a).identicalTo(store1);
    check(await future1b).identicalTo(store1);
    check(await future2).identicalTo(store2);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(await globalStore.perAccount(2)).identicalTo(store2);
    check(completers(1)).length.equals(1);
    check(completers(2)).length.equals(1);
  });

  test('GlobalStore.perAccountSync', () async {
    final accounts = [account1, account2];
    final globalStore = LoadingTestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
      globalStore.completers[accounts[accountId - 1]]!;

    check(globalStore.perAccountSync(1)).isNull();
    final future1 = globalStore.perAccount(1);
    check(globalStore.perAccountSync(1)).isNull();
    final store1 = PerAccountStore.fromInitialSnapshot(
      account: account1,
      connection: FakeApiConnection.fromAccount(account1),
      initialSnapshot: eg.initialSnapshot(),
    );
    completers(1).single.complete(store1);
    await pumpEventQueue();
    check(globalStore.perAccountSync(1)).identicalTo(store1);
    check(await future1).identicalTo(store1);
    check(globalStore.perAccountSync(1)).identicalTo(store1);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(completers(1)).length.equals(1);
  });

  group('PerAccountStore.registerNotificationToken', () {
    late LivePerAccountStore store;
    late FakeApiConnection connection;

    void prepare() {
      store = eg.liveStore();
      connection = store.connection as FakeApiConnection;
    }

    void checkLastRequest({
      required String token,
    }) {
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/android_gcm_reg_id')
        ..bodyFields.deepEquals({
          'token': token,
        });
    }

    test('token already known', () async {
      // This tests the case where [NotificationService.start] has already
      // learned the token before the store is created.
      // (This is probably the common case.)
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      addTearDown(NotificationService.debugReset);
      await NotificationService.instance.start();

      // On store startup, send the token.
      prepare();
      connection.prepare(json: {});
      await store.registerNotificationToken();
      checkLastRequest(token: '012abc');

      // If the token changes, send it again.
      testBinding.firebaseMessaging.setToken('456def');
      connection.prepare(json: {});
      await null; // Run microtasks.  TODO use FakeAsync for these tests.
      checkLastRequest(token: '456def');
    });

    test('token initially unknown', () async {
      // This tests the case where the store is created while our
      // request for the token is still pending.
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      addTearDown(NotificationService.debugReset);
      final startFuture = NotificationService.instance.start();

      // On store startup, send nothing (because we have nothing to send).
      prepare();
      await store.registerNotificationToken();
      check(connection.lastRequest).isNull();

      // When the token later appears, send it.
      connection.prepare(json: {});
      await startFuture;
      checkLastRequest(token: '012abc');

      // If the token subsequently changes, send it again.
      testBinding.firebaseMessaging.setToken('456def');
      connection.prepare(json: {});
      await null; // Run microtasks.  TODO use FakeAsync for these tests.
      checkLastRequest(token: '456def');
    });
  });
}

class LoadingTestGlobalStore extends TestGlobalStore {
  LoadingTestGlobalStore({required super.accounts});

  Map<Account, List<Completer<PerAccountStore>>> completers = {};

  @override
  Future<PerAccountStore> loadPerAccount(Account account) {
    final completer = Completer<PerAccountStore>();
    (completers[account] ??= []).add(completer);
    return completer.future;
  }
}
