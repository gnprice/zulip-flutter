import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import 'store.dart';

/// The portion of [PerAccountStore] describing user groups.
mixin UserGroupStore on PerAccountStoreBase {
  /// The user group with the given ID, if any.
  UserGroup? getGroup(int userGroupId);

  /// All non-deactivated user groups in the realm.
  ///
  /// For when deactivated groups are desired too, see [allGroups].
  Iterable<UserGroup> get activeGroups;

  /// All user groups in the realm, even those deactivated.
  ///
  /// Consider using [activeGroups] instead.
  Iterable<UserGroup> get allGroups;

  /// Whether the self-user is a (transitive) member of the given group,
  /// a group-setting value.
  bool selfInGroupSetting(GroupSettingValue value);
}

mixin ProxyUserGroupStore on UserGroupStore {
  @protected
  UserGroupStore get userGroupStore;

  @override
  UserGroup? getGroup(int userGroupId) => userGroupStore.getGroup(userGroupId);
  @override
  Iterable<UserGroup> get activeGroups => userGroupStore.activeGroups;
  @override
  Iterable<UserGroup> get allGroups => userGroupStore.allGroups;
  @override
  bool selfInGroupSetting(GroupSettingValue value)
    => userGroupStore.selfInGroupSetting(value);
}

abstract class HasUserGroupStore extends PerAccountStoreBase with UserGroupStore, ProxyUserGroupStore {
  HasUserGroupStore({required UserGroupStore groups})
    : userGroupStore = groups, super(core: groups.core);

  @protected
  @override
  final UserGroupStore userGroupStore;
}

/// The implementation of [UserGroupStore] that does the work.
class UserGroupStoreImpl extends PerAccountStoreBase with UserGroupStore {
  factory UserGroupStoreImpl({
      required CorePerAccountStore core, required List<UserGroup> groups}) {
    final groupMap = <int, UserGroup>{};
    final reverseSubgroups = <int, Set<int>>{};
    final selfUserDirectGroups = <int>{};
    for (final group in groups) {
      groupMap[group.id] = group;
      reverseSubgroups[group.id] ??= {};
      for (final subgroupId in group.directSubgroupIds) {
        (reverseSubgroups[subgroupId] ??= {}).add(group.id);
      }
      if (group.members.contains(core.selfUserId)) {
        selfUserDirectGroups.add(group.id);
      }
    }
    return UserGroupStoreImpl._(core: core, groupMap,
      reverseSubgroups, selfUserDirectGroups);
  }

  UserGroupStoreImpl._(
    this._groups,
    this._reverseSubgroups, this._selfUserDirectGroups, {
    required super.core,
  });

  @override
  UserGroup? getGroup(int userGroupId) {
    return _groups[userGroupId];
  }

  @override
  Iterable<UserGroup> get activeGroups {
    return _groups.values.where((group) => !group.deactivated);
  }

  @override
  Iterable<UserGroup> get allGroups {
    return _groups.values;
  }

  @override
  bool selfInGroupSetting(GroupSettingValue value) {
    return switch (value) {
      GroupSettingValueNamed() =>
        _selfInGroup(value.groupId),
      GroupSettingValueNameless() =>
        value.directMembers.contains(selfUserId)
          || value.directSubgroups.any(_selfInGroup),
    };
  }

  bool _selfInGroup(int groupId) {
    final group = _groups[groupId];
    if (group == null) return false; // TODO(log); should know all groups
    // TODO(perf), TODO(#814): memoize which groups the self-user is in,
    //   to save doing this depth-first search on each permission check
    return group.members.contains(selfUserId)
      || group.directSubgroupIds.any(_selfInGroup);
  }

  final Map<int, UserGroup> _groups;

  final Map<int, Set<int>> _reverseSubgroups;
  final Set<int> _selfUserDirectGroups;

  Set<int> get _selfUserTransitiveGroups =>
    __selfUserTransitiveGroups ??= _computeSelfUserTransitiveGroups();
  Set<int>? __selfUserTransitiveGroups;

