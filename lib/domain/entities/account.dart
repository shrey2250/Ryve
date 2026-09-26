import 'package:equatable/equatable.dart';

/// Account types in RYVE
enum AccountType {
  cash('cash', 'Cash', '💵'),
  online('online', 'Online', '🌐'),
  bank('bank', 'Bank', '🏦'),
  upi('upi', 'UPI', '📱'),
  creditCard('credit_card', 'Credit Card', '💳'),
  other('other', 'Other', '🪙');

  const AccountType(this.value, this.label, this.icon);

  final String value;
  final String label;
  final String icon;

  static AccountType fromValue(String value) =>
      AccountType.values.firstWhere(
        (t) => t.value == value,
        orElse: () => AccountType.other,
      );
}

/// Pure domain entity — no SQLite dependencies.
///
/// [balancePaise] is always in integer paise.
/// Display formatting happens only at the UI layer.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balancePaise,
    this.currency = 'INR',
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Balance stored as integer paise. Never use floating-point.
  final int balancePaise;

  /// Convenience getter for balance in rupees
  double get balance => balancePaise / 100.0;

  /// Icon code point helper for UI display
  int get iconCodePoint {
    switch (type) {
      case AccountType.online:
        return 0xe351; // language / globe
      case AccountType.bank:
        return 0xe040; // account_balance
      case AccountType.upi:
        return 0xe4a2; // phone_android
      case AccountType.creditCard:
        return 0xe19f; // credit_card
      case AccountType.cash:
        return 0xf04d7; // payments
      case AccountType.other:
        return 0xe041; // account_balance_wallet
    }
  }

  final String currency;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? balancePaise,
    String? currency,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balancePaise: balancePaise ?? this.balancePaise,
      currency: currency ?? this.currency,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, type, balancePaise, currency, isArchived, createdAt, updatedAt,
      ];
}
