import 'package:equatable/equatable.dart';

/// Savings Goal Entity (Stored in integer paise)
class SavingsGoal extends Equatable {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmountPaise,
    this.savedAmountPaise = 0,
    this.monthlyContributionPaise,
    this.targetDate,
    this.icon = 'star',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final int targetAmountPaise;
  final int savedAmountPaise;
  final int? monthlyContributionPaise;
  final DateTime? targetDate;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  double get targetAmount => targetAmountPaise / 100.0;
  double get savedAmount => savedAmountPaise / 100.0;
  double get progress => targetAmountPaise > 0
      ? (savedAmountPaise / targetAmountPaise).clamp(0.0, 1.0)
      : 0.0;
  int get remainingAmountPaise =>
      (targetAmountPaise - savedAmountPaise).clamp(0, targetAmountPaise);

  SavingsGoal copyWith({
    String? id,
    String? name,
    int? targetAmountPaise,
    int? savedAmountPaise,
    int? monthlyContributionPaise,
    DateTime? targetDate,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountPaise: targetAmountPaise ?? this.targetAmountPaise,
      savedAmountPaise: savedAmountPaise ?? this.savedAmountPaise,
      monthlyContributionPaise:
          monthlyContributionPaise ?? this.monthlyContributionPaise,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmountPaise,
        savedAmountPaise,
        monthlyContributionPaise,
        targetDate,
        icon,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
