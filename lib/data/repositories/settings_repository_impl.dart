import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dbHelper, [FlutterSecureStorage? secureStorage])
      : _secureStorage = kIsWeb ? null : (secureStorage ?? const FlutterSecureStorage());

  final DatabaseHelper _dbHelper;
  final FlutterSecureStorage? _secureStorage;
  final _currencyController = StreamController<String>.broadcast();

  static const _pinKey = 'user_pin_hash';

  Future<Database> get _db => _dbHelper.database;


  @override
  Future<String?> getSetting(String key) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.settings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert(
      DatabaseSchema.settings,
      {
        'key': key,
        'value': value,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String> getCurrency() async {
    final val = await getSetting('currency');
    return val ?? 'INR';
  }

  @override
  Future<void> setCurrency(String currency) async {
    await setSetting('currency', currency);
    _currencyController.add(currency);
  }

  @override
  Future<bool> isAppLockEnabled() async {
    final val = await getSetting('appLockEnabled');
    return val == 'true';
  }

  @override
  Future<void> setAppLockEnabled(bool enabled) async {
    await setSetting('appLockEnabled', enabled ? 'true' : 'false');
  }

  @override
  Future<bool> isBiometricEnabled() async {
    final val = await getSetting('biometricEnabled');
    return val == 'true';
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await setSetting('biometricEnabled', enabled ? 'true' : 'false');
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final val = await getSetting('onboardingComplete');
    return val == 'true';
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    await setSetting('onboardingComplete', complete ? 'true' : 'false');
  }

  @override
  Future<String?> getPinHash() async {
    final storage = _secureStorage;
    if (!kIsWeb && storage != null) {
      try {
        final pin = await storage.read(key: _pinKey);
        if (pin != null) return pin;
      } catch (_) {}
    }
    return getSetting(_pinKey);
  }

  @override
  Future<void> setPinHash(String pin) async {
    final hash = _hashPin(pin);
    final storage = _secureStorage;
    if (!kIsWeb && storage != null) {
      try {
        await storage.write(key: _pinKey, value: hash);
      } catch (_) {}
    }
    await setSetting(_pinKey, hash);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final storedHash = await getPinHash();
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  @override
  Future<void> clearPin() async {
    final storage = _secureStorage;
    if (!kIsWeb && storage != null) {
      try {
        await storage.delete(key: _pinKey);
      } catch (_) {}
    }
    final db = await _db;
    await db.delete(
      DatabaseSchema.settings,
      where: 'key = ?',
      whereArgs: [_pinKey],
    );
  }



  @override
  Stream<String> watchCurrency() async* {
    yield await getCurrency();
    yield* _currencyController.stream;
  }


  String _hashPin(String pin) {
    return sha256.convert(utf8.encode('ryve_salt_$pin')).toString();
  }
}
