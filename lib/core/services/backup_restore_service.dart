import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../database/schema.dart';
import '../utils/date_formatter.dart';

class BackupRestoreService {
  static Future<void> createAndShareBackup(DatabaseHelper dbHelper) async {
    final db = await dbHelper.database;
    final Map<String, dynamic> backupData = {
      'app': 'RYVE',
      'version': DatabaseSchema.version,
      'exportedAt': DateFormatter.toIso(DateTime.now()),
      'tables': <String, dynamic>{},
    };

    final tables = [
      DatabaseSchema.categories,
      DatabaseSchema.accounts,
      DatabaseSchema.transactions,
      DatabaseSchema.transfers,
      DatabaseSchema.budgets,
      DatabaseSchema.goals,
      DatabaseSchema.people,
      DatabaseSchema.iouRecords,
      DatabaseSchema.iouRepayments,
      DatabaseSchema.groups,
      DatabaseSchema.groupMembers,
      DatabaseSchema.groupExpenses,
      DatabaseSchema.expenseSplits,
      DatabaseSchema.settlements,
      DatabaseSchema.settings,
      DatabaseSchema.recurringBills,
    ];

    final tablesMap = <String, dynamic>{};
    for (final table in tables) {
      final rows = await db.query(table);
      tablesMap[table] = rows;
    }
    backupData['tables'] = tablesMap;

    final jsonStr = jsonEncode(backupData);
    final bytes = utf8.encode(jsonStr);
    final fileName = 'RYVE_Backup_${DateTime.now().millisecondsSinceEpoch}.ryve.json';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/json',
          name: fileName,
        ),
      ],
      text: 'RYVE Local Backup (${DateFormatter.formatDate(DateTime.now())})',
    );
  }

  static Future<bool> restoreBackup(DatabaseHelper dbHelper) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'ryve'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return false;
    }

    final file = result.files.single;
    String content;
    if (file.bytes != null) {
      content = utf8.decode(file.bytes!);
    } else {
      return false;
    }

    final Map<String, dynamic> data = jsonDecode(content);

    if (data['app'] != 'RYVE' || !data.containsKey('tables')) {
      throw const FormatException('Invalid RYVE backup file.');
    }

    final db = await dbHelper.database;
    final tablesMap = data['tables'] as Map<String, dynamic>;

    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');

      // Clear all tables first
      for (final table in tablesMap.keys) {
        await txn.delete(table);
      }

      // Insert all rows from backup
      for (final entry in tablesMap.entries) {
        final table = entry.key;
        final rows = (entry.value as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert(table, row);
        }
      }

      await txn.execute('PRAGMA foreign_keys = ON');
    });

    return true;
  }
}

