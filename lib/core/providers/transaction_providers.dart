import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../utils/date_formatter.dart';
import 'account_providers.dart';
import 'database_providers.dart';

/// Transaction repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  return TransactionRepositoryImpl(db, accountRepo);
});

/// Reactive stream of all transactions without filter
final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactions();
});

/// Reactive stream of all transactions (with optional filter)
final transactionsProvider = StreamProvider.family<List<Transaction>, TransactionFilter?>(
  (ref, filter) {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.watchTransactions(filter: filter);
  },
);

/// Recent transactions for Home screen (top 20)
final recentTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final allAsync = ref.watch(allTransactionsProvider);
  return allAsync.whenData((list) => list.take(20).toList());
});

/// Monthly summary for the current month - reactive with allTransactionsProvider
final currentMonthSummaryProvider = Provider<AsyncValue<MonthlySummary>>((ref) {
  final allAsync = ref.watch(allTransactionsProvider);
  return allAsync.whenData((transactions) {
    final now = DateTime.now();
    final start = DateFormatter.startOfMonth(now);
    final end = DateFormatter.endOfMonth(now);

    int income = 0;
    int expense = 0;

    for (final tx in transactions) {
      if (tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(end.add(const Duration(seconds: 1)))) {
        if (tx.type == TransactionType.income) {
          income += tx.amountPaise;
        } else if (tx.type == TransactionType.expense) {
          expense += tx.amountPaise;
        }
      }
    }

    return MonthlySummary(
      incomePaise: income,
      expensePaise: expense,
      month: now,
    );
  });
});

final currentMonthlySummaryProvider = currentMonthSummaryProvider;

/// Monthly summary for a specific month
final monthlySummaryProvider = FutureProvider.family<MonthlySummary, DateTime>(
  (ref, month) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getMonthlySummary(month);
  },
);

/// Single transaction by ID
final transactionByIdProvider = FutureProvider.family<Transaction?, String>(
  (ref, id) async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getTransactionById(id);
  },
);

/// Recent transfers
final recentTransfersProvider = FutureProvider<List<Transfer>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getRecentTransfers(limit: 20);
});

/// Item representing spending distribution per category
class CategorySpendingItem {
  const CategorySpendingItem({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.colorHex,
    required this.amountPaise,
    required this.percentage,
    required this.transactionCount,
  });

  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String colorHex;
  final int amountPaise;
  final double percentage; // 0.0 to 100.0
  final int transactionCount;
}

/// Reactive breakdown of category spending for the current month
final categorySpendingBreakdownProvider = Provider<AsyncValue<List<CategorySpendingItem>>>((ref) {
  final allAsync = ref.watch(allTransactionsProvider);
  return allAsync.whenData((transactions) {
    final now = DateTime.now();
    final start = DateFormatter.startOfMonth(now);
    final end = DateFormatter.endOfMonth(now);

    final Map<String, (String name, String icon, String color, int amount, int count)> map = {};
    int totalExpensePaise = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(end.add(const Duration(seconds: 1)))) {
        final catId = tx.categoryId ?? 'uncategorized';
        final catName = tx.categoryName ?? (tx.categoryId != null ? 'Category' : 'Other');
        final catIcon = tx.categoryIcon ?? '🏷️';
        final catColor = tx.categoryColorHex ?? '0xFF059669';

        final current = map[catId];
        if (current != null) {
          map[catId] = (current.$1, current.$2, current.$3, current.$4 + tx.amountPaise, current.$5 + 1);
        } else {
          map[catId] = (catName, catIcon, catColor, tx.amountPaise, 1);
        }
        totalExpensePaise += tx.amountPaise;
      }
    }

    if (totalExpensePaise == 0) return const [];

    final items = map.entries.map((e) {
      final percentage = (e.value.$4 / totalExpensePaise) * 100.0;
      return CategorySpendingItem(
        categoryId: e.key,
        categoryName: e.value.$1,
        categoryIcon: e.value.$2,
        colorHex: e.value.$3,
        amountPaise: e.value.$4,
        percentage: percentage,
        transactionCount: e.value.$5,
      );
    }).toList();

    // Sort highest spending first
    items.sort((a, b) => b.amountPaise.compareTo(a.amountPaise));
    return items;
  });
});

/// Metric model for calm financial runway and savings rate
class FinancialHealthMetrics {
  const FinancialHealthMetrics({
    required this.runwayMonths,
    required this.savingsRatePercent,
    required this.hasExpenseHistory,
  });

  final double? runwayMonths;
  final double savingsRatePercent;
  final bool hasExpenseHistory;
}

/// Reactive financial health metrics provider
final financialHealthProvider = Provider<AsyncValue<FinancialHealthMetrics>>((ref) {
  final totalBalanceAsync = ref.watch(totalBalanceProvider);
  final monthlySummaryAsync = ref.watch(currentMonthSummaryProvider);

  return totalBalanceAsync.when(
    data: (balance) {
      return monthlySummaryAsync.when(
        data: (summary) {
          final income = summary.incomePaise;
          final expense = summary.expensePaise;

          // Savings rate: ((Income - Expense) / Income) * 100
          final double savingsRate = income > 0
              ? (((income - expense) / income) * 100).clamp(-100.0, 100.0)
              : 0.0;

          // Runway: Liquid balance / Monthly expense
          final double? runway = expense > 0
              ? (balance > 0 ? (balance / expense) : 0.0)
              : null;

          return AsyncValue.data(FinancialHealthMetrics(
            runwayMonths: runway,
            savingsRatePercent: savingsRate,
            hasExpenseHistory: expense > 0,
          ));
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

