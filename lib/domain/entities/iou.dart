import 'package:equatable/equatable.dart';

enum IouType {
  lent('lent', 'Lent (Owed to you)', 'Asset'),
  borrowed('borrowed', 'Borrowed (You owe)', 'Liability');

  const IouType(this.value, this.label, this.category);
  final String value;
  final String label;
  final String category;

  static IouType fromValue(String value) =>
      IouType.values.firstWhere(
        (t) => t.value == value,
        orElse: () => IouType.lent,
      );

  bool get isLent => this == IouType.lent;
  bool get isBorrowed => this == IouType.borrowed;
}

enum IouStatus {
  active('active'),
  settled('settled');

  const IouStatus(this.value);
  final String value;

  static IouStatus fromValue(String value) =>
      IouStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => IouStatus.active,
      );

  bool get isActive => this == IouStatus.active;
  bool get isSettled => this == IouStatus.settled;
}

/// IOU Record Entity
class IouRecord extends Equatable {
  const IouRecord({
    required this.id,
    required this.personId,
    this.personName,
    required this.type,
    required this.originalAmountPaise,
    this.paidAmountPaise = 0,
    this.dueDate,
    this.note,
    this.status = IouStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.repayments = const [],
  });

  final String id;
  final String personId;
  final String? personName;
  final IouType type;
  final int originalAmountPaise;
  final int paidAmountPaise;
  final DateTime? dueDate;
  final String? note;
  final IouStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<IouRepayment> repayments;

  bool get isDeleted => deletedAt != null;
  int get remainingAmountPaise =>
      (originalAmountPaise - paidAmountPaise).clamp(0, originalAmountPaise);

  double get originalAmount => originalAmountPaise / 100.0;
  double get remainingAmount => remainingAmountPaise / 100.0;

  IouRecord copyWith({
    String? id,
    String? personId,
    String? personName,
    IouType? type,
    int? originalAmountPaise,
    int? paidAmountPaise,
    DateTime? dueDate,
    String? note,
    IouStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<IouRepayment>? repayments,
  }) {
    return IouRecord(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      type: type ?? this.type,
      originalAmountPaise: originalAmountPaise ?? this.originalAmountPaise,
      paidAmountPaise: paidAmountPaise ?? this.paidAmountPaise,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      repayments: repayments ?? this.repayments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        personId,
        personName,
        type,
        originalAmountPaise,
        paidAmountPaise,
        dueDate,
        note,
        status,
        createdAt,
        updatedAt,
        deletedAt,
        repayments,
      ];
}

/// IOU Repayment Entity
class IouRepayment extends Equatable {
  const IouRepayment({
    required this.id,
    required this.iouId,
    required this.amountPaise,
    required this.date,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String iouId;
  final int amountPaise;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  double get amount => amountPaise / 100.0;

  @override
  List<Object?> get props => [
        id,
        iouId,
        amountPaise,
        date,
        note,
        createdAt,
      ];
}

/// Summary of lending and borrowing
class IouSummary extends Equatable {
  const IouSummary({
    required this.totalLentPaise,
    required this.totalBorrowedPaise,
  });

  final int totalLentPaise; // You are owed
  final int totalBorrowedPaise; // You owe

  int get netBalancePaise => totalLentPaise - totalBorrowedPaise;

  @override
  List<Object?> get props => [totalLentPaise, totalBorrowedPaise];
}
