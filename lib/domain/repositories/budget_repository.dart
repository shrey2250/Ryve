import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<MonthlyBudget?> getMonthlyBudget(String month);
  Future<List<MonthlyBudget>> getCategoryBudgets(String month);
  Future<void> setMonthlyBudget(MonthlyBudget budget);
  Future<void> deleteBudget(String id);
  Stream<MonthlyBudget?> watchMonthlyBudget(String month);
  void notifyListeners();
}
