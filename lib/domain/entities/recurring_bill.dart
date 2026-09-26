import 'package:equatable/equatable.dart';

/// Billing cycle frequency for recurring subscriptions and bills.
enum BillingCycle {
  monthly('monthly'),
  yearly('yearly'),
  weekly('weekly');

  const BillingCycle(this.value);
  final String value;

  static BillingCycle fromValue(String value) =>
      BillingCycle.values.firstWhere(
        (c) => c.value == value,
        orElse: () => BillingCycle.monthly,
      );
}

/// Pure domain entity for a recurring bill or subscription.
class RecurringBill extends Equatable {
  const RecurringBill({
    required this.id,
    required this.name,
    required this.amountPaise,
    this.cycle = BillingCycle.monthly,
    required this.nextDueDate,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.accountId,
    this.accountName,
    this.icon = 'receipt',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final int amountPaise;
  final BillingCycle cycle;
  final DateTime nextDueDate;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? accountId;
  final String? accountName;
  final String icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Monthly normalized cost in paise for committed spend calculation
  int get monthlyNormalizedPaise {
    switch (cycle) {
      case BillingCycle.monthly:
        return amountPaise;
      case BillingCycle.yearly:
        return (amountPaise / 12.0).round();
      case BillingCycle.weekly:
        return ((amountPaise * 52) / 12.0).round();
    }
  }

  /// Days remaining until the next due date
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  RecurringBill copyWith({
    String? id,
    String? name,
    int? amountPaise,
    BillingCycle? cycle,
    DateTime? nextDueDate,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? accountId,
    String? accountName,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RecurringBill(
      id: id ?? this.id,
      name: name ?? this.name,
      amountPaise: amountPaise ?? this.amountPaise,
      cycle: cycle ?? this.cycle,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        amountPaise,
        cycle,
        nextDueDate,
        categoryId,
        categoryName,
        categoryIcon,
        accountId,
        accountName,
        icon,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
