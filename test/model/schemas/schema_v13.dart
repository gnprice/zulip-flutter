// dart format width=80
import 'dart:typed_data' as i2;
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class GlobalSettings extends Table
    with TableInfo<GlobalSettings, GlobalSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GlobalSettings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> themeSetting = GeneratedColumn<String>(
    'theme_setting',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> browserPreference =
      GeneratedColumn<String>(
        'browser_preference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<String> visitFirstUnread = GeneratedColumn<String>(
    'visit_first_unread',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> markReadOnScroll = GeneratedColumn<String>(
    'mark_read_on_scroll',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> legacyUpgradeState =
      GeneratedColumn<String>(
        'legacy_upgrade_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    themeSetting,
    browserPreference,
    visitFirstUnread,
    markReadOnScroll,
    legacyUpgradeState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'global_settings';
  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  GlobalSettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlobalSettingsData(
      themeSetting: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_setting'],
      ),
      browserPreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}browser_preference'],
      ),
      visitFirstUnread: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_first_unread'],
      ),
      markReadOnScroll: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mark_read_on_scroll'],
      ),
      legacyUpgradeState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_upgrade_state'],
      ),
    );
  }

  @override
  GlobalSettings createAlias(String alias) {
    return GlobalSettings(attachedDatabase, alias);
  }
}

