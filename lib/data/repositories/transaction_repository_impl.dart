import 'dart:async';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._dbHelper, [this._accountRepository]);

  final DatabaseHelper _dbHelper;
  final AccountRepository? _accountRepository;
  final _controller = StreamController<List<Transaction>>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  void _notifyListeners({TransactionFilter? filter}) {
    getTransactions(filter: filter).then((txns) {
      if (!_controller.isClosed) _controller.add(txns);
    });
    _accountRepository?.notifyListeners();
  }

  @override
  Future<List<Transaction>> getTransactions({
    TransactionFilter? filter,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db;

    final conditions = ['t.deletedAt IS NULL'];
    final args = <dynamic>[];

    if (filter != null) {
      if (filter.type != null) {
        conditions.add('t.type = ?');
        args.add(filter.type!.value);
      }
      if (filter.accountId != null) {
        conditions.add('t.accountId = ?');
        args.add(filter.accountId);
      }
      if (filter.categoryId != null) {
        conditions.add('t.categoryId = ?');
        args.add(filter.categoryId);
      }
      if (filter.startDate != null) {
        conditions.add('t.date >= ?');
        args.add(DateFormatter.toIso(filter.startDate!));
      }
      if (filter.endDate != null) {
        conditions.add('t.date <= ?');
        args.add(DateFormatter.toIso(filter.endDate!));
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        conditions.add(
          '(t.description LIKE ? OR t.merchant LIKE ? OR t.note LIKE ?)',
        );
        final q = '%${filter.searchQuery}%';
        args.addAll([q, q, q]);
      }
    }

    final where = conditions.join(' AND ');
    args.addAll([limit, offset]);

    final rows = await db.rawQuery('''
      SELECT
        t.*,
        c.name  AS categoryName,
        c.icon  AS categoryIcon,
        a.name  AS accountName
      FROM ${DatabaseSchema.transactions} t
      LEFT JOIN ${DatabaseSchema.categories} c ON t.categoryId = c.id
      LEFT JOIN ${DatabaseSchema.accounts}   a ON t.accountId  = a.id
      WHERE $where
      ORDER BY t.date DESC, t.createdAt DESC
      LIMIT ? OFFSET ?
    ''', args);

    return rows.map((r) => TransactionModel.fromMap(r).toDomain()).toList();
  }

  @override
  Stream<List<Transaction>> watchTransactions({TransactionFilter? filter}) {
    _notifyListeners(filter: filter);
    return _controller.stream;
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        t.*,
        c.name AS categoryName,
        c.icon AS categoryIcon,
        a.name AS accountName
      FROM ${DatabaseSchema.transactions} t
      LEFT JOIN ${DatabaseSchema.categories} c ON t.categoryId = c.id
      LEFT JOIN ${DatabaseSchema.accounts}   a ON t.accountId  = a.id
      WHERE t.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return TransactionModel.fromMap(rows.first).toDomain();
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 20}) =>
      getTransactions(limit: limit);

  @override
  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    final db = await _db;
    final start = DateFormatter.toIso(DateFormatter.startOfMonth(month));
    final end = DateFormatter.toIso(DateFormatter.endOfMonth(month));

    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income'  THEN amountPaise ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amountPaise ELSE 0 END), 0) AS expense
      FROM ${DatabaseSchema.transactions}
      WHERE deletedAt IS NULL
        AND date >= ?
        AND date <= ?
    ''', [start, end]);

    return MonthlySummary(
      incomePaise: (result.first['income'] as int?) ?? 0,
      expensePaise: (result.first['expense'] as int?) ?? 0,
      month: month,
    );
  }

  /// Creates a transaction and atomically updates the account balance.
  ///
  /// Expense: account.balancePaise -= amountPaise
  /// Income:  account.balancePaise += amountPaise
  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final db = await _db;

    await db.transaction((txn) async {
      // Insert the transaction record
      await txn.insert(
        DatabaseSchema.transactions,
        TransactionModel.fromDomain(transaction).toMap(),
      );

      // Update account balance
      final delta = transaction.type.isExpense
          ? -transaction.amountPaise
          : transaction.amountPaise;

      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise + ?,
            updatedAt = ?
        WHERE id = ?
      ''', [delta, DateFormatter.toIso(DateTime.now()), transaction.accountId]);
    });

    _notifyListeners();
    return transaction;
  }

  /// Updates a transaction and recalculates the account balance delta.
  ///
  /// If account, type, or amount changed — the old effect is reversed
  /// and the new effect is applied atomically.
  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final db = await _db;
    final original = await getTransactionById(transaction.id);
    if (original == null) return;

    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      // Reverse the original balance impact
      final oldDelta = original.type.isExpense
          ? original.amountPaise
          : -original.amountPaise;

      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise + ?,
            updatedAt = ?
        WHERE id = ?
      ''', [oldDelta, now, original.accountId]);

      // Apply the new balance impact
      final newDelta = transaction.type.isExpense
          ? -transaction.amountPaise
          : transaction.amountPaise;

      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise + ?,
            updatedAt = ?
        WHERE id = ?
      ''', [newDelta, now, transaction.accountId]);

      // Update the transaction record
      final map = TransactionModel.fromDomain(transaction).toMap();
      map['updatedAt'] = now;
      await txn.update(
        DatabaseSchema.transactions,
        map,
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });

    _notifyListeners();
  }

  /// Soft-deletes a transaction and reverses its balance impact.
  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _db;
    final original = await getTransactionById(id);
    if (original == null || original.isDeleted) return;

    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      // Reverse balance impact
      final reverseDelta = original.type.isExpense
          ? original.amountPaise
          : -original.amountPaise;

      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise + ?,
            updatedAt = ?
        WHERE id = ?
      ''', [reverseDelta, now, original.accountId]);

      // Soft-delete
      await txn.update(
        DatabaseSchema.transactions,
        {'deletedAt': now, 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    _notifyListeners();
  }

  // ─── Transfers ─────────────────────────────────────────────────────────────

  @override
  Future<Transfer> createTransfer(Transfer transfer) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert(DatabaseSchema.transfers, {
        'id': transfer.id,
        'fromAccountId': transfer.fromAccountId,
        'toAccountId': transfer.toAccountId,
        'amountPaise': transfer.amountPaise,
        'date': DateFormatter.toIso(transfer.date),
        'note': transfer.note,
        'createdAt': now,
        'updatedAt': now,
        'deletedAt': null,
      });

      // Debit source account
      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise - ?,
            updatedAt = ?
        WHERE id = ?
      ''', [transfer.amountPaise, now, transfer.fromAccountId]);

      // Credit destination account
      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise + ?,
            updatedAt = ?
        WHERE id = ?
      ''', [transfer.amountPaise, now, transfer.toAccountId]);
    });

    _notifyListeners();
    return transfer;
  }

  @override
  Future<void> deleteTransfer(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.transfers,
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;

    final row = rows.first;
    final amountPaise = row['amountPaise'] as int;
    final fromAccountId = row['fromAccountId'] as String;
    final toAccountId = row['toAccountId'] as String;
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      // Reverse: credit source, debit destination
      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise + ?, updatedAt = ?
        WHERE id = ?
      ''', [amountPaise, now, fromAccountId]);

      await txn.rawUpdate('''
        UPDATE ${DatabaseSchema.accounts}
        SET balancePaise = balancePaise - ?, updatedAt = ?
        WHERE id = ?
      ''', [amountPaise, now, toAccountId]);

      await txn.update(
        DatabaseSchema.transfers,
        {'deletedAt': now, 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    _notifyListeners();
  }

  @override
  Future<List<Transfer>> getRecentTransfers({int limit = 10}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        t.*,
        fa.name AS fromAccountName,
        ta.name AS toAccountName
      FROM ${DatabaseSchema.transfers} t
      LEFT JOIN ${DatabaseSchema.accounts} fa ON t.fromAccountId = fa.id
      LEFT JOIN ${DatabaseSchema.accounts} ta ON t.toAccountId   = ta.id
      WHERE t.deletedAt IS NULL
      ORDER BY t.date DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((r) => Transfer(
          id: r['id'] as String,
          fromAccountId: r['fromAccountId'] as String,
          toAccountId: r['toAccountId'] as String,
          amountPaise: r['amountPaise'] as int,
          date: DateFormatter.fromIso(r['date'] as String),
          note: r['note'] as String?,
          createdAt: DateFormatter.fromIso(r['createdAt'] as String),
          updatedAt: DateFormatter.fromIso(r['updatedAt'] as String),
          deletedAt: r['deletedAt'] != null
              ? DateFormatter.fromIso(r['deletedAt'] as String)
              : null,
          fromAccountName: r['fromAccountName'] as String?,
          toAccountName: r['toAccountName'] as String?,
        )).toList();
  }
}
