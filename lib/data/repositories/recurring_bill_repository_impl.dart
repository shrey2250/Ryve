import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/recurring_bill.dart';
import '../../domain/repositories/recurring_bill_repository.dart';
import '../models/recurring_bill_model.dart';

class RecurringBillRepositoryImpl implements RecurringBillRepository {
  RecurringBillRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;
  final _controller = StreamController<List<RecurringBill>>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  @override
  void notifyListeners() {
    getRecurringBills().then((bills) {
      if (!_controller.isClosed) _controller.add(bills);
    });
  }

  @override
  Stream<List<RecurringBill>> watchRecurringBills() {
    notifyListeners();
    return _controller.stream;
  }

  @override
  Future<List<RecurringBill>> getRecurringBills() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        b.*,
        c.name AS categoryName,
        c.icon AS categoryIcon,
        a.name AS accountName
      FROM ${DatabaseSchema.recurringBills} b
      LEFT JOIN ${DatabaseSchema.categories} c ON b.categoryId = c.id
      LEFT JOIN ${DatabaseSchema.accounts}   a ON b.accountId  = a.id
      WHERE b.deletedAt IS NULL
      ORDER BY b.nextDueDate ASC
    ''');

    return rows.map((r) => RecurringBillModel.fromMap(r).toDomain()).toList();
  }

  @override
  Future<RecurringBill?> getRecurringBillById(String id) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        b.*,
        c.name AS categoryName,
        c.icon AS categoryIcon,
        a.name AS accountName
      FROM ${DatabaseSchema.recurringBills} b
      LEFT JOIN ${DatabaseSchema.categories} c ON b.categoryId = c.id
      LEFT JOIN ${DatabaseSchema.accounts}   a ON b.accountId  = a.id
      WHERE b.id = ? AND b.deletedAt IS NULL
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;
    return RecurringBillModel.fromMap(rows.first).toDomain();
  }

  @override
  Future<RecurringBill> createRecurringBill(RecurringBill bill) async {
    final db = await _db;
    await db.insert(
      DatabaseSchema.recurringBills,
      RecurringBillModel.fromDomain(bill).toMap(),
    );
    notifyListeners();
    return bill;
  }

  @override
  Future<void> updateRecurringBill(RecurringBill bill) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());
    final map = RecurringBillModel.fromDomain(bill).toMap();
    map['updatedAt'] = now;

    await db.update(
      DatabaseSchema.recurringBills,
      map,
      where: 'id = ?',
      whereArgs: [bill.id],
    );
    notifyListeners();
  }

  @override
  Future<void> deleteRecurringBill(String id) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());
    await db.update(
      DatabaseSchema.recurringBills,
      {'deletedAt': now, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  @override
  Future<void> toggleActive(String id, bool isActive) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());
    await db.update(
      DatabaseSchema.recurringBills,
      {'isActive': isActive ? 1 : 0, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }
}
