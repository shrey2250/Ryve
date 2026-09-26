import '../../core/utils/date_formatter.dart';
import '../../domain/entities/recurring_bill.dart';

class RecurringBillModel {
  const RecurringBillModel({
    required this.id,
    required this.name,
    required this.amountPaise,
    required this.cycle,
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
  final String cycle;
  final String nextDueDate;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? accountId;
  final String? accountName;
  final String icon;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory RecurringBillModel.fromMap(Map<String, dynamic> map) {
    return RecurringBillModel(
      id: map['id'] as String,
      name: map['name'] as String,
      amountPaise: map['amountPaise'] as int,
      cycle: map['cycle'] as String? ?? 'monthly',
      nextDueDate: map['nextDueDate'] as String,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      categoryIcon: map['categoryIcon'] as String?,
      accountId: map['accountId'] as String?,
      accountName: map['accountName'] as String?,
      icon: map['icon'] as String? ?? 'receipt',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      deletedAt: map['deletedAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amountPaise': amountPaise,
      'cycle': cycle,
      'nextDueDate': nextDueDate,
      'categoryId': categoryId,
      'accountId': accountId,
      'icon': icon,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  RecurringBill toDomain() {
    return RecurringBill(
      id: id,
      name: name,
      amountPaise: amountPaise,
      cycle: BillingCycle.fromValue(cycle),
      nextDueDate: DateFormatter.fromIso(nextDueDate),
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      accountId: accountId,
      accountName: accountName,
      icon: icon,
      isActive: isActive,
      createdAt: DateFormatter.fromIso(createdAt),
      updatedAt: DateFormatter.fromIso(updatedAt),
      deletedAt: deletedAt != null ? DateFormatter.fromIso(deletedAt!) : null,
    );
  }

  factory RecurringBillModel.fromDomain(RecurringBill domain) {
    return RecurringBillModel(
      id: domain.id,
      name: domain.name,
      amountPaise: domain.amountPaise,
      cycle: domain.cycle.value,
      nextDueDate: DateFormatter.toIso(domain.nextDueDate),
      categoryId: domain.categoryId,
      categoryName: domain.categoryName,
      categoryIcon: domain.categoryIcon,
      accountId: domain.accountId,
      accountName: domain.accountName,
      icon: domain.icon,
      isActive: domain.isActive,
      createdAt: DateFormatter.toIso(domain.createdAt),
      updatedAt: DateFormatter.toIso(domain.updatedAt),
      deletedAt: domain.deletedAt != null ? DateFormatter.toIso(domain.deletedAt!) : null,
    );
  }
}
