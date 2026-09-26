import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;
  final _controller = StreamController<MonthlyBudget?>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  @override
  void notifyListeners() {
    final currentMonth = DateFormatter.formatMonthKey(DateTime.now());
    getMonthlyBudget(currentMonth).then((budget) {
      if (!_controller.isClosed) _controller.add(budget);
    });
  }

  @override
  Future<MonthlyBudget?> getMonthlyBudget(String month) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.budgets,
      where: 'month = ? AND categoryId IS NULL',
      whereArgs: [month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<List<MonthlyBudget>> getCategoryBudgets(String month) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT b.*, c.name AS categoryName
      FROM ${DatabaseSchema.budgets} b
      LEFT JOIN ${DatabaseSchema.categories} c ON b.categoryId = c.id
      WHERE b.month = ? AND b.categoryId IS NOT NULL
      ORDER BY b.amountPaise DESC
    ''', [month]);
    return rows.map(_mapRow).toList();
  }

  @override
  Future<void> setMonthlyBudget(MonthlyBudget budget) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    // Check if budget exists for this month and categoryId
    final where = budget.categoryId == null
        ? 'month = ? AND categoryId IS NULL'
        : 'month = ? AND categoryId = ?';
    final whereArgs = budget.categoryId == null
        ? [budget.month]
        : [budget.month, budget.categoryId];

    final existing = await db.query(
      DatabaseSchema.budgets,
      where: where,
      whereArgs: whereArgs,
    );

    if (existing.isEmpty) {
      await db.insert(
        DatabaseSchema.budgets,
        {
          'id': budget.id,
          'month': budget.month,
          'amountPaise': budget.amountPaise,
          'categoryId': budget.categoryId,
          'createdAt': now,
          'updatedAt': now,
        },
      );
    } else {
      await db.update(
        DatabaseSchema.budgets,
        {
          'amountPaise': budget.amountPaise,
          'updatedAt': now,
        },
        where: where,
        whereArgs: whereArgs,
      );
    }

    notifyListeners();
  }

  @override
  Future<void> deleteBudget(String id) async {
    final db = await _db;
    await db.delete(
      DatabaseSchema.budgets,
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  @override
  Stream<MonthlyBudget?> watchMonthlyBudget(String month) {
    getMonthlyBudget(month).then((b) {
      if (!_controller.isClosed) _controller.add(b);
    });
    return _controller.stream;
  }

  MonthlyBudget _mapRow(Map<String, dynamic> row) {
    return MonthlyBudget(
      id: row['id'] as String,
      month: row['month'] as String,
      amountPaise: row['amountPaise'] as int,
      categoryId: row['categoryId'] as String?,
      categoryName: row['categoryName'] as String?,
      createdAt: DateFormatter.fromIso(row['createdAt'] as String),
      updatedAt: DateFormatter.fromIso(row['updatedAt'] as String),
    );
  }
}
