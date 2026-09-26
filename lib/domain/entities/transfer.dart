import 'package:equatable/equatable.dart';

/// Pure domain entity for an account-to-account transfer.
///
/// IMPORTANT financial rules:
/// - Transfers do NOT count as income or expense.
/// - fromAccount.balancePaise -= amountPaise
/// - toAccount.balancePaise += amountPaise
/// - Both updates happen atomically in a single DB transaction.
/// - Net effect on total wealth = zero (money moves, not created/destroyed).
class Transfer extends Equatable {
  const Transfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountPaise,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    // Joined display fields
    this.fromAccountName,
    this.toAccountName,
  });

  final String id;
  final String fromAccountId;
  final String toAccountId;

  /// Always positive paise.
  final int amountPaise;

  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Denormalized display fields
  final String? fromAccountName;
  final String? toAccountName;

  bool get isDeleted => deletedAt != null;

  Transfer copyWith({
    String? id,
    String? fromAccountId,
    String? toAccountId,
    int? amountPaise,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? fromAccountName,
    String? toAccountName,
  }) {
    return Transfer(
      id: id ?? this.id,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amountPaise: amountPaise ?? this.amountPaise,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      fromAccountName: fromAccountName ?? this.fromAccountName,
      toAccountName: toAccountName ?? this.toAccountName,
    );
  }

  @override
  List<Object?> get props => [
        id, fromAccountId, toAccountId, amountPaise, date, note,
        createdAt, updatedAt, deletedAt,
      ];
}
