import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

  // Stream controller for reactive updates
  final _controller = StreamController<List<Account>>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  @override
  void notifyListeners() {
    getAccounts().then((accounts) {
      if (!_controller.isClosed) _controller.add(accounts);
    });
  }

  @override
  Future<List<Account>> getAccounts() async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.accounts,
      where: 'isArchived = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return rows.map((r) => AccountModel.fromMap(r).toDomain()).toList();
  }

  @override
  Stream<List<Account>> watchAccounts() {
    // Emit current data immediately
    getAccounts().then((accounts) {
      if (!_controller.isClosed) _controller.add(accounts);
    });
    return _controller.stream;
  }

  @override
  Future<Account?> getAccountById(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.accounts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AccountModel.fromMap(rows.first).toDomain();
  }

  @override
  Future<Account> createAccount(Account account) async {
    final db = await _db;
    final model = AccountModel.fromDomain(account);
    await db.insert(
      DatabaseSchema.accounts,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
    return account;
  }

  @override
  Future<void> updateAccount(Account account) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());
    final map = AccountModel.fromDomain(account).toMap();
    map['updatedAt'] = now;

    await db.update(
      DatabaseSchema.accounts,
      map,
      where: 'id = ?',
      whereArgs: [account.id],
    );
    notifyListeners();
  }

  @override
  Future<void> archiveAccount(String id) async {
    final db = await _db;
    await db.update(
      DatabaseSchema.accounts,
      {
        'isArchived': 1,
        'updatedAt': DateFormatter.toIso(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  @override
  Future<int> recalculateBalance(String accountId) async {
    final db = await _db;

    // Sum all non-deleted income transactions
    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amountPaise), 0) AS total
      FROM ${DatabaseSchema.transactions}
      WHERE accountId = ? AND type = 'income' AND deletedAt IS NULL
    ''', [accountId]);
    final income = (incomeResult.first['total'] as int?) ?? 0;

    // Sum all non-deleted expense transactions
    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amountPaise), 0) AS total
      FROM ${DatabaseSchema.transactions}
      WHERE accountId = ? AND type = 'expense' AND deletedAt IS NULL
    ''', [accountId]);
    final expense = (expenseResult.first['total'] as int?) ?? 0;

    // Sum incoming transfers
    final transferInResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amountPaise), 0) AS total
      FROM ${DatabaseSchema.transfers}
      WHERE toAccountId = ? AND deletedAt IS NULL
    ''', [accountId]);
    final transferIn = (transferInResult.first['total'] as int?) ?? 0;

    // Sum outgoing transfers
    final transferOutResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amountPaise), 0) AS total
      FROM ${DatabaseSchema.transfers}
      WHERE fromAccountId = ? AND deletedAt IS NULL
    ''', [accountId]);
    final transferOut = (transferOutResult.first['total'] as int?) ?? 0;

    final balance = income - expense + transferIn - transferOut;

    await db.update(
      DatabaseSchema.accounts,
      {
        'balancePaise': balance,
        'updatedAt': DateFormatter.toIso(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );

    notifyListeners();
    return balance;
  }

  @override
  Future<int> getTotalBalancePaise() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balancePaise), 0) AS total
      FROM ${DatabaseSchema.accounts}
      WHERE isArchived = 0
    ''');
    return (result.first['total'] as int?) ?? 0;
  }
}
