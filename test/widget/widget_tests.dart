import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryve/core/theme/app_theme.dart';
import 'package:ryve/domain/entities/account.dart';
import 'package:ryve/features/settings/pin_setup_dialog.dart';
import 'package:ryve/presentation/widgets/account_card.dart';
import 'package:ryve/presentation/widgets/shared_widgets.dart';


void main() {
  group('UI & Widget Smoke Tests', () {
    testWidgets('AmountDisplay renders formatted currency with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AmountDisplay(
              amountPaise: 4500000,
              label: 'Total Balance',
            ),
          ),
        ),
      );

      expect(find.text('TOTAL BALANCE'), findsOneWidget);
      expect(find.text('₹45,000'), findsOneWidget);
    });

    testWidgets('SummaryRow renders Inflow, Outflow, and Saved amounts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SummaryRow(
              incomePaise: 8000000,
              expensePaise: 3500000,
              netSavingsPaise: 4500000,
            ),
          ),
        ),
      );

      expect(find.text('Inflow'), findsOneWidget);
      expect(find.text('Outflow'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('AccountCard renders account name, type, and balance', (tester) async {
      final account = Account(
        id: 'acc-test',
        name: 'Main Bank',
        type: AccountType.bank,
        balancePaise: 1250000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AccountCard(account: account),
          ),
        ),
      );

      expect(find.text('Main Bank'), findsOneWidget);
      expect(find.text('BANK'), findsOneWidget);
      expect(find.text('₹12,500'), findsOneWidget);
    });

    testWidgets('PinSetupDialog renders keypad and header', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: PinSetupDialog(),
            ),
          ),
        ),
      );

      expect(find.text('Set Up App Lock PIN'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('⌫'), findsOneWidget);
    });

  });
}

