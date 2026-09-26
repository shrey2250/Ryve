import 'package:flutter_test/flutter_test.dart';
import 'package:ryve/domain/entities/recurring_bill.dart';

void main() {
  group('RecurringBill Domain Entity Tests', () {
    test('Calculates monthly normalized paise correctly for different billing cycles', () {
      final monthly = RecurringBill(
        id: '1',
        name: 'Netflix',
        amountPaise: 64900, // ₹649
        cycle: BillingCycle.monthly,
        nextDueDate: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(monthly.monthlyNormalizedPaise, equals(64900));

      final yearly = RecurringBill(
        id: '2',
        name: 'Amazon Prime',
        amountPaise: 149900, // ₹1,499/year
        cycle: BillingCycle.yearly,
        nextDueDate: DateTime.now().add(const Duration(days: 60)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(yearly.monthlyNormalizedPaise, equals((149900 / 12.0).round()));

      final weekly = RecurringBill(
        id: '3',
        name: 'Weekly Milk',
        amountPaise: 50000, // ₹500/week
        cycle: BillingCycle.weekly,
        nextDueDate: DateTime.now().add(const Duration(days: 4)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(weekly.monthlyNormalizedPaise, equals(((50000 * 52) / 12.0).round()));
    });

    test('Calculates days until due date accurately', () {
      final now = DateTime.now();
      final bill = RecurringBill(
        id: '4',
        name: 'Rent',
        amountPaise: 1500000,
        cycle: BillingCycle.monthly,
        nextDueDate: DateTime(now.year, now.month, now.day).add(const Duration(days: 5)),
        createdAt: now,
        updatedAt: now,
      );
      expect(bill.daysUntilDue, equals(5));
    });

    test('BillingCycle fromValue fallback works safely', () {
      expect(BillingCycle.fromValue('monthly'), equals(BillingCycle.monthly));
      expect(BillingCycle.fromValue('yearly'), equals(BillingCycle.yearly));
      expect(BillingCycle.fromValue('weekly'), equals(BillingCycle.weekly));
      expect(BillingCycle.fromValue('invalid'), equals(BillingCycle.monthly));
    });
  });
}
