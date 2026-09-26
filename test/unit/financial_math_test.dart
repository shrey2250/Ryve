import 'package:flutter_test/flutter_test.dart';
import 'package:ryve/core/utils/currency_formatter.dart';

void main() {
  group('Financial Math & Currency Formatter Tests', () {
    test('Converts rupees string to exact integer paise without floating point inaccuracy', () {
      expect(CurrencyFormatter.parseToPaise('100'), equals(10000));
      expect(CurrencyFormatter.parseToPaise('124567.50'), equals(12456750));
      expect(CurrencyFormatter.parseToPaise('0.99'), equals(99));
      expect(CurrencyFormatter.parseToPaise('0.01'), equals(1));
      expect(CurrencyFormatter.parseToPaise('₹ 1,24,567.50'), equals(12456750));
      expect(CurrencyFormatter.parseToPaise('0'), equals(0));
      expect(CurrencyFormatter.parseToPaise(''), isNull);
      expect(CurrencyFormatter.parseToPaise('-50'), equals(-5000));
    });

    test('Formats integer paise to Indian Currency format properly', () {
      expect(CurrencyFormatter.format(10000), equals('₹100'));
      expect(CurrencyFormatter.format(12456750), equals('₹1,24,567.50'));
      expect(CurrencyFormatter.format(0), equals('₹0'));
      expect(CurrencyFormatter.format(-50000), equals('-₹500'));
    });

    test('Compact format works as expected', () {
      expect(CurrencyFormatter.formatCompact(10000000), equals('₹1L'));
      expect(CurrencyFormatter.formatCompact(1000000000), equals('₹1Cr'));
      expect(CurrencyFormatter.formatCompact(50000), equals('₹500'));
    });

    test('Financial Runway and Savings Rate computations', () {
      const balancePaise = 50000000; // ₹5,00,000
      const monthlyExpensePaise = 10000000; // ₹1,00,000
      const monthlyIncomePaise = 15000000; // ₹1,50,000

      const runway = balancePaise / monthlyExpensePaise;
      expect(runway, equals(5.0));

      const savingsRate = ((monthlyIncomePaise - monthlyExpensePaise) / monthlyIncomePaise) * 100;
      expect(savingsRate, closeTo(33.33, 0.01));
    });
  });
}
