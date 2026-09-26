import '../entities/goal.dart';

abstract class GoalRepository {
  Future<List<SavingsGoal>> getGoals();
  Future<SavingsGoal?> getGoalById(String id);
  Future<SavingsGoal> createGoal(SavingsGoal goal);
  Future<void> updateGoal(SavingsGoal goal);
  Future<void> deleteGoal(String id);
  Future<void> addContribution(String goalId, int amountPaise);
  Stream<List<SavingsGoal>> watchGoals();
  void notifyListeners();
}
