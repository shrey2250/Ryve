import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'schema.dart';
import 'database_seeder.dart';

/// RYVE Database Helper — Singleton SQLite manager
///
/// Responsible for:
/// - Opening the database on first access
/// - Running DDL migrations
/// - Seeding initial data
/// - Providing the raw [Database] instance to repositories
///
/// Repositories use this class directly — UI code never touches SQL.
class DatabaseHelper {
  static const String _dbName = 'ryve.db';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  /// Returns the open database, initializing if necessary.
  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      return openDatabase(
        inMemoryDatabasePath,
        version: DatabaseSchema.version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    return openDatabase(
      path,
      version: DatabaseSchema.version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign key enforcement (SQLite requires explicit activation).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      for (final sql in DatabaseSchema.allCreateStatements) {
        await txn.execute(sql);
      }
    });

    // Seed initial data
    await DatabaseSeeder.seed(db);
  }

  /// Migrations are handled here as the schema evolves.
  /// V1 → V2 and beyond will add columns / tables safely.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No upgrades yet — V1 is the baseline
    // Future example:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  /// Close the database (call on app dispose / test teardown).
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// Drop and recreate all tables (for testing / restore only).
  Future<void> resetDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      // Disable FK constraints during reset
      await txn.execute('PRAGMA foreign_keys = OFF');

      // Drop all tables
      final tables = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      for (final row in tables) {
        await txn.execute('DROP TABLE IF EXISTS ${row['name']}');
      }

      await txn.execute('PRAGMA foreign_keys = ON');

      // Recreate
      for (final sql in DatabaseSchema.allCreateStatements) {
        await txn.execute(sql);
      }
    });

    await DatabaseSeeder.seed(db);
  }
}
