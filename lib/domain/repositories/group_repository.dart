import '../entities/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups();
  Future<Group?> getGroupById(String id);
  Future<Group> createGroup(String name, List<String> memberNames);
  Future<void> deleteGroup(String id);

  Future<List<GroupMember>> getGroupMembers(String groupId);
  Future<GroupMember> addMember(String groupId, String name);

  Future<List<GroupExpense>> getGroupExpenses(String groupId);
  Future<GroupExpense> createGroupExpense({
    required String groupId,
    required String description,
    required int amountPaise,
    required String paidByMemberId,
    required DateTime date,
    String? note,
    required Map<String, int> splitMap, // memberId -> amountPaise
  });
  Future<void> deleteGroupExpense(String expenseId);

  Future<List<Settlement>> getSettlements(String groupId);
  Future<Settlement> createSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountPaise,
    required DateTime date,
    String? note,
  });

  Future<List<MemberDebt>> getGroupDebts(String groupId);
  Future<int> getTotalGroupBalancePaise();

  Stream<List<Group>> watchGroups();
  Stream<Group?> watchGroup(String id);
  void notifyListeners();
}
