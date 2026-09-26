import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;
  final _controller = StreamController<List<SavingsGoal>>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  @override
  void notifyListeners() {
    getGoals().then((goals) {
      if (!_controller.isClosed) _controller.add(goals);
    });
  }

  @override
  Future<List<SavingsGoal>> getGoals() async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.goals,
      where: 'deletedAt IS NULL',
      orderBy: 'createdAt DESC',
    );
    return rows.map(_mapRow).toList();
  }

  @override
  Future<SavingsGoal?> getGoalById(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.goals,
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  @override
  Future<SavingsGoal> createGoal(SavingsGoal goal) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert(
      DatabaseSchema.goals,
      {
        'id': goal.id,
        'name': goal.name,
        'targetAmountPaise': goal.targetAmountPaise,
        'savedAmountPaise': goal.savedAmountPaise,
        'monthlyContributionPaise': goal.monthlyContributionPaise,
        'targetDate': goal.targetDate != null ? DateFormatter.toIso(goal.targetDate!) : null,
        'icon': goal.icon,
        'createdAt': now,
        'updatedAt': now,
        'deletedAt': null,
      },
    );

    notifyListeners();
    return goal;
  }

  @override
  Future<void> updateGoal(SavingsGoal goal) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.update(
      DatabaseSchema.goals,
      {
        'name': goal.name,
        'targetAmountPaise': goal.targetAmountPaise,
        'savedAmountPaise': goal.savedAmountPaise,
        'monthlyContributionPaise': goal.monthlyContributionPaise,
        'targetDate': goal.targetDate != null ? DateFormatter.toIso(goal.targetDate!) : null,
        'icon': goal.icon,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [goal.id],
    );

    notifyListeners();
  }

  @override
  Future<void> deleteGoal(String id) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.update(
      DatabaseSchema.goals,
      {
        'deletedAt': now,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    notifyListeners();
  }

  @override
  Future<void> addContribution(String goalId, int amountPaise) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.rawUpdate('''
      UPDATE ${DatabaseSchema.goals}
      SET savedAmountPaise = savedAmountPaise + ?,
          updatedAt = ?
      WHERE id = ?
    ''', [amountPaise, now, goalId]);

    notifyListeners();
  }

  @override
  Stream<List<SavingsGoal>> watchGoals() {
    getGoals().then((goals) {
      if (!_controller.isClosed) _controller.add(goals);
    });
    return _controller.stream;
  }

  SavingsGoal _mapRow(Map<String, dynamic> row) {
    return SavingsGoal(
      id: row['id'] as String,
      name: row['name'] as String,
      targetAmountPaise: row['targetAmountPaise'] as int,
      savedAmountPaise: row['savedAmountPaise'] as int,
      monthlyContributionPaise: row['monthlyContributionPaise'] as int?,
      targetDate: row['targetDate'] != null ? DateFormatter.fromIso(row['targetDate'] as String) : null,
      icon: (row['icon'] as String?) ?? 'star',
      createdAt: DateFormatter.fromIso(row['createdAt'] as String),
      updatedAt: DateFormatter.fromIso(row['updatedAt'] as String),
      deletedAt: row['deletedAt'] != null ? DateFormatter.fromIso(row['deletedAt'] as String) : null,
    );
  }
}
