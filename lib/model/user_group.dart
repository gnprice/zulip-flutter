import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
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
    final groupMap = {         for (final group in groups) group.id: group   };
    final reverseSubgroups = { for (final group in groups) group.id: <int>{} };
    final selfUserDirectGroups = <int>[];
    for (final group in groups) {
      if (group.directSubgroupIds.any((id) => !groupMap.containsKey(id))) {
        // The group has an unknown subgroup.  TODO(log) that's a server bug.
        // Forget the unknown subgroups so we don't crash in later processing.
        group.directSubgroupIds.removeWhere((id) => !groupMap.containsKey(id));
      }
      for (final subgroupId in group.directSubgroupIds) {
        reverseSubgroups[subgroupId]!.add(group.id);
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
    this._reverseSubgroups,
    Iterable<int> selfUserDirectGroups, {
    required super.core,
  }) : _selfUserTransitiveGroups = {} {
    for (final groupId in selfUserDirectGroups) {
      _addTransitively(groupId);
    }
  }

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

  /// All the (named) user groups in the realm.
  ///
  /// This corresponds to [InitialSnapshot.realmUserGroups] in the API.
  /// These are all the groups that exist as groups in the Zulip API,
  /// including system groups.
  ///
  /// These are the "named" groups in contrast with "anonymous" groups.
  /// Those exist in the Zulip server, but appear in the API only in the form
  /// of group-setting values (<https://zulip.com/api/group-setting-values>),
  /// never with a group ID of their own,
  /// and are never members of other groups.
  ///
  /// Every subgroup mentioned in [UserGroup.directSubgroupIds]
  /// of any of these groups is itself present in this map.
  final Map<int, UserGroup> _groups;

  /// The set of groups with each given group as a direct subgroup.
  ///
  /// This has the same set of keys as [_groups].
  ///
  /// For each key `id`, the items in this map's value at `id` are
  /// `for (final g in _groups.values)
  ///    if (g.directSubgroupIds.contains(id))
  ///      g.id`.
  final Map<int, Set<int>> _reverseSubgroups;

  /// The groups that the self-user is transitively a member of.
  final Set<int> _selfUserTransitiveGroups;

  void _addTransitively(int groupId) {
    if (!_selfUserTransitiveGroups.add(groupId)) return;
    final toVisit = List.of(_reverseSubgroups[groupId]!);
    while (toVisit.isNotEmpty) {
      final parentId = toVisit.removeLast();
      if (!_selfUserTransitiveGroups.add(parentId)) continue;
      toVisit.addAll(_reverseSubgroups[parentId]!);
    }
  }

  bool _containsTransitively(UserGroup group) {
    return group.members.contains(selfUserId)
      || group.directSubgroupIds.any(_selfUserTransitiveGroups.contains);
  }

  void _removeTransitively(int groupId) {
    if (!_selfUserTransitiveGroups.remove(groupId)) return;
    final toVisit = List.of(_reverseSubgroups[groupId]!);
    while (toVisit.isNotEmpty) {
      final parentId = toVisit.removeLast();
      if (!_selfUserTransitiveGroups.contains(parentId)) {
        // Already removed; must have been visited previously in this loop.
        continue;
      }
      final parent = _groups[parentId]!;
      if (!_containsTransitively(parent)) {
        _selfUserTransitiveGroups.remove(parentId);
        toVisit.addAll(_reverseSubgroups[parentId]!);
      }
    }
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

        transitive: {
          if (event.group.members.contains(selfUserId)) {
            _selfUserTransitiveGroups.add(event.group.id);
            break transitive;
          }
          for (final subgroupId in event.group.directSubgroupIds) {
            if (_selfUserTransitiveGroups.contains(subgroupId)) {
              _selfUserTransitiveGroups.add(event.group.id);
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

        _removeTransitively(event.groupId);

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
          _addTransitively(event.groupId);
        }

      case UserGroupRemoveMembersEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.members.removeAll(event.userIds);

        if (event.userIds.contains(selfUserId)) {
          if (!_containsTransitively(group)) _removeTransitively(group.id);
        }

      case UserGroupAddSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.directSubgroupIds.addAll(event.directSubgroupIds);

        bool willAdd = _selfUserTransitiveGroups.contains(event.groupId);
        for (final subgroupId in event.directSubgroupIds) {
          final containing = _reverseSubgroups[subgroupId];
          if (containing == null) continue; // TODO(log)
          containing.add(event.groupId);
          if (!willAdd && _selfUserTransitiveGroups.contains(subgroupId)) {
            willAdd = true;
          }
        }
        if (willAdd) _addTransitively(event.groupId);

      case UserGroupRemoveSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.directSubgroupIds.removeAll(event.directSubgroupIds);

        for (final subgroupId in event.directSubgroupIds) {
          final containing = _reverseSubgroups[subgroupId];
          if (containing == null) continue; // TODO(log)
          containing.remove(event.groupId);
        }
        if (!_containsTransitively(group)) _removeTransitively(group.id);
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
