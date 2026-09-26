import 'package:equatable/equatable.dart';

/// Person Entity (For Lending / Borrowing contacts)
class Person extends Equatable {
  const Person({
    required this.id,
    required this.name,
    this.avatarInitials,
    required this.createdAt,
    required this.updatedAt,
    this.totalLentPaise = 0,
    this.totalBorrowedPaise = 0,
    this.netBalancePaise = 0,
  });

  final String id;
  final String name;
  final String? avatarInitials;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalLentPaise;
  final int totalBorrowedPaise;
  final int netBalancePaise; // Positive = they owe user, Negative = user owes them

  String get initials {
    if (avatarInitials != null && avatarInitials!.isNotEmpty) {
      return avatarInitials!;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Person copyWith({
    String? id,
    String? name,
    String? avatarInitials,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalLentPaise,
    int? totalBorrowedPaise,
    int? netBalancePaise,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalLentPaise: totalLentPaise ?? this.totalLentPaise,
      totalBorrowedPaise: totalBorrowedPaise ?? this.totalBorrowedPaise,
      netBalancePaise: netBalancePaise ?? this.netBalancePaise,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarInitials,
        createdAt,
        updatedAt,
        totalLentPaise,
        totalBorrowedPaise,
        netBalancePaise,
      ];
}
