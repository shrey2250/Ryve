import 'package:flutter_test/flutter_test.dart';
import 'package:ryve/domain/entities/iou.dart';

void main() {
  group('IOU Domain Entity Tests', () {
    test('Calculates remaining amount correctly after repayments', () {
      final now = DateTime.now();
      final iou = IouRecord(
        id: 'iou-1',
        personId: 'p-1',
        personName: 'Rahul',
        type: IouType.lent,
        originalAmountPaise: 1000000, // ₹10,000
        paidAmountPaise: 400000, // ₹4,000 repaid
        createdAt: now,
        updatedAt: now,
      );

      expect(iou.remainingAmountPaise, equals(600000)); // ₹6,000 remaining
      expect(iou.originalAmount, equals(10000.0));
      expect(iou.remainingAmount, equals(6000.0));
    });

    test('Clamps remaining amount at zero if repayments meet or exceed original', () {
      final now = DateTime.now();
      final iou = IouRecord(
        id: 'iou-2',
        personId: 'p-2',
        personName: 'Priya',
        type: IouType.borrowed,
        originalAmountPaise: 500000,
        paidAmountPaise: 500000,
        createdAt: now,
        updatedAt: now,
      );

      expect(iou.remainingAmountPaise, equals(0));
    });

    test('IouSummary net balance computation', () {
      const summary = IouSummary(
        totalLentPaise: 1500000, // ₹15,000 (asset)
        totalBorrowedPaise: 500000, // ₹5,000 (liability)
      );

      expect(summary.netBalancePaise, equals(1000000)); // +₹10,000 net surplus
    });
  });
}
