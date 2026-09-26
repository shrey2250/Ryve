import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../utils/date_formatter.dart';
import 'database_providers.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(db);
});

final currentMonthKeyProvider = Provider<String>((ref) {
  return DateFormatter.formatMonthKey(DateTime.now());
});

final currentMonthBudgetProvider = StreamProvider<MonthlyBudget?>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  final month = ref.watch(currentMonthKeyProvider);
  return repo.watchMonthlyBudget(month);
});

final categoryBudgetsProvider = FutureProvider.family<List<MonthlyBudget>, String>((ref, month) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getCategoryBudgets(month);
});
