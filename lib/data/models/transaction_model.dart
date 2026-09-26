import '../../domain/entities/transaction.dart';
import '../../core/utils/date_formatter.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountPaise,
    this.categoryId,
    required this.description,
    this.merchant,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.categoryName,
    this.categoryIcon,
    this.accountName,
  });

  final String id;
  final String accountId;
  final String type;
  final int amountPaise;
  final String? categoryId;
  final String description;
  final String? merchant;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? categoryName;
  final String? categoryIcon;
  final String? accountName;

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] as String,
        accountId: map['accountId'] as String,
        type: map['type'] as String,
        amountPaise: map['amountPaise'] as int,
        categoryId: map['categoryId'] as String?,
        description: map['description'] as String? ?? '',
        merchant: map['merchant'] as String?,
        date: DateFormatter.fromIso(map['date'] as String),
        note: map['note'] as String?,
        createdAt: DateFormatter.fromIso(map['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(map['updatedAt'] as String),
        deletedAt: map['deletedAt'] != null
            ? DateFormatter.fromIso(map['deletedAt'] as String)
            : null,
        categoryName: map['categoryName'] as String?,
        categoryIcon: map['categoryIcon'] as String?,
        accountName: map['accountName'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountId': accountId,
        'type': type,
        'amountPaise': amountPaise,
        'categoryId': categoryId,
        'description': description,
        'merchant': merchant,
        'date': DateFormatter.toIso(date),
        'note': note,
        'createdAt': DateFormatter.toIso(createdAt),
        'updatedAt': DateFormatter.toIso(updatedAt),
        'deletedAt': deletedAt != null ? DateFormatter.toIso(deletedAt!) : null,
      };

  Transaction toDomain() => Transaction(
        id: id,
        accountId: accountId,
        type: TransactionType.fromValue(type),
        amountPaise: amountPaise,
        categoryId: categoryId,
        description: description,
        merchant: merchant,
        date: date,
        note: note,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        accountName: accountName,
      );

  factory TransactionModel.fromDomain(Transaction t) => TransactionModel(
        id: t.id,
        accountId: t.accountId,
        type: t.type.value,
        amountPaise: t.amountPaise,
        categoryId: t.categoryId,
        description: t.description,
        merchant: t.merchant,
        date: t.date,
        note: t.note,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
        deletedAt: t.deletedAt,
      );
}
