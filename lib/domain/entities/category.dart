import 'package:equatable/equatable.dart';

/// Pure domain entity for a transaction category.
///
/// System categories are seeded on install and cannot be deleted.
/// Users can create custom categories and archive (soft-delete) them.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.isSystem = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Emoji or icon identifier. V1 uses emoji strings.
  final String icon;

  /// Convenience helper for icon identifier name
  String get iconName => icon;

  /// Default color hex for category icon container
  String get colorHex => '0xFF059669';

  /// System categories are seeded and protected from deletion.
  final bool isSystem;

  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isSystem,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, isSystem, isArchived, createdAt, updatedAt];
}
