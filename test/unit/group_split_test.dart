import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Group Split Algorithm Tests', () {
    test('Equal split with non-zero remainder allocates remainder deterministically', () {
      const totalPaise = 10000; // ₹100.00
      const memberCount = 3;

      const baseShare = totalPaise ~/ memberCount; // 3333
      const remainder = totalPaise % memberCount; // 1

      final shares = <int>[];
      for (var i = 0; i < memberCount; i++) {
        shares.add(baseShare + (i < remainder ? 1 : 0));
      }

      expect(shares, equals([3334, 3333, 3333]));
      final sum = shares.fold<int>(0, (a, b) => a + b);
      expect(sum, equals(totalPaise));
    });

    test('Equal split with 7 members and 1000 paise', () {
      const totalPaise = 1000;
      const memberCount = 7;

      const baseShare = totalPaise ~/ memberCount; // 142
      const remainder = totalPaise % memberCount; // 6

      final shares = List.generate(
        memberCount,
        (i) => baseShare + (i < remainder ? 1 : 0),
      );

      expect(shares, equals([143, 143, 143, 143, 143, 143, 142]));
      expect(shares.fold<int>(0, (a, b) => a + b), equals(1000));
    });

    test('Debt simplification logic correctly pairs debtors and creditors', () {
      // Member 1 owes 50, Member 2 owes 50, Member 3 is owed 100
      final debtors = [
        (name: 'Alice', amount: 5000),
        (name: 'Bob', amount: 5000),
      ];
      final creditors = [
        (name: 'Charlie', amount: 10000),
      ];

      final debts = <String>[];
      var dIdx = 0;
      var cIdx = 0;

      while (dIdx < debtors.length && cIdx < creditors.length) {
        final debtor = debtors[dIdx];
        final creditor = creditors[cIdx];
        final settleAmount = debtor.amount < creditor.amount ? debtor.amount : creditor.amount;

        debts.add('${debtor.name} owes ${creditor.name} $settleAmount');

        final remDebtor = debtor.amount - settleAmount;
        final remCreditor = creditor.amount - settleAmount;

        if (remDebtor == 0) {
          dIdx++;
        } else {
          debtors[dIdx] = (name: debtor.name, amount: remDebtor);
        }

        if (remCreditor == 0) {
          cIdx++;
        } else {
          creditors[cIdx] = (name: creditor.name, amount: remCreditor);
        }
      }

      expect(debts, equals([
        'Alice owes Charlie 5000',
        'Bob owes Charlie 5000',
      ]));
    });
  });
}
