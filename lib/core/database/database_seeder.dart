import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../utils/date_formatter.dart';
import 'schema.dart';

/// Seeds initial data on first install.
///
/// Inserts:
/// - System categories (Food, Transport, Shopping, etc.)
/// - Default Cash account
/// - Default INR currency setting
abstract final class DatabaseSeeder {
  static const _uuid = Uuid();

  static Future<void> seed(Database db) async {
    await _seedCategories(db);
    await _seedDefaultAccount(db);
    await _seedDefaultSettings(db);
  }

  // ─── Categories ───────────────────────────────────────────────────────────
  static const _systemCategories = [
    ('cat_food', 'Food & Dining', '🍽️'),
    ('cat_transport', 'Transport', '🚗'),
    ('cat_shopping', 'Shopping', '🛍️'),
    ('cat_bills', 'Bills & Utilities', '📄'),
    ('cat_travel', 'Travel', '✈️'),
    ('cat_entertainment', 'Entertainment', '🎬'),
    ('cat_health', 'Health', '💊'),
    ('cat_education', 'Education', '📚'),
    ('cat_fuel', 'Fuel', '⛽'),
    ('cat_groceries', 'Groceries', '🛒'),
    ('cat_rent', 'Rent', '🏠'),
    ('cat_salary', 'Salary', '💼'),
    ('cat_freelance', 'Freelance', '💻'),
    ('cat_investment', 'Investment', '📈'),
    ('cat_other', 'Other', '📦'),
  ];

  static Future<void> _seedCategories(Database db) async {
    final now = DateFormatter.toIso(DateTime.now());
    final batch = db.batch();

    for (final (id, name, icon) in _systemCategories) {
      batch.insert(
        DatabaseSchema.categories,
        {
          'id': id,
          'name': name,
          'icon': icon,
          'isSystem': 1,
          'isArchived': 0,
          'createdAt': now,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  // ─── Default Account ──────────────────────────────────────────────────────
  static Future<void> _seedDefaultAccount(Database db) async {
    final existing = await db.query(
      DatabaseSchema.accounts,
      limit: 1,
    );
    if (existing.isNotEmpty) return; // Already seeded

    final now = DateFormatter.toIso(DateTime.now());
    await db.insert(
      DatabaseSchema.accounts,
      {
        'id': _uuid.v4(),
        'name': 'Cash',
        'type': 'cash',
        'balancePaise': 0,
        'currency': 'INR',
        'isArchived': 0,
        'createdAt': now,
        'updatedAt': now,
      },
    );
  }

  // ─── Settings ─────────────────────────────────────────────────────────────
  static Future<void> _seedDefaultSettings(Database db) async {
    final now = DateFormatter.toIso(DateTime.now());
    final defaults = {
      'currency': 'INR',
      'appLockEnabled': 'false',
      'biometricEnabled': 'false',
      'onboardingComplete': 'false',
      'themeMode': 'light',
    };

    final batch = db.batch();
    for (final entry in defaults.entries) {
      batch.insert(
        DatabaseSchema.settings,
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
