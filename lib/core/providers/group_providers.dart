import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import 'database_providers.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GroupRepositoryImpl(db);
});

final groupsProvider = StreamProvider<List<Group>>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.watchGroups();
});

final totalGroupBalanceProvider = Provider<AsyncValue<int>>((ref) {
  final groupsAsync = ref.watch(groupsProvider);
  return groupsAsync.whenData((groups) {
    return groups.fold<int>(0, (sum, g) => sum + g.userBalancePaise);
  });
});

final groupMembersProvider = FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getGroupMembers(groupId);
});

final groupExpensesProvider = FutureProvider.family<List<GroupExpense>, String>((ref, groupId) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getGroupExpenses(groupId);
});

final groupDebtsProvider = FutureProvider.family<List<MemberDebt>, String>((ref, groupId) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getGroupDebts(groupId);
});

final groupSettlementsProvider = FutureProvider.family<List<Settlement>, String>((ref, groupId) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getSettlements(groupId);
});
