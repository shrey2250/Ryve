import '../entities/transaction.dart';
import '../entities/transfer.dart';

/// Monthly financial summary — derived from transaction data
class MonthlySummary {
  const MonthlySummary({
    required this.incomePaise,
    required this.expensePaise,
    required this.month,
  });

  final int incomePaise;
  final int expensePaise;
  final DateTime month;

  /// Savings = income − expenses (can be negative if overspent)
  int get savedPaise => incomePaise - expensePaise;

  MonthlySummary copyWith({
    int? incomePaise,
    int? expensePaise,
    DateTime? month,
  }) =>
      MonthlySummary(
        incomePaise: incomePaise ?? this.incomePaise,
        expensePaise: expensePaise ?? this.expensePaise,
        month: month ?? this.month,
      );
}

/// Transaction filter parameters
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.accountId,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  bool get isEmpty =>
      type == null &&
      accountId == null &&
      categoryId == null &&
      startDate == null &&
      endDate == null &&
      (searchQuery == null || searchQuery!.isEmpty);
}

/// Repository interface for transaction operations.
abstract class TransactionRepository {
  /// Paginated transaction list, ordered by date DESC.
  /// Excludes soft-deleted records.
  Future<List<Transaction>> getTransactions({
    TransactionFilter? filter,
    int limit = 50,
    int offset = 0,
  });

  /// Watch transactions reactively (refreshes on any change).
  Stream<List<Transaction>> watchTransactions({TransactionFilter? filter});

  /// Get a single transaction by ID.
  Future<Transaction?> getTransactionById(String id);

  /// Recent transactions for the Home screen.
  Future<List<Transaction>> getRecentTransactions({int limit = 20});

  /// Monthly summary: total income and expense for a given month.
  Future<MonthlySummary> getMonthlySummary(DateTime month);

  /// Create a transaction and update the account balance atomically.
  Future<Transaction> createTransaction(Transaction transaction);

  /// Update an existing transaction and recalculate account balance.
  Future<void> updateTransaction(Transaction transaction);

  /// Soft-delete a transaction. Sets deletedAt, reverses balance impact.
  Future<void> deleteTransaction(String id);

  // ─── Transfers ─────────────────────────────────────────────────────────
  Future<Transfer> createTransfer(Transfer transfer);
  Future<void> deleteTransfer(String id);
  Future<List<Transfer>> getRecentTransfers({int limit = 10});
}
