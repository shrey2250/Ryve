import 'package:flutter_test/flutter_test.dart';
import 'package:ryve/core/utils/smart_transaction_parser.dart';
import 'package:ryve/domain/entities/transaction.dart';

void main() {
  group('SmartTransactionParser Natural Language Unit Tests', () {
    test('Parses amount, merchant, category, and clean description from natural text', () {
      final res = SmartTransactionParser.parse('Dinner 450 at Swiggy');
      expect(res.amountPaise, equals(45000));
      expect(res.merchant, equals('Swiggy'));
      expect(res.categoryId, equals('cat_food'));
      expect(res.type, equals(TransactionType.expense));
    });

    test('Parses transportation with Uber', () {
      final res = SmartTransactionParser.parse('Uber to airport ₹680');
      expect(res.amountPaise, equals(68000));
      expect(res.merchant, equals('Uber'));
      expect(res.categoryId, equals('cat_transport'));
    });

    test('Parses salary income type accurately', () {
      final res = SmartTransactionParser.parse('Monthly Salary from Google 125000');
      expect(res.amountPaise, equals(12500000));
      expect(res.categoryId, equals('cat_salary'));
      expect(res.type, equals(TransactionType.income));
    });

    test('Handles grocery platforms', () {
      final res = SmartTransactionParser.parse('Groceries 1450 via Blinkit');
      expect(res.amountPaise, equals(145000));
      expect(res.merchant, equals('Blinkit'));
      expect(res.categoryId, equals('cat_groceries'));
    });

    test('Handles blank and empty inputs gracefully', () {
      final res = SmartTransactionParser.parse('   ');
      expect(res.amountPaise, isNull);
      expect(res.categoryId, isNull);
    });
  });
}
