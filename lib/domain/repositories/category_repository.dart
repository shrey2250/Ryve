import '../entities/category.dart';

abstract class CategoryRepository {
  /// All non-archived categories.
  Future<List<Category>> getCategories();

  /// Watch categories reactively.
  Stream<List<Category>> watchCategories();

  /// Get category by ID.
  Future<Category?> getCategoryById(String id);

  /// Create a custom user category.
  Future<Category> createCategory(Category category);

  /// Update a category (system categories cannot have name changed).
  Future<void> updateCategory(Category category);

  /// Archive a category (soft-delete). System categories cannot be archived.
  Future<void> archiveCategory(String id);
}
