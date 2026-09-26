import 'package:equatable/equatable.dart';

/// Transaction types — expense reduces balance, income increases balance, transfer moves money.
enum TransactionType {
  expense('expense'),
  income('income'),
  transfer('transfer');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromValue(String value) =>
      TransactionType.values.firstWhere(
        (t) => t.value == value,
        orElse: () => TransactionType.expense,
      );

  bool get isExpense => this == TransactionType.expense;
  bool get isIncome => this == TransactionType.income;
  bool get isTransfer => this == TransactionType.transfer;
}

/// Pure domain entity for a financial transaction.
class Transaction extends Equatable {
  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    int? amountPaise,
    double? amount,
    this.categoryId,
    this.description = '',
    String? merchantName,
    String? merchant,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.categoryName,
    String? categoryIconName,
    String? categoryIcon,
    this.categoryColorHex = '0xFF059669',
    this.accountName,
  })  : amountPaise = amountPaise ?? ((amount ?? 0.0) * 100).round(),
        merchant = merchant ?? merchantName,
        categoryIcon = categoryIcon ?? categoryIconName;

  final String id;
  final String accountId;
  final TransactionType type;
  final int amountPaise;
  final String? categoryId;
  final String description;
  final String? merchant;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Joined / Display fields
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorHex;
  final String? accountName;

  // Convenience getters for UI
  double get amount => amountPaise / 100.0;
  String? get merchantName => merchant;
  String? get categoryIconName => categoryIcon;

  bool get isDeleted => deletedAt != null;

  int get signedAmountPaise =>
      type.isExpense ? -amountPaise : amountPaise;

  String get displayName =>
      (merchant?.isNotEmpty == true) ? merchant! : description;

  Transaction copyWith({
    String? id,
    String? accountId,
    TransactionType? type,
    int? amountPaise,
    double? amount,
    String? categoryId,
    String? description,
    String? merchant,
    String? merchantName,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryIconName,
    String? categoryColorHex,
    String? accountName,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amountPaise: amountPaise ?? (amount != null ? (amount * 100).round() : this.amountPaise),
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      merchant: merchant ?? merchantName ?? this.merchant,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? categoryIconName ?? this.categoryIcon,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      accountName: accountName ?? this.accountName,
    );
  }

  @override
  List<Object?> get props => [
        id, accountId, type, amountPaise, categoryId, description,
        merchant, date, note, createdAt, updatedAt, deletedAt,
      ];
}
