import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import '../utils/date_formatter.dart';
import '../../domain/repositories/transaction_repository.dart';

class CsvExportService {
  static Future<void> generateAndShareCsv(TransactionRepository repository) async {
    final transactions = await repository.getTransactions(limit: 10000);

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Date,Time,Type,Amount (INR),Category,Account,Merchant / Source,Description,Note');

    for (final tx in transactions) {
      final date = DateFormatter.formatDate(tx.date);
      final time = DateFormatter.formatTime(tx.date);
      final type = tx.type.name.toUpperCase();
      final amount = (tx.amountPaise / 100.0).toStringAsFixed(2);
      final category = _cleanCsv(tx.categoryName ?? '');
      final account = _cleanCsv(tx.accountName ?? '');
      final merchant = _cleanCsv(tx.merchantName ?? '');
      final desc = _cleanCsv(tx.description);
      final note = _cleanCsv(tx.note ?? '');

      buffer.writeln('${tx.id},$date,$time,$type,$amount,$category,$account,$merchant,$desc,$note');
    }

    final bytes = utf8.encode(buffer.toString());
    final fileName = 'RYVE_Statement_${DateTime.now().millisecondsSinceEpoch}.csv';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: fileName,
        ),
      ],
      text: 'RYVE Personal Finance Statement - Exported on ${DateFormatter.formatFullDate(DateTime.now())}',
    );
  }

  static String _cleanCsv(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}

