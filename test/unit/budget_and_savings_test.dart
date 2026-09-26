import 'package:flutter_test/flutter_test.dart';
import 'package:ryve/domain/entities/goal.dart';

void main() {
  group('Budget and Savings Goal Tests', () {
    test('Savings Goal progress percentage and remaining amount in integer paise', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'Emergency Fund',
        targetAmountPaise: 10000000, // ₹1,00,000
        savedAmountPaise: 7500000, // ₹75,000
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.progress, equals(0.75));
      expect(goal.remainingAmountPaise, equals(2500000)); // ₹25,000
      expect(goal.targetAmount, equals(100000.0));
      expect(goal.savedAmount, equals(75000.0));
    });

    test('Savings Goal handles over-achievement correctly without exceeding 1.0 progress clamp', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'goal-2',
        name: 'New Phone',
        targetAmountPaise: 5000000,
        savedAmountPaise: 6000000,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.progress, equals(1.0));
      expect(goal.remainingAmountPaise, equals(0));
    });
  });
}