class GlobalSettingsData extends DataClass
    implements Insertable<GlobalSettingsData> {
  final String? themeSetting;
  final String? browserPreference;
  final String? visitFirstUnread;
  final String? markReadOnScroll;
  final String? legacyUpgradeState;
  const GlobalSettingsData({
    this.themeSetting,
    this.browserPreference,
    this.visitFirstUnread,
    this.markReadOnScroll,
    this.legacyUpgradeState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || themeSetting != null) {
      map['theme_setting'] = Variable<String>(themeSetting);
    }
    if (!nullToAbsent || browserPreference != null) {
      map['browser_preference'] = Variable<String>(browserPreference);
    }
    if (!nullToAbsent || visitFirstUnread != null) {
      map['visit_first_unread'] = Variable<String>(visitFirstUnread);
    }
    if (!nullToAbsent || markReadOnScroll != null) {
      map['mark_read_on_scroll'] = Variable<String>(markReadOnScroll);
    }
    if (!nullToAbsent || legacyUpgradeState != null) {
      map['legacy_upgrade_state'] = Variable<String>(legacyUpgradeState);
    }
    return map;
  }

  GlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return GlobalSettingsCompanion(
      themeSetting: themeSetting == null && nullToAbsent
          ? const Value.absent()
          : Value(themeSetting),
      browserPreference: browserPreference == null && nullToAbsent
          ? const Value.absent()
          : Value(browserPreference),
      visitFirstUnread: visitFirstUnread == null && nullToAbsent
          ? const Value.absent()
          : Value(visitFirstUnread),
      markReadOnScroll: markReadOnScroll == null && nullToAbsent
          ? const Value.absent()
          : Value(markReadOnScroll),
      legacyUpgradeState: legacyUpgradeState == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyUpgradeState),
    );
  }

  factory GlobalSettingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GlobalSettingsData(
      themeSetting: serializer.fromJson<String?>(json['themeSetting']),
      browserPreference: serializer.fromJson<String?>(
        json['browserPreference'],
      ),
      visitFirstUnread: serializer.fromJson<String?>(json['visitFirstUnread']),
      markReadOnScroll: serializer.fromJson<String?>(json['markReadOnScroll']),
      legacyUpgradeState: serializer.fromJson<String?>(
        json['legacyUpgradeState'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'themeSetting': serializer.toJson<String?>(themeSetting),
      'browserPreference': serializer.toJson<String?>(browserPreference),
      'visitFirstUnread': serializer.toJson<String?>(visitFirstUnread),
      'markReadOnScroll': serializer.toJson<String?>(markReadOnScroll),
      'legacyUpgradeState': serializer.toJson<String?>(legacyUpgradeState),
    };
  }

  GlobalSettingsData copyWith({
    Value<String?> themeSetting = const Value.absent(),
    Value<String?> browserPreference = const Value.absent(),
    Value<String?> visitFirstUnread = const Value.absent(),
    Value<String?> markReadOnScroll = const Value.absent(),
    Value<String?> legacyUpgradeState = const Value.absent(),
  }) => GlobalSettingsData(
    themeSetting: themeSetting.present ? themeSetting.value : this.themeSetting,
    browserPreference: browserPreference.present
        ? browserPreference.value
        : this.browserPreference,
    visitFirstUnread: visitFirstUnread.present
        ? visitFirstUnread.value
        : this.visitFirstUnread,
    markReadOnScroll: markReadOnScroll.present
        ? markReadOnScroll.value
        : this.markReadOnScroll,
    legacyUpgradeState: legacyUpgradeState.present
        ? legacyUpgradeState.value
        : this.legacyUpgradeState,
  );
  GlobalSettingsData copyWithCompanion(GlobalSettingsCompanion data) {
    return GlobalSettingsData(
      themeSetting: data.themeSetting.present
          ? data.themeSetting.value
          : this.themeSetting,
      browserPreference: data.browserPreference.present
          ? data.browserPreference.value
          : this.browserPreference,
      visitFirstUnread: data.visitFirstUnread.present
          ? data.visitFirstUnread.value
          : this.visitFirstUnread,
      markReadOnScroll: data.markReadOnScroll.present
          ? data.markReadOnScroll.value
          : this.markReadOnScroll,
      legacyUpgradeState: data.legacyUpgradeState.present
          ? data.legacyUpgradeState.value
          : this.legacyUpgradeState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlobalSettingsData(')
          ..write('themeSetting: $themeSetting, ')
          ..write('browserPreference: $browserPreference, ')
          ..write('visitFirstUnread: $visitFirstUnread, ')
          ..write('markReadOnScroll: $markReadOnScroll, ')
          ..write('legacyUpgradeState: $legacyUpgradeState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    themeSetting,
    browserPreference,
    visitFirstUnread,
    markReadOnScroll,
    legacyUpgradeState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlobalSettingsData &&
          other.themeSetting == this.themeSetting &&
          other.browserPreference == this.browserPreference &&
          other.visitFirstUnread == this.visitFirstUnread &&
          other.markReadOnScroll == this.markReadOnScroll &&
          other.legacyUpgradeState == this.legacyUpgradeState);
}

class GlobalSettingsCompanion extends UpdateCompanion<GlobalSettingsData> {
  final Value<String?> themeSetting;
  final Value<String?> browserPreference;
  final Value<String?> visitFirstUnread;
  final Value<String?> markReadOnScroll;
  final Value<String?> legacyUpgradeState;
  final Value<int> rowid;
  const GlobalSettingsCompanion({
    this.themeSetting = const Value.absent(),
    this.browserPreference = const Value.absent(),
    this.visitFirstUnread = const Value.absent(),
    this.markReadOnScroll = const Value.absent(),
    this.legacyUpgradeState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GlobalSettingsCompanion.insert({
    this.themeSetting = const Value.absent(),
    this.browserPreference = const Value.absent(),
    this.visitFirstUnread = const Value.absent(),
    this.markReadOnScroll = const Value.absent(),
    this.legacyUpgradeState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<GlobalSettingsData> custom({
    Expression<String>? themeSetting,
    Expression<String>? browserPreference,
    Expression<String>? visitFirstUnread,
    Expression<String>? markReadOnScroll,
    Expression<String>? legacyUpgradeState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (themeSetting != null) 'theme_setting': themeSetting,
      if (browserPreference != null) 'browser_preference': browserPreference,
      if (visitFirstUnread != null) 'visit_first_unread': visitFirstUnread,
      if (markReadOnScroll != null) 'mark_read_on_scroll': markReadOnScroll,
      if (legacyUpgradeState != null)
        'legacy_upgrade_state': legacyUpgradeState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GlobalSettingsCompanion copyWith({
    Value<String?>? themeSetting,
    Value<String?>? browserPreference,
    Value<String?>? visitFirstUnread,
    Value<String?>? markReadOnScroll,
    Value<String?>? legacyUpgradeState,
    Value<int>? rowid,
  }) {
    return GlobalSettingsCompanion(
      themeSetting: themeSetting ?? this.themeSetting,
      browserPreference: browserPreference ?? this.browserPreference,
      visitFirstUnread: visitFirstUnread ?? this.visitFirstUnread,
      markReadOnScroll: markReadOnScroll ?? this.markReadOnScroll,
      legacyUpgradeState: legacyUpgradeState ?? this.legacyUpgradeState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (themeSetting.present) {
      map['theme_setting'] = Variable<String>(themeSetting.value);
    }
    if (browserPreference.present) {
      map['browser_preference'] = Variable<String>(browserPreference.value);
    }
    if (visitFirstUnread.present) {
      map['visit_first_unread'] = Variable<String>(visitFirstUnread.value);
    }
    if (markReadOnScroll.present) {
      map['mark_read_on_scroll'] = Variable<String>(markReadOnScroll.value);
    }
    if (legacyUpgradeState.present) {
      map['legacy_upgrade_state'] = Variable<String>(legacyUpgradeState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GlobalSettingsCompanion(')
          ..write('themeSetting: $themeSetting, ')
          ..write('browserPreference: $browserPreference, ')
          ..write('visitFirstUnread: $visitFirstUnread, ')
          ..write('markReadOnScroll: $markReadOnScroll, ')
          ..write('legacyUpgradeState: $legacyUpgradeState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class BoolGlobalSettings extends Table
    with TableInfo<BoolGlobalSettings, BoolGlobalSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BoolGlobalSettings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> value = GeneratedColumn<bool>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("value" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bool_global_settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  BoolGlobalSettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoolGlobalSettingsData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  BoolGlobalSettings createAlias(String alias) {
    return BoolGlobalSettings(attachedDatabase, alias);
  }
}

class BoolGlobalSettingsData extends DataClass
    implements Insertable<BoolGlobalSettingsData> {
  final String name;
  final bool value;
  const BoolGlobalSettingsData({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<bool>(value);
    return map;
  }

  BoolGlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return BoolGlobalSettingsCompanion(name: Value(name), value: Value(value));
  }

  factory BoolGlobalSettingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoolGlobalSettingsData(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<bool>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<bool>(value),
    };
  }

  BoolGlobalSettingsData copyWith({String? name, bool? value}) =>
      BoolGlobalSettingsData(
        name: name ?? this.name,
        value: value ?? this.value,
      );
  BoolGlobalSettingsData copyWithCompanion(BoolGlobalSettingsCompanion data) {
    return BoolGlobalSettingsData(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoolGlobalSettingsData(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoolGlobalSettingsData &&
          other.name == this.name &&
          other.value == this.value);
}

class BoolGlobalSettingsCompanion
    extends UpdateCompanion<BoolGlobalSettingsData> {
  final Value<String> name;
  final Value<bool> value;
  final Value<int> rowid;
  const BoolGlobalSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoolGlobalSettingsCompanion.insert({
    required String name,
    required bool value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<BoolGlobalSettingsData> custom({
    Expression<String>? name,
    Expression<bool>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoolGlobalSettingsCompanion copyWith({
    Value<String>? name,
    Value<bool>? value,
    Value<int>? rowid,
  }) {
    return BoolGlobalSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<bool>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoolGlobalSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class IntGlobalSettings extends Table
    with TableInfo<IntGlobalSettings, IntGlobalSettingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  IntGlobalSettings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'int_global_settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  IntGlobalSettingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntGlobalSettingsData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  IntGlobalSettings createAlias(String alias) {
    return IntGlobalSettings(attachedDatabase, alias);
  }
}

class IntGlobalSettingsData extends DataClass
    implements Insertable<IntGlobalSettingsData> {
  final String name;
  final int value;
  const IntGlobalSettingsData({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<int>(value);
    return map;
  }

  IntGlobalSettingsCompanion toCompanion(bool nullToAbsent) {
    return IntGlobalSettingsCompanion(name: Value(name), value: Value(value));
  }

  factory IntGlobalSettingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntGlobalSettingsData(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<int>(value),
    };
  }

  IntGlobalSettingsData copyWith({String? name, int? value}) =>
      IntGlobalSettingsData(
        name: name ?? this.name,
        value: value ?? this.value,
      );
  IntGlobalSettingsData copyWithCompanion(IntGlobalSettingsCompanion data) {
    return IntGlobalSettingsData(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntGlobalSettingsData(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntGlobalSettingsData &&
          other.name == this.name &&
          other.value == this.value);
}

class IntGlobalSettingsCompanion
    extends UpdateCompanion<IntGlobalSettingsData> {
  final Value<String> name;
  final Value<int> value;
  final Value<int> rowid;
  const IntGlobalSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntGlobalSettingsCompanion.insert({
    required String name,
    required int value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<IntGlobalSettingsData> custom({
    Expression<String>? name,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntGlobalSettingsCompanion copyWith({
    Value<String>? name,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return IntGlobalSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntGlobalSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Accounts extends Table with TableInfo<Accounts, AccountsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Accounts(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> realmUrl = GeneratedColumn<String>(
    'realm_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> realmName = GeneratedColumn<String>(
    'realm_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> realmIcon = GeneratedColumn<String>(
    'realm_icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> zulipVersion = GeneratedColumn<String>(
    'zulip_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> zulipMergeBase = GeneratedColumn<String>(
    'zulip_merge_base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> zulipFeatureLevel = GeneratedColumn<int>(
    'zulip_feature_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> pushAccountId = GeneratedColumn<int>(
    'push_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<i2.Uint8List> pushKey =
      GeneratedColumn<i2.Uint8List>(
        'push_key',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<String> pushToken = GeneratedColumn<String>(
    'push_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> pushRegistrationTimestamp =
      GeneratedColumn<int>(
        'push_registration_timestamp',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  late final GeneratedColumn<String> pushRegistrationResult =
      GeneratedColumn<String>(
        'push_registration_result',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    realmUrl,
    realmName,
    realmIcon,
    userId,
    email,
    apiKey,
    zulipVersion,
    zulipMergeBase,
    zulipFeatureLevel,
    pushAccountId,
    pushKey,
    pushToken,
    pushRegistrationTimestamp,
    pushRegistrationResult,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {realmUrl, userId},
    {realmUrl, email},
    {pushAccountId},
  ];
  @override
  AccountsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      realmUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}realm_url'],
      )!,
      realmName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}realm_name'],
      ),
      realmIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}realm_icon'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      )!,
      zulipVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zulip_version'],
      )!,
      zulipMergeBase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zulip_merge_base'],
      ),
      zulipFeatureLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zulip_feature_level'],
      )!,
      pushAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}push_account_id'],
      ),
      pushKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}push_key'],
      ),
      pushToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}push_token'],
      ),
      pushRegistrationTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}push_registration_timestamp'],
      ),
      pushRegistrationResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}push_registration_result'],
      ),
    );
  }

  @override
  Accounts createAlias(String alias) {
    return Accounts(attachedDatabase, alias);
  }
}

class AccountsData extends DataClass implements Insertable<AccountsData> {
  final int id;
  final String realmUrl;
  final String? realmName;
  final String? realmIcon;
  final int userId;
  final String email;
  final String apiKey;
  final String zulipVersion;
  final String? zulipMergeBase;
  final int zulipFeatureLevel;
  final int? pushAccountId;
  final i2.Uint8List? pushKey;
  final String? pushToken;
  final int? pushRegistrationTimestamp;
  final String? pushRegistrationResult;
  const AccountsData({
    required this.id,
    required this.realmUrl,
    this.realmName,
    this.realmIcon,
    required this.userId,
    required this.email,
    required this.apiKey,
    required this.zulipVersion,
    this.zulipMergeBase,
    required this.zulipFeatureLevel,
    this.pushAccountId,
    this.pushKey,
    this.pushToken,
    this.pushRegistrationTimestamp,
    this.pushRegistrationResult,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['realm_url'] = Variable<String>(realmUrl);
    if (!nullToAbsent || realmName != null) {
      map['realm_name'] = Variable<String>(realmName);
    }
    if (!nullToAbsent || realmIcon != null) {
      map['realm_icon'] = Variable<String>(realmIcon);
    }
    map['user_id'] = Variable<int>(userId);
    map['email'] = Variable<String>(email);
    map['api_key'] = Variable<String>(apiKey);
    map['zulip_version'] = Variable<String>(zulipVersion);
    if (!nullToAbsent || zulipMergeBase != null) {
      map['zulip_merge_base'] = Variable<String>(zulipMergeBase);
    }
    map['zulip_feature_level'] = Variable<int>(zulipFeatureLevel);
    if (!nullToAbsent || pushAccountId != null) {
      map['push_account_id'] = Variable<int>(pushAccountId);
    }
    if (!nullToAbsent || pushKey != null) {
      map['push_key'] = Variable<i2.Uint8List>(pushKey);
    }
    if (!nullToAbsent || pushToken != null) {
      map['push_token'] = Variable<String>(pushToken);
    }
    if (!nullToAbsent || pushRegistrationTimestamp != null) {
      map['push_registration_timestamp'] = Variable<int>(
        pushRegistrationTimestamp,
      );
    }
    if (!nullToAbsent || pushRegistrationResult != null) {
      map['push_registration_result'] = Variable<String>(
        pushRegistrationResult,
      );
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      realmUrl: Value(realmUrl),
      realmName: realmName == null && nullToAbsent
          ? const Value.absent()
          : Value(realmName),
      realmIcon: realmIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(realmIcon),
      userId: Value(userId),
      email: Value(email),
      apiKey: Value(apiKey),
      zulipVersion: Value(zulipVersion),
      zulipMergeBase: zulipMergeBase == null && nullToAbsent
          ? const Value.absent()
          : Value(zulipMergeBase),
      zulipFeatureLevel: Value(zulipFeatureLevel),
      pushAccountId: pushAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(pushAccountId),
      pushKey: pushKey == null && nullToAbsent
          ? const Value.absent()
          : Value(pushKey),
      pushToken: pushToken == null && nullToAbsent
          ? const Value.absent()
          : Value(pushToken),
      pushRegistrationTimestamp:
          pushRegistrationTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(pushRegistrationTimestamp),
      pushRegistrationResult: pushRegistrationResult == null && nullToAbsent
          ? const Value.absent()
          : Value(pushRegistrationResult),
    );
  }

  factory AccountsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsData(
      id: serializer.fromJson<int>(json['id']),
      realmUrl: serializer.fromJson<String>(json['realmUrl']),
      realmName: serializer.fromJson<String?>(json['realmName']),
      realmIcon: serializer.fromJson<String?>(json['realmIcon']),
      userId: serializer.fromJson<int>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      zulipVersion: serializer.fromJson<String>(json['zulipVersion']),
      zulipMergeBase: serializer.fromJson<String?>(json['zulipMergeBase']),
      zulipFeatureLevel: serializer.fromJson<int>(json['zulipFeatureLevel']),
      pushAccountId: serializer.fromJson<int?>(json['pushAccountId']),
      pushKey: serializer.fromJson<i2.Uint8List?>(json['pushKey']),
      pushToken: serializer.fromJson<String?>(json['pushToken']),
      pushRegistrationTimestamp: serializer.fromJson<int?>(
        json['pushRegistrationTimestamp'],
      ),
      pushRegistrationResult: serializer.fromJson<String?>(
        json['pushRegistrationResult'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'realmUrl': serializer.toJson<String>(realmUrl),
      'realmName': serializer.toJson<String?>(realmName),
      'realmIcon': serializer.toJson<String?>(realmIcon),
      'userId': serializer.toJson<int>(userId),
      'email': serializer.toJson<String>(email),
      'apiKey': serializer.toJson<String>(apiKey),
      'zulipVersion': serializer.toJson<String>(zulipVersion),
      'zulipMergeBase': serializer.toJson<String?>(zulipMergeBase),
      'zulipFeatureLevel': serializer.toJson<int>(zulipFeatureLevel),
      'pushAccountId': serializer.toJson<int?>(pushAccountId),
      'pushKey': serializer.toJson<i2.Uint8List?>(pushKey),
      'pushToken': serializer.toJson<String?>(pushToken),
      'pushRegistrationTimestamp': serializer.toJson<int?>(
        pushRegistrationTimestamp,
      ),
      'pushRegistrationResult': serializer.toJson<String?>(
        pushRegistrationResult,
      ),
    };
  }

  AccountsData copyWith({
    int? id,
    String? realmUrl,
    Value<String?> realmName = const Value.absent(),
    Value<String?> realmIcon = const Value.absent(),
    int? userId,
    String? email,
    String? apiKey,
    String? zulipVersion,
    Value<String?> zulipMergeBase = const Value.absent(),
    int? zulipFeatureLevel,
    Value<int?> pushAccountId = const Value.absent(),
    Value<i2.Uint8List?> pushKey = const Value.absent(),
    Value<String?> pushToken = const Value.absent(),
    Value<int?> pushRegistrationTimestamp = const Value.absent(),
    Value<String?> pushRegistrationResult = const Value.absent(),
  }) => AccountsData(
    id: id ?? this.id,
    realmUrl: realmUrl ?? this.realmUrl,
    realmName: realmName.present ? realmName.value : this.realmName,
    realmIcon: realmIcon.present ? realmIcon.value : this.realmIcon,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    apiKey: apiKey ?? this.apiKey,
    zulipVersion: zulipVersion ?? this.zulipVersion,
    zulipMergeBase: zulipMergeBase.present
        ? zulipMergeBase.value
        : this.zulipMergeBase,
    zulipFeatureLevel: zulipFeatureLevel ?? this.zulipFeatureLevel,
    pushAccountId: pushAccountId.present
        ? pushAccountId.value
        : this.pushAccountId,
    pushKey: pushKey.present ? pushKey.value : this.pushKey,
    pushToken: pushToken.present ? pushToken.value : this.pushToken,
    pushRegistrationTimestamp: pushRegistrationTimestamp.present
        ? pushRegistrationTimestamp.value
        : this.pushRegistrationTimestamp,
    pushRegistrationResult: pushRegistrationResult.present
        ? pushRegistrationResult.value
        : this.pushRegistrationResult,
  );
  AccountsData copyWithCompanion(AccountsCompanion data) {
    return AccountsData(
      id: data.id.present ? data.id.value : this.id,
      realmUrl: data.realmUrl.present ? data.realmUrl.value : this.realmUrl,
      realmName: data.realmName.present ? data.realmName.value : this.realmName,
      realmIcon: data.realmIcon.present ? data.realmIcon.value : this.realmIcon,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      zulipVersion: data.zulipVersion.present
          ? data.zulipVersion.value
          : this.zulipVersion,
      zulipMergeBase: data.zulipMergeBase.present
          ? data.zulipMergeBase.value
          : this.zulipMergeBase,
      zulipFeatureLevel: data.zulipFeatureLevel.present
          ? data.zulipFeatureLevel.value
          : this.zulipFeatureLevel,
      pushAccountId: data.pushAccountId.present
          ? data.pushAccountId.value
          : this.pushAccountId,
      pushKey: data.pushKey.present ? data.pushKey.value : this.pushKey,
      pushToken: data.pushToken.present ? data.pushToken.value : this.pushToken,
      pushRegistrationTimestamp: data.pushRegistrationTimestamp.present
          ? data.pushRegistrationTimestamp.value
          : this.pushRegistrationTimestamp,
      pushRegistrationResult: data.pushRegistrationResult.present
          ? data.pushRegistrationResult.value
          : this.pushRegistrationResult,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsData(')
          ..write('id: $id, ')
          ..write('realmUrl: $realmUrl, ')
          ..write('realmName: $realmName, ')
          ..write('realmIcon: $realmIcon, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('apiKey: $apiKey, ')
          ..write('zulipVersion: $zulipVersion, ')
          ..write('zulipMergeBase: $zulipMergeBase, ')
          ..write('zulipFeatureLevel: $zulipFeatureLevel, ')
          ..write('pushAccountId: $pushAccountId, ')
          ..write('pushKey: $pushKey, ')
          ..write('pushToken: $pushToken, ')
          ..write('pushRegistrationTimestamp: $pushRegistrationTimestamp, ')
          ..write('pushRegistrationResult: $pushRegistrationResult')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    realmUrl,
    realmName,
    realmIcon,
    userId,
    email,
    apiKey,
    zulipVersion,
    zulipMergeBase,
    zulipFeatureLevel,
    pushAccountId,
    $driftBlobEquality.hash(pushKey),
    pushToken,
    pushRegistrationTimestamp,
    pushRegistrationResult,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsData &&
          other.id == this.id &&
          other.realmUrl == this.realmUrl &&
          other.realmName == this.realmName &&
          other.realmIcon == this.realmIcon &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.apiKey == this.apiKey &&
          other.zulipVersion == this.zulipVersion &&
          other.zulipMergeBase == this.zulipMergeBase &&
          other.zulipFeatureLevel == this.zulipFeatureLevel &&
          other.pushAccountId == this.pushAccountId &&
          $driftBlobEquality.equals(other.pushKey, this.pushKey) &&
          other.pushToken == this.pushToken &&
          other.pushRegistrationTimestamp == this.pushRegistrationTimestamp &&
          other.pushRegistrationResult == this.pushRegistrationResult);
}

class AccountsCompanion extends UpdateCompanion<AccountsData> {
  final Value<int> id;
  final Value<String> realmUrl;
  final Value<String?> realmName;
  final Value<String?> realmIcon;
  final Value<int> userId;
  final Value<String> email;
  final Value<String> apiKey;
  final Value<String> zulipVersion;
  final Value<String?> zulipMergeBase;
  final Value<int> zulipFeatureLevel;
  final Value<int?> pushAccountId;
  final Value<i2.Uint8List?> pushKey;
  final Value<String?> pushToken;
  final Value<int?> pushRegistrationTimestamp;
  final Value<String?> pushRegistrationResult;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.realmUrl = const Value.absent(),
    this.realmName = const Value.absent(),
    this.realmIcon = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.zulipVersion = const Value.absent(),
    this.zulipMergeBase = const Value.absent(),
    this.zulipFeatureLevel = const Value.absent(),
    this.pushAccountId = const Value.absent(),
    this.pushKey = const Value.absent(),
    this.pushToken = const Value.absent(),
    this.pushRegistrationTimestamp = const Value.absent(),
    this.pushRegistrationResult = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String realmUrl,
    this.realmName = const Value.absent(),
    this.realmIcon = const Value.absent(),
    required int userId,
    required String email,
    required String apiKey,
    required String zulipVersion,
    this.zulipMergeBase = const Value.absent(),
    required int zulipFeatureLevel,
    this.pushAccountId = const Value.absent(),
    this.pushKey = const Value.absent(),
    this.pushToken = const Value.absent(),
    this.pushRegistrationTimestamp = const Value.absent(),
    this.pushRegistrationResult = const Value.absent(),
  }) : realmUrl = Value(realmUrl),
       userId = Value(userId),
       email = Value(email),
       apiKey = Value(apiKey),
       zulipVersion = Value(zulipVersion),
       zulipFeatureLevel = Value(zulipFeatureLevel);
  static Insertable<AccountsData> custom({
    Expression<int>? id,
    Expression<String>? realmUrl,
    Expression<String>? realmName,
    Expression<String>? realmIcon,
    Expression<int>? userId,
    Expression<String>? email,
    Expression<String>? apiKey,
    Expression<String>? zulipVersion,
    Expression<String>? zulipMergeBase,
    Expression<int>? zulipFeatureLevel,
    Expression<int>? pushAccountId,
    Expression<i2.Uint8List>? pushKey,
    Expression<String>? pushToken,
    Expression<int>? pushRegistrationTimestamp,
    Expression<String>? pushRegistrationResult,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (realmUrl != null) 'realm_url': realmUrl,
      if (realmName != null) 'realm_name': realmName,
      if (realmIcon != null) 'realm_icon': realmIcon,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (apiKey != null) 'api_key': apiKey,
      if (zulipVersion != null) 'zulip_version': zulipVersion,
      if (zulipMergeBase != null) 'zulip_merge_base': zulipMergeBase,
      if (zulipFeatureLevel != null) 'zulip_feature_level': zulipFeatureLevel,
      if (pushAccountId != null) 'push_account_id': pushAccountId,
      if (pushKey != null) 'push_key': pushKey,
      if (pushToken != null) 'push_token': pushToken,
      if (pushRegistrationTimestamp != null)
        'push_registration_timestamp': pushRegistrationTimestamp,
      if (pushRegistrationResult != null)
        'push_registration_result': pushRegistrationResult,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? realmUrl,
    Value<String?>? realmName,
    Value<String?>? realmIcon,
    Value<int>? userId,
    Value<String>? email,
    Value<String>? apiKey,
    Value<String>? zulipVersion,
    Value<String?>? zulipMergeBase,
    Value<int>? zulipFeatureLevel,
    Value<int?>? pushAccountId,
    Value<i2.Uint8List?>? pushKey,
    Value<String?>? pushToken,
    Value<int?>? pushRegistrationTimestamp,
    Value<String?>? pushRegistrationResult,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      realmUrl: realmUrl ?? this.realmUrl,
      realmName: realmName ?? this.realmName,
      realmIcon: realmIcon ?? this.realmIcon,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      apiKey: apiKey ?? this.apiKey,
      zulipVersion: zulipVersion ?? this.zulipVersion,
      zulipMergeBase: zulipMergeBase ?? this.zulipMergeBase,
      zulipFeatureLevel: zulipFeatureLevel ?? this.zulipFeatureLevel,
      pushAccountId: pushAccountId ?? this.pushAccountId,
      pushKey: pushKey ?? this.pushKey,
      pushToken: pushToken ?? this.pushToken,
      pushRegistrationTimestamp:
          pushRegistrationTimestamp ?? this.pushRegistrationTimestamp,
      pushRegistrationResult:
          pushRegistrationResult ?? this.pushRegistrationResult,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (realmUrl.present) {
      map['realm_url'] = Variable<String>(realmUrl.value);
    }
    if (realmName.present) {
      map['realm_name'] = Variable<String>(realmName.value);
    }
    if (realmIcon.present) {
      map['realm_icon'] = Variable<String>(realmIcon.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (zulipVersion.present) {
      map['zulip_version'] = Variable<String>(zulipVersion.value);
    }
    if (zulipMergeBase.present) {
      map['zulip_merge_base'] = Variable<String>(zulipMergeBase.value);
    }
    if (zulipFeatureLevel.present) {
      map['zulip_feature_level'] = Variable<int>(zulipFeatureLevel.value);
    }
    if (pushAccountId.present) {
      map['push_account_id'] = Variable<int>(pushAccountId.value);
    }
    if (pushKey.present) {
      map['push_key'] = Variable<i2.Uint8List>(pushKey.value);
    }
    if (pushToken.present) {
      map['push_token'] = Variable<String>(pushToken.value);
    }
    if (pushRegistrationTimestamp.present) {
      map['push_registration_timestamp'] = Variable<int>(
        pushRegistrationTimestamp.value,
      );
    }
    if (pushRegistrationResult.present) {
      map['push_registration_result'] = Variable<String>(
        pushRegistrationResult.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('realmUrl: $realmUrl, ')
          ..write('realmName: $realmName, ')
          ..write('realmIcon: $realmIcon, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('apiKey: $apiKey, ')
          ..write('zulipVersion: $zulipVersion, ')
          ..write('zulipMergeBase: $zulipMergeBase, ')
          ..write('zulipFeatureLevel: $zulipFeatureLevel, ')
          ..write('pushAccountId: $pushAccountId, ')
          ..write('pushKey: $pushKey, ')
          ..write('pushToken: $pushToken, ')
          ..write('pushRegistrationTimestamp: $pushRegistrationTimestamp, ')
          ..write('pushRegistrationResult: $pushRegistrationResult')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV13 extends GeneratedDatabase {
  DatabaseAtV13(QueryExecutor e) : super(e);
  late final GlobalSettings globalSettings = GlobalSettings(this);
  late final BoolGlobalSettings boolGlobalSettings = BoolGlobalSettings(this);
  late final IntGlobalSettings intGlobalSettings = IntGlobalSettings(this);
  late final Accounts accounts = Accounts(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    globalSettings,
    boolGlobalSettings,
    intGlobalSettings,
    accounts,
  ];
  @override
  int get schemaVersion => 13;
}
