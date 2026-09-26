import '../../domain/entities/category.dart';
import '../../core/utils/date_formatter.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.isSystem,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String icon;
  final bool isSystem;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        isSystem: (map['isSystem'] as int) == 1,
        isArchived: (map['isArchived'] as int) == 1,
        createdAt: DateFormatter.fromIso(map['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(map['updatedAt'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'isSystem': isSystem ? 1 : 0,
        'isArchived': isArchived ? 1 : 0,
        'createdAt': DateFormatter.toIso(createdAt),
        'updatedAt': DateFormatter.toIso(updatedAt),
      };

  Category toDomain() => Category(
        id: id,
        name: name,
        icon: icon,
        isSystem: isSystem,
        isArchived: isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory CategoryModel.fromDomain(Category category) => CategoryModel(
        id: category.id,
        name: category.name,
        icon: category.icon,
        isSystem: category.isSystem,
        isArchived: category.isArchived,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      );
}
