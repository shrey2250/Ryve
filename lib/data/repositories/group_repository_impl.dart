import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();
  final _groupsController = StreamController<List<Group>>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  @override
  void notifyListeners() {
    getGroups().then((groups) {
      if (!_groupsController.isClosed) _groupsController.add(groups);
    });
  }

  @override
  Future<List<Group>> getGroups() async {
    final db = await _db;
    final groupRows = await db.query(
      DatabaseSchema.groups,
      where: 'deletedAt IS NULL',
      orderBy: 'updatedAt DESC',
    );

    final List<Group> result = [];
    for (final row in groupRows) {
      final groupId = row['id'] as String;
      final members = await getGroupMembers(groupId);

      // Calculate total group expenses
      final expResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amountPaise), 0) AS total
        FROM ${DatabaseSchema.groupExpenses}
        WHERE groupId = ? AND deletedAt IS NULL
      ''', [groupId]);
      final totalExpensePaise = (expResult.first['total'] as int?) ?? 0;

      // Find current user's net balance in this group
      final userMember = members.where((m) => m.isCurrentUser).firstOrNull ??
          (members.isNotEmpty ? members.first : null);
      final userBalance = userMember?.netBalancePaise ?? 0;

      result.add(Group(
        id: groupId,
        name: row['name'] as String,
        createdAt: DateFormatter.fromIso(row['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(row['updatedAt'] as String),
        deletedAt: row['deletedAt'] != null ? DateFormatter.fromIso(row['deletedAt'] as String) : null,
        members: members,
        totalExpensePaise: totalExpensePaise,
        userBalancePaise: userBalance,
      ));
    }

    return result;
  }

  @override
  Future<Group?> getGroupById(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.groups,
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final members = await getGroupMembers(id);

    final expResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amountPaise), 0) AS total
      FROM ${DatabaseSchema.groupExpenses}
      WHERE groupId = ? AND deletedAt IS NULL
    ''', [id]);
    final totalExpensePaise = (expResult.first['total'] as int?) ?? 0;
    final userMember = members.where((m) => m.isCurrentUser).firstOrNull ??
        (members.isNotEmpty ? members.first : null);
    final userBalance = userMember?.netBalancePaise ?? 0;

    return Group(
      id: id,
      name: row['name'] as String,
      createdAt: DateFormatter.fromIso(row['createdAt'] as String),
      updatedAt: DateFormatter.fromIso(row['updatedAt'] as String),
      deletedAt: row['deletedAt'] != null ? DateFormatter.fromIso(row['deletedAt'] as String) : null,
      members: members,
      totalExpensePaise: totalExpensePaise,
      userBalancePaise: userBalance,
    );
  }

  @override
  Future<Group> createGroup(String name, List<String> memberNames) async {
    final db = await _db;
    final groupId = _uuid.v4();
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert(DatabaseSchema.groups, {
        'id': groupId,
        'name': name,
        'createdAt': now,
        'updatedAt': now,
        'deletedAt': null,
      });

      // Always include 'You' as primary member if not explicitly named
      final distinctNames = <String>[];
      if (!memberNames.any((n) => n.trim().toLowerCase() == 'you')) {
        distinctNames.add('You');
      }
      for (final n in memberNames) {
        final clean = n.trim();
        if (clean.isNotEmpty && !distinctNames.contains(clean)) {
          distinctNames.add(clean);
        }
      }

      for (var i = 0; i < distinctNames.length; i++) {
        await txn.insert(DatabaseSchema.groupMembers, {
          'id': _uuid.v4(),
          'groupId': groupId,
          'name': distinctNames[i],
          'createdAt': now,
          'updatedAt': now,
        });
      }
    });

    notifyListeners();
    final created = await getGroupById(groupId);
    return created!;
  }

  @override
  Future<void> deleteGroup(String id) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.update(
      DatabaseSchema.groups,
      {'deletedAt': now, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [id],
    );

    notifyListeners();
  }

  @override
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.groupMembers,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'createdAt ASC',
    );

    final List<GroupMember> members = [];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final memberId = r['id'] as String;
      final name = r['name'] as String;
      final isCurrentUser = (i == 0 || name.toLowerCase() == 'you');

      // Calculate member net balance:
      // + Amount paid by this member in expenses
      final paidResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amountPaise), 0) AS total
        FROM ${DatabaseSchema.groupExpenses}
        WHERE groupId = ? AND paidByMemberId = ? AND deletedAt IS NULL
      ''', [groupId, memberId]);
      final paidForExpenses = (paidResult.first['total'] as int?) ?? 0;

      // - Amount split to this member in expenses
      final splitResult = await db.rawQuery('''
        SELECT COALESCE(SUM(es.amountPaise), 0) AS total
        FROM ${DatabaseSchema.expenseSplits} es
        INNER JOIN ${DatabaseSchema.groupExpenses} ge ON es.groupExpenseId = ge.id
        WHERE ge.groupId = ? AND es.memberId = ? AND ge.deletedAt IS NULL
      ''', [groupId, memberId]);
      final splitShares = (splitResult.first['total'] as int?) ?? 0;

      // + Amount paid by this member in settlements
      final sentResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amountPaise), 0) AS total
        FROM ${DatabaseSchema.settlements}
        WHERE groupId = ? AND fromMemberId = ?
      ''', [groupId, memberId]);
      final paidSettlements = (sentResult.first['total'] as int?) ?? 0;

      // - Amount received by this member in settlements
      final receivedResult = await db.rawQuery('''
        SELECT COALESCE(SUM(amountPaise), 0) AS total
        FROM ${DatabaseSchema.settlements}
        WHERE groupId = ? AND toMemberId = ?
      ''', [groupId, memberId]);
      final receivedSettlements = (receivedResult.first['total'] as int?) ?? 0;

      final netBalance = (paidForExpenses + paidSettlements) - (splitShares + receivedSettlements);

      members.add(GroupMember(
        id: memberId,
        groupId: groupId,
        name: name,
        isCurrentUser: isCurrentUser,
        createdAt: DateFormatter.fromIso(r['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(r['updatedAt'] as String),
        netBalancePaise: netBalance,
      ));
    }

    return members;
  }

  @override
  Future<GroupMember> addMember(String groupId, String name) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());
    final memberId = _uuid.v4();

    await db.insert(DatabaseSchema.groupMembers, {
      'id': memberId,
      'groupId': groupId,
      'name': name.trim(),
      'createdAt': now,
      'updatedAt': now,
    });

    notifyListeners();
    return GroupMember(
      id: memberId,
      groupId: groupId,
      name: name.trim(),
      isCurrentUser: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<GroupExpense>> getGroupExpenses(String groupId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT ge.*, gm.name AS paidByMemberName
      FROM ${DatabaseSchema.groupExpenses} ge
      LEFT JOIN ${DatabaseSchema.groupMembers} gm ON ge.paidByMemberId = gm.id
      WHERE ge.groupId = ? AND ge.deletedAt IS NULL
      ORDER BY ge.date DESC, ge.createdAt DESC
    ''', [groupId]);

    final List<GroupExpense> expenses = [];
    for (final r in rows) {
      final expId = r['id'] as String;
      final splitRows = await db.rawQuery('''
        SELECT es.*, gm.name AS memberName
        FROM ${DatabaseSchema.expenseSplits} es
        LEFT JOIN ${DatabaseSchema.groupMembers} gm ON es.memberId = gm.id
        WHERE es.groupExpenseId = ?
      ''', [expId]);

      final splits = splitRows.map((s) => ExpenseSplit(
            id: s['id'] as String,
            groupExpenseId: expId,
            memberId: s['memberId'] as String,
            memberName: s['memberName'] as String?,
            amountPaise: s['amountPaise'] as int,
            createdAt: DateFormatter.fromIso(s['createdAt'] as String),
          )).toList();

      expenses.add(GroupExpense(
        id: expId,
        groupId: groupId,
        description: r['description'] as String,
        amountPaise: r['amountPaise'] as int,
        paidByMemberId: r['paidByMemberId'] as String,
        paidByMemberName: r['paidByMemberName'] as String?,
        date: DateFormatter.fromIso(r['date'] as String),
        note: r['note'] as String?,
        createdAt: DateFormatter.fromIso(r['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(r['updatedAt'] as String),
        deletedAt: r['deletedAt'] != null ? DateFormatter.fromIso(r['deletedAt'] as String) : null,
        splits: splits,
      ));
    }

    return expenses;
  }

  @override
  Future<GroupExpense> createGroupExpense({
    required String groupId,
    required String description,
    required int amountPaise,
    required String paidByMemberId,
    required DateTime date,
    String? note,
    required Map<String, int> splitMap,
  }) async {
    final db = await _db;
    final expId = _uuid.v4();
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert(DatabaseSchema.groupExpenses, {
        'id': expId,
        'groupId': groupId,
        'description': description,
        'amountPaise': amountPaise,
        'paidByMemberId': paidByMemberId,
        'date': DateFormatter.toIso(date),
        'note': note,
        'createdAt': now,
        'updatedAt': now,
        'deletedAt': null,
      });

      for (final entry in splitMap.entries) {
        await txn.insert(DatabaseSchema.expenseSplits, {
          'id': _uuid.v4(),
          'groupExpenseId': expId,
          'memberId': entry.key,
          'amountPaise': entry.value,
          'createdAt': now,
        });
      }

      await txn.update(
        DatabaseSchema.groups,
        {'updatedAt': now},
        where: 'id = ?',
        whereArgs: [groupId],
      );
    });

    notifyListeners();
    final expenses = await getGroupExpenses(groupId);
    return expenses.firstWhere((e) => e.id == expId);
  }

  @override
  Future<void> deleteGroupExpense(String expenseId) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.update(
      DatabaseSchema.groupExpenses,
      {'deletedAt': now, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [expenseId],
    );

    notifyListeners();
  }

  @override
  Future<List<Settlement>> getSettlements(String groupId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT s.*,
             fm.name AS fromMemberName,
             tm.name AS toMemberName
      FROM ${DatabaseSchema.settlements} s
      LEFT JOIN ${DatabaseSchema.groupMembers} fm ON s.fromMemberId = fm.id
      LEFT JOIN ${DatabaseSchema.groupMembers} tm ON s.toMemberId = tm.id
      WHERE s.groupId = ?
      ORDER BY s.date DESC
    ''', [groupId]);

    return rows.map((r) => Settlement(
          id: r['id'] as String,
          groupId: groupId,
          fromMemberId: r['fromMemberId'] as String,
          fromMemberName: r['fromMemberName'] as String?,
          toMemberId: r['toMemberId'] as String,
          toMemberName: r['toMemberName'] as String?,
          amountPaise: r['amountPaise'] as int,
          date: DateFormatter.fromIso(r['date'] as String),
          note: r['note'] as String?,
          createdAt: DateFormatter.fromIso(r['createdAt'] as String),
        )).toList();
  }

  @override
  Future<Settlement> createSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    final db = await _db;
    final id = _uuid.v4();
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert(DatabaseSchema.settlements, {
      'id': id,
      'groupId': groupId,
      'fromMemberId': fromMemberId,
      'toMemberId': toMemberId,
      'amountPaise': amountPaise,
      'date': DateFormatter.toIso(date),
      'note': note,
      'createdAt': now,
    });

    notifyListeners();
    final settlements = await getSettlements(groupId);
    return settlements.firstWhere((s) => s.id == id);
  }

  @override
  Future<List<MemberDebt>> getGroupDebts(String groupId) async {
    final members = await getGroupMembers(groupId);

    // debtors: netBalance < 0 (owe money)
    // creditors: netBalance > 0 (are owed money)
    final List<({GroupMember member, int amount})> debtors = [];
    final List<({GroupMember member, int amount})> creditors = [];

    for (final m in members) {
      if (m.netBalancePaise < 0) {
        debtors.add((member: m, amount: -m.netBalancePaise));
      } else if (m.netBalancePaise > 0) {
        creditors.add((member: m, amount: m.netBalancePaise));
      }
    }

    final List<MemberDebt> debts = [];
    var dIdx = 0;
    var cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtor = debtors[dIdx];
      final creditor = creditors[cIdx];

      final settleAmount = debtor.amount < creditor.amount ? debtor.amount : creditor.amount;

      if (settleAmount > 0) {
        debts.add(MemberDebt(
          fromMemberId: debtor.member.id,
          fromMemberName: debtor.member.name,
          toMemberId: creditor.member.id,
          toMemberName: creditor.member.name,
          amountPaise: settleAmount,
        ));
      }

      final remDebtor = debtor.amount - settleAmount;
      final remCreditor = creditor.amount - settleAmount;

      if (remDebtor == 0) {
        dIdx++;
      } else {
        debtors[dIdx] = (member: debtor.member, amount: remDebtor);
      }

      if (remCreditor == 0) {
        cIdx++;
      } else {
        creditors[cIdx] = (member: creditor.member, amount: remCreditor);
      }
    }

    return debts;
  }

  @override
  Future<int> getTotalGroupBalancePaise() async {
    final groups = await getGroups();
    int total = 0;
    for (final g in groups) {
      total += g.userBalancePaise;
    }
    return total;
  }

  @override
  Stream<List<Group>> watchGroups() {
    getGroups().then((groups) {
      if (!_groupsController.isClosed) _groupsController.add(groups);
    });
    return _groupsController.stream;
  }

  @override
  Stream<Group?> watchGroup(String id) {
    return watchGroups().map((groups) {
      final match = groups.where((g) => g.id == id);
      return match.isNotEmpty ? match.first : null;
    });
  }
}
