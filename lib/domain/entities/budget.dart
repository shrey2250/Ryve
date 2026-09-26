import 'package:equatable/equatable.dart';

/// Monthly Budget Entity (Paise stored as integer)
class MonthlyBudget extends Equatable {
  const MonthlyBudget({
    required this.id,
    required this.month, // Format: 'yyyy-MM', e.g. '2026-09'
    required this.amountPaise,
    this.categoryId,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String month;
  final int amountPaise;
  final String? categoryId;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get amount => amountPaise / 100.0;

  MonthlyBudget copyWith({
    String? id,
    String? month,
    int? amountPaise,
    String? categoryId,
    String? categoryName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      month: month ?? this.month,
      amountPaise: amountPaise ?? this.amountPaise,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        month,
        amountPaise,
        categoryId,
        categoryName,
        createdAt,
        updatedAt,
      ];
}
