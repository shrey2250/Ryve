import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;
  final _controller = StreamController<List<Category>>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  void _notifyListeners() {
    getCategories().then((cats) {
      if (!_controller.isClosed) _controller.add(cats);
    });
  }

  @override
  Future<List<Category>> getCategories() async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.categories,
      where: 'isArchived = ?',
      whereArgs: [0],
      orderBy: 'isSystem DESC, name ASC',
    );
    return rows.map((r) => CategoryModel.fromMap(r).toDomain()).toList();
  }

  @override
  Stream<List<Category>> watchCategories() {
    _notifyListeners();
    return _controller.stream;
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.categories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first).toDomain();
  }

  @override
  Future<Category> createCategory(Category category) async {
    final db = await _db;
    await db.insert(
      DatabaseSchema.categories,
      CategoryModel.fromDomain(category).toMap(),
    );
    _notifyListeners();
    return category;
  }

  @override
  Future<void> updateCategory(Category category) async {
    final db = await _db;
    final map = CategoryModel.fromDomain(category).toMap();
    map['updatedAt'] = DateFormatter.toIso(DateTime.now());
    await db.update(
      DatabaseSchema.categories,
      map,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    _notifyListeners();
  }

  @override
  Future<void> archiveCategory(String id) async {
    final db = await _db;
    // Protect system categories from archival
    final rows = await db.query(
      DatabaseSchema.categories,
      columns: ['isSystem'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;
    if ((rows.first['isSystem'] as int) == 1) {
      throw StateError('System categories cannot be archived');
    }

    await db.update(
      DatabaseSchema.categories,
      {
        'isArchived': 1,
        'updatedAt': DateFormatter.toIso(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyListeners();
  }
}
