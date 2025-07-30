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
    final groupMap = {         for (final group in groups) group.id: group   };
    final reverseSubgroups = { for (final group in groups) group.id: <int>{} };
    for (final group in groups) {
      _pruneSubgroups(group, groupMap);
      for (final subgroupId in group.directSubgroupIds) {
        reverseSubgroups[subgroupId]!.add(group.id);
      }
    }
    return UserGroupStoreImpl._(core: core, groupMap, reverseSubgroups);
  }

  UserGroupStoreImpl._(
    this._groups,
    this._directSupergroups, {
    required super.core,
  }) : _selfUserGroups = {} {
    _recomputeSelfUserGroups();
  }

  static void _pruneSubgroups(UserGroup group, Map<int, UserGroup> groupMap) {
    if (group.directSubgroupIds.any((id) => !groupMap.containsKey(id))) {
      // The group has an unknown subgroup.  TODO(log) that's a server bug.
      // Forget the unknown subgroups so we don't crash in later processing.
      group.directSubgroupIds.removeWhere((id) => !groupMap.containsKey(id));
    }
  }

  static void _pruneSubgroupList(List<int> subgroupIds, Map<int, UserGroup> groupMap) {
    if (subgroupIds.any((id) => !groupMap.containsKey(id))) {
      // The group has an unknown subgroup.  TODO(log) that's a server bug.
      // Forget the unknown subgroups so we don't crash in later processing.
      subgroupIds.removeWhere((id) => !groupMap.containsKey(id));
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
  final Map<int, Set<int>> _directSupergroups;

  /// The groups that the self-user is a member of, transitively.
  final Set<int> _selfUserGroups;

  void _recomputeSelfUserGroups() {
    // TODO(perf): maintain _selfUserGroups more incrementally on events
    _selfUserGroups.clear();
    final toVisit = <int>[
      for (final group in _groups.values)
        if (group.members.contains(selfUserId))
          group.id,
    ];
    while (toVisit.isNotEmpty) {
      final groupId = toVisit.removeLast();
      if (!_selfUserGroups.add(groupId)) continue;
      toVisit.addAll(_directSupergroups[groupId]!);
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
        final group = event.group;
        _pruneSubgroups(group, _groups);
        _groups[group.id] = group;

        _directSupergroups[group.id] = {};
        for (final subgroupId in group.directSubgroupIds) {
          _directSupergroups[subgroupId]!.add(group.id);
        }
        if (group.members.contains(selfUserId)
            || group.directSubgroupIds.any(_selfUserGroups.contains)) {
          _recomputeSelfUserGroups();
        }

      case UserGroupRemoveEvent():
        final group = _groups.remove(event.groupId);
        if (group == null) return; // TODO(log)
        for (final parent in _groups.values) {
          parent.directSubgroupIds.remove(event.groupId);
        }

        for (final subgroupId in group.directSubgroupIds) {
          _directSupergroups[subgroupId]!.remove(event.groupId);
        }
        _directSupergroups.remove(event.groupId);
        if (_selfUserGroups.contains(group.id)) {
          _recomputeSelfUserGroups();
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

        if (!_selfUserGroups.contains(group.id)
            && group.members.contains(selfUserId)) {
          _recomputeSelfUserGroups();
        }

      case UserGroupRemoveMembersEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.members.removeAll(event.userIds);

        if (_selfUserGroups.contains(group.id)
            && !group.members.contains(selfUserId)) {
          _recomputeSelfUserGroups();
        }

      case UserGroupAddSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        final subgroupIds = event.directSubgroupIds;
        _pruneSubgroupList(subgroupIds, _groups);
        group.directSubgroupIds.addAll(subgroupIds);

        for (final subgroupId in subgroupIds) {
          _directSupergroups[subgroupId]!.add(event.groupId);
        }
        if (!_selfUserGroups.contains(group.id)
            && subgroupIds.any(_selfUserGroups.contains)) {
          _recomputeSelfUserGroups();
        }

      case UserGroupRemoveSubgroupsEvent():
        final group = _expectGroup(event.groupId);
        if (group == null) return;
        group.directSubgroupIds.removeAll(event.directSubgroupIds);

        for (final subgroupId in event.directSubgroupIds) {
          _directSupergroups[subgroupId]!.remove(event.groupId);
        }
        if (_selfUserGroups.contains(group.id)
            && event.directSubgroupIds.any(_selfUserGroups.contains)) {
          _recomputeSelfUserGroups();
        }
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