  Set<int> _computeSelfUserTransitiveGroups() {
    final result = <int>{};
    final toVisit = List.of(_selfUserDirectGroups);
    while (toVisit.isNotEmpty) {
      final groupId = toVisit.removeLast();
      if (!result.add(groupId)) continue;
      final containing = _reverseSubgroups[groupId];
      if (containing == null) continue; // TODO(log)
      toVisit.addAll(containing);
    }
    return result;
  }

  UserGroup? _expectGroup(int groupId) {
    final group = _groups[groupId];
    // TODO(log) if group not found
    return group;
  }

  void handleUserGroupEvent(UserGroupEvent event) {
    switch (event) {
      case UserGroupAddEvent():
        _groups[event.group.id] = event.group;

        _reverseSubgroups[event.group.id] = {};
        for (final subgroupId in event.group.directSubgroupIds) {
          _reverseSubgroups[subgroupId]?.add(event.group.id);
        }
        if (event.group.members.contains(selfUserId)) {
          _selfUserDirectGroups.add(event.group.id);
        }

        transitive: if (__selfUserTransitiveGroups != null) {
          if (event.group.members.contains(selfUserId)) {
            __selfUserTransitiveGroups!.add(event.group.id);
            break transitive;
          }
          for (final subgroupId in event.group.directSubgroupIds) {
            if (__selfUserTransitiveGroups!.contains(subgroupId)) {
              __selfUserTransitiveGroups!.add(event.group.id);
              break transitive;
            }
          }
        }

      case UserGroupRemoveEvent():
        final group = _groups.remove(event.groupId);
        if (group == null) return; // TODO(log)

        _reverseSubgroups.remove(event.groupId);
        for (final subgroupId in group.directSubgroupIds) {
          _reverseSubgroups[subgroupId]?.remove(event.groupId);
        }
        _selfUserDirectGroups.remove(event.groupId);

        if (__selfUserTransitiveGroups != null
            && __selfUserTransitiveGroups!.contains(event.groupId)) {
          __selfUserTransitiveGroups!.remove(event.groupId);
          final containing = _reverseSubgroups[event.groupId];
          if (containing == null) break; // TODO(log)
          for (final parentId in containing) {
            assert(__selfUserTransitiveGroups!.contains(parentId));
            final parent = _groups[parentId]!;
            if (!parent.members.contains(selfUserId)
                && !parent.directSubgroupIds.any(
                      __selfUserTransitiveGroups!.contains)) {
              __selfUserTransitiveGroups!.remove(parentId); // TODO but transitively
            }
          }
        }

      case UserGroupUpdateEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        final data = event.data;
        if (data.name != null)        group.name        = data.name!;
        if (data.description != null) group.description = data.description!;
        if (data.deactivated != null) group.deactivated = data.deactivated!;

      case UserGroupAddMembersEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.members.addAll(event.userIds);

        if (event.userIds.contains(selfUserId)) {
          _selfUserDirectGroups.add(event.groupId);
        }
        // TODO transitive

      case UserGroupRemoveMembersEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.members.removeAll(event.userIds);

        if (event.userIds.contains(selfUserId)) {
          _selfUserDirectGroups.remove(event.groupId);
        }
        // TODO transitive

      case UserGroupAddSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.directSubgroupIds.addAll(event.directSubgroupIds);

        for (final subgroupId in event.directSubgroupIds) {
          final containing = _reverseSubgroups[subgroupId];
          if (containing == null) continue; // TODO(log)
          containing.add(event.groupId);
        }
        // TODO transitive

      case UserGroupRemoveSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.directSubgroupIds.removeAll(event.directSubgroupIds);

        for (final subgroupId in event.directSubgroupIds) {
          final containing = _reverseSubgroups[subgroupId];
          if (containing == null) continue; // TODO(log)
          containing.remove(event.groupId);
        }
        // TODO transitive
    }
  }

  void handleRealmUserUpdateEvent(RealmUserUpdateEvent event) {
    if (event.isActive == false) {
      for (final group in _groups.values) {
        group.members.remove(event.userId);
      }
    }
  }
}
