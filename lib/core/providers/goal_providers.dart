import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import 'database_providers.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GoalRepositoryImpl(db);
});

final goalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.watchGoals();
});

final goalByIdProvider = FutureProvider.family<SavingsGoal?, String>((ref, id) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getGoalById(id);
});
