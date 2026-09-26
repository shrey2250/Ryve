import 'package:equatable/equatable.dart';

/// Group Entity
class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.members = const [],
    this.totalExpensePaise = 0,
    this.userBalancePaise = 0,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<GroupMember> members;
  final int totalExpensePaise;
  final int userBalancePaise;

  bool get isDeleted => deletedAt != null;

  Group copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<GroupMember>? members,
    int? totalExpensePaise,
    int? userBalancePaise,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      members: members ?? this.members,
      totalExpensePaise: totalExpensePaise ?? this.totalExpensePaise,
      userBalancePaise: userBalancePaise ?? this.userBalancePaise,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        createdAt,
        updatedAt,
        deletedAt,
        members,
        totalExpensePaise,
        userBalancePaise,
      ];
}

/// Group Member Entity
class GroupMember extends Equatable {
  const GroupMember({
    required this.id,
    required this.groupId,
    required this.name,
    this.isCurrentUser = false,
    required this.createdAt,
    required this.updatedAt,
    this.netBalancePaise = 0,
  });

  final String id;
  final String groupId;
  final String name;
  final bool isCurrentUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int netBalancePaise;

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? name,
    bool? isCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? netBalancePaise,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      netBalancePaise: netBalancePaise ?? this.netBalancePaise,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        name,
        isCurrentUser,
        createdAt,
        updatedAt,
        netBalancePaise,
      ];
}

/// Group Expense Entity
class GroupExpense extends Equatable {
  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amountPaise,
    required this.paidByMemberId,
    this.paidByMemberName,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.splits = const [],
  });

  final String id;
  final String groupId;
  final String description;
  final int amountPaise;
  final String paidByMemberId;
  final String? paidByMemberName;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<ExpenseSplit> splits;

  bool get isDeleted => deletedAt != null;

  GroupExpense copyWith({
    String? id,
    String? groupId,
    String? description,
    int? amountPaise,
    String? paidByMemberId,
    String? paidByMemberName,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<ExpenseSplit>? splits,
  }) {
    return GroupExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amountPaise: amountPaise ?? this.amountPaise,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      paidByMemberName: paidByMemberName ?? this.paidByMemberName,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      splits: splits ?? this.splits,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        description,
        amountPaise,
        paidByMemberId,
        paidByMemberName,
        date,
        note,
        createdAt,
        updatedAt,
        deletedAt,
        splits,
      ];
}

/// Expense Split Entity (Split amount per member)
class ExpenseSplit extends Equatable {
  const ExpenseSplit({
    required this.id,
    required this.groupExpenseId,
    required this.memberId,
    this.memberName,
    required this.amountPaise,
    required this.createdAt,
  });

  final String id;
  final String groupExpenseId;
  final String memberId;
  final String? memberName;
  final int amountPaise;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        groupExpenseId,
        memberId,
        memberName,
        amountPaise,
        createdAt,
      ];
}

/// Group Debt Settlement Entity
class Settlement extends Equatable {
  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    this.fromMemberName,
    required this.toMemberId,
    this.toMemberName,
    required this.amountPaise,
    required this.date,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String fromMemberId;
  final String? fromMemberName;
  final String toMemberId;
  final String? toMemberName;
  final int amountPaise;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        groupId,
        fromMemberId,
        fromMemberName,
        toMemberId,
        toMemberName,
        amountPaise,
        date,
        note,
        createdAt,
      ];
}

/// Computed debt balance between two members
class MemberDebt extends Equatable {
  const MemberDebt({
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amountPaise,
  });

  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final int amountPaise;

  @override
  List<Object?> get props => [
        fromMemberId,
        fromMemberName,
        toMemberId,
        toMemberName,
        amountPaise,
      ];
}
