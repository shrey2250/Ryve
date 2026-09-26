import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'database_providers.dart';

/// Category repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepositoryImpl(db);
});

/// Reactive stream of all non-archived categories
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});

/// Expense categories stream
final expenseCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});

/// Income categories stream
final incomeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});

/// Single category by ID
final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, id) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategoryById(id);
});
