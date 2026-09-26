import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/iou.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/iou_repository.dart';

class IouRepositoryImpl implements IouRepository {
  IouRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();
  final _summaryController = StreamController<IouSummary>.broadcast();
  final _iousController = StreamController<List<IouRecord>>.broadcast();

  Future<Database> get _db => _dbHelper.database;

  @override
  void notifyListeners() {
    getIouSummary().then((sum) {
      if (!_summaryController.isClosed) _summaryController.add(sum);
    });
    getIouRecords().then((ious) {
      if (!_iousController.isClosed) _iousController.add(ious);
    });
  }

  @override
  Future<List<Person>> getPeople() async {
    final db = await _db;
    final rows = await db.query(DatabaseSchema.people, orderBy: 'name ASC');

    final List<Person> people = [];
    for (final r in rows) {
      final personId = r['id'] as String;

      // Lent to this person
      final lentRows = await db.rawQuery('''
        SELECT r.originalAmountPaise, COALESCE(SUM(rep.amountPaise), 0) AS repaid
        FROM ${DatabaseSchema.iouRecords} r
        LEFT JOIN ${DatabaseSchema.iouRepayments} rep ON r.id = rep.iouId
        WHERE r.personId = ? AND r.type = 'lent' AND r.deletedAt IS NULL
        GROUP BY r.id
      ''', [personId]);

      int totalLent = 0;
      for (final lr in lentRows) {
        final orig = lr['originalAmountPaise'] as int;
        final repaid = lr['repaid'] as int;
        totalLent += (orig - repaid).clamp(0, orig);
      }

      // Borrowed from this person
      final borrowedRows = await db.rawQuery('''
        SELECT r.originalAmountPaise, COALESCE(SUM(rep.amountPaise), 0) AS repaid
        FROM ${DatabaseSchema.iouRecords} r
        LEFT JOIN ${DatabaseSchema.iouRepayments} rep ON r.id = rep.iouId
        WHERE r.personId = ? AND r.type = 'borrowed' AND r.deletedAt IS NULL
        GROUP BY r.id
      ''', [personId]);

      int totalBorrowed = 0;
      for (final br in borrowedRows) {
        final orig = br['originalAmountPaise'] as int;
        final repaid = br['repaid'] as int;
        totalBorrowed += (orig - repaid).clamp(0, orig);
      }

      people.add(Person(
        id: personId,
        name: r['name'] as String,
        avatarInitials: r['avatarInitials'] as String?,
        createdAt: DateFormatter.fromIso(r['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(r['updatedAt'] as String),
        totalLentPaise: totalLent,
        totalBorrowedPaise: totalBorrowed,
        netBalancePaise: totalLent - totalBorrowed,
      ));
    }

    return people;
  }

  @override
  Future<Person?> getPersonById(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseSchema.people,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final people = await getPeople();
    final match = people.where((p) => p.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<Person> createPerson(String name) async {
    final db = await _db;
    final id = _uuid.v4();
    final now = DateFormatter.toIso(DateTime.now());

    final cleanName = name.trim();
    String initials = '?';
    final parts = cleanName.split(RegExp(r'\s+'));
    if (parts.length == 1 && cleanName.isNotEmpty) {
      initials = cleanName.substring(0, 1).toUpperCase();
    } else if (parts.length > 1) {
      initials = (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
    }

    await db.insert(DatabaseSchema.people, {
      'id': id,
      'name': cleanName,
      'avatarInitials': initials,
      'createdAt': now,
      'updatedAt': now,
    });

    notifyListeners();
    return Person(
      id: id,
      name: cleanName,
      avatarInitials: initials,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<IouRecord>> getIouRecords({IouType? type, IouStatus? status, String? personId}) async {
    final db = await _db;

    final conditions = ['r.deletedAt IS NULL'];
    final args = <dynamic>[];

    if (type != null) {
      conditions.add('r.type = ?');
      args.add(type.value);
    }
    if (status != null) {
      conditions.add('r.status = ?');
      args.add(status.value);
    }
    if (personId != null) {
      conditions.add('r.personId = ?');
      args.add(personId);
    }

    final where = conditions.join(' AND ');

    final rows = await db.rawQuery('''
      SELECT r.*, p.name AS personName
      FROM ${DatabaseSchema.iouRecords} r
      LEFT JOIN ${DatabaseSchema.people} p ON r.personId = p.id
      WHERE $where
      ORDER BY r.createdAt DESC
    ''', args);

    final List<IouRecord> result = [];
    for (final r in rows) {
      final iouId = r['id'] as String;
      final repayments = await _getRepaymentsForIou(db, iouId);

      int paidAmount = 0;
      for (final rep in repayments) {
        paidAmount += rep.amountPaise;
      }

      result.add(IouRecord(
        id: iouId,
        personId: r['personId'] as String,
        personName: r['personName'] as String?,
        type: IouType.fromValue(r['type'] as String),
        originalAmountPaise: r['originalAmountPaise'] as int,
        paidAmountPaise: paidAmount,
        dueDate: r['dueDate'] != null ? DateFormatter.fromIso(r['dueDate'] as String) : null,
        note: r['note'] as String?,
        status: IouStatus.fromValue(r['status'] as String),
        createdAt: DateFormatter.fromIso(r['createdAt'] as String),
        updatedAt: DateFormatter.fromIso(r['updatedAt'] as String),
        deletedAt: r['deletedAt'] != null ? DateFormatter.fromIso(r['deletedAt'] as String) : null,
        repayments: repayments,
      ));
    }

    return result;
  }

  Future<List<IouRepayment>> _getRepaymentsForIou(Database db, String iouId) async {
    final rows = await db.query(
      DatabaseSchema.iouRepayments,
      where: 'iouId = ?',
      whereArgs: [iouId],
      orderBy: 'date DESC, createdAt DESC',
    );
    return rows.map((r) => IouRepayment(
          id: r['id'] as String,
          iouId: r['iouId'] as String,
          amountPaise: r['amountPaise'] as int,
          date: DateFormatter.fromIso(r['date'] as String),
          note: r['note'] as String?,
          createdAt: DateFormatter.fromIso(r['createdAt'] as String),
        )).toList();
  }

  @override
  Future<IouRecord?> getIouById(String id) async {
    final records = await getIouRecords();
    final match = records.where((r) => r.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<IouRecord> createIou(IouRecord iou) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert(DatabaseSchema.iouRecords, {
      'id': iou.id,
      'personId': iou.personId,
      'type': iou.type.value,
      'originalAmountPaise': iou.originalAmountPaise,
      'dueDate': iou.dueDate != null ? DateFormatter.toIso(iou.dueDate!) : null,
      'note': iou.note,
      'status': iou.status.value,
      'createdAt': now,
      'updatedAt': now,
      'deletedAt': null,
    });

    notifyListeners();
    return iou;
  }

  @override
  Future<void> updateIou(IouRecord iou) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.update(
      DatabaseSchema.iouRecords,
      {
        'personId': iou.personId,
        'type': iou.type.value,
        'originalAmountPaise': iou.originalAmountPaise,
        'dueDate': iou.dueDate != null ? DateFormatter.toIso(iou.dueDate!) : null,
        'note': iou.note,
        'status': iou.status.value,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [iou.id],
    );

    notifyListeners();
  }

  @override
  Future<void> deleteIou(String id) async {
    final db = await _db;
    final now = DateFormatter.toIso(DateTime.now());

    await db.update(
      DatabaseSchema.iouRecords,
      {'deletedAt': now, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [id],
    );

    notifyListeners();
  }

  @override
  Future<IouRepayment> addRepayment({
    required String iouId,
    required int amountPaise,
    required DateTime date,
    String? note,
  }) async {
    final db = await _db;
    final repId = _uuid.v4();
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert(DatabaseSchema.iouRepayments, {
        'id': repId,
        'iouId': iouId,
        'amountPaise': amountPaise,
        'date': DateFormatter.toIso(date),
        'note': note,
        'createdAt': now,
      });

      // Check if settled
      final iouRows = await txn.query(
        DatabaseSchema.iouRecords,
        where: 'id = ?',
        whereArgs: [iouId],
      );
      if (iouRows.isNotEmpty) {
        final orig = iouRows.first['originalAmountPaise'] as int;
        final repRows = await txn.rawQuery('''
          SELECT COALESCE(SUM(amountPaise), 0) AS total
          FROM ${DatabaseSchema.iouRepayments}
          WHERE iouId = ?
        ''', [iouId]);
        final totalRepaid = (repRows.first['total'] as int?) ?? 0;

        if (totalRepaid >= orig) {
          await txn.update(
            DatabaseSchema.iouRecords,
            {'status': 'settled', 'updatedAt': now},
            where: 'id = ?',
            whereArgs: [iouId],
          );
        }
      }
    });

    notifyListeners();
    return IouRepayment(
      id: repId,
      iouId: iouId,
      amountPaise: amountPaise,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<IouSummary> getIouSummary() async {
    final activeRecords = await getIouRecords(status: IouStatus.active);

    int totalLent = 0;
    int totalBorrowed = 0;

    for (final r in activeRecords) {
      if (r.type == IouType.lent) {
        totalLent += r.remainingAmountPaise;
      } else {
        totalBorrowed += r.remainingAmountPaise;
      }
    }

    return IouSummary(
      totalLentPaise: totalLent,
      totalBorrowedPaise: totalBorrowed,
    );
  }

  @override
  Stream<IouSummary> watchIouSummary() {
    getIouSummary().then((sum) {
      if (!_summaryController.isClosed) _summaryController.add(sum);
    });
    return _summaryController.stream;
  }

  @override
  Stream<List<IouRecord>> watchIous({IouType? type}) {
    getIouRecords(type: type).then((ious) {
      if (!_iousController.isClosed) _iousController.add(ious);
    });
    return _iousController.stream;
  }
}
