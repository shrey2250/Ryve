import '../../domain/entities/account.dart';
import '../../core/utils/date_formatter.dart';

/// SQLite data model for Account.
/// Handles serialization to/from Map<String, dynamic>.
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balancePaise,
    required this.currency,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final int balancePaise;
  final String currency;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        balancePaise: map['balancePaise'] as int,
        currency: map['currency'] as String? ?? 'INR',
        isArchived: (map['isArchived'] as int) == 1,
        createdAt: DateFormatter.fromIso(map['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(map['updatedAt'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'balancePaise': balancePaise,
        'currency': currency,
        'isArchived': isArchived ? 1 : 0,
        'createdAt': DateFormatter.toIso(createdAt),
        'updatedAt': DateFormatter.toIso(updatedAt),
      };

  Account toDomain() => Account(
        id: id,
        name: name,
        type: AccountType.fromValue(type),
        balancePaise: balancePaise,
        currency: currency,
        isArchived: isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory AccountModel.fromDomain(Account account) => AccountModel(
        id: account.id,
        name: account.name,
        type: account.type.value,
        balancePaise: account.balancePaise,
        currency: account.currency,
        isArchived: account.isArchived,
        createdAt: account.createdAt,
        updatedAt: account.updatedAt,
      );
}
