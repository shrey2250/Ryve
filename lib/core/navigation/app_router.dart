import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/iou.dart';
import '../../domain/entities/transaction.dart';
import '../../features/accounts/account_detail_screen.dart';
import '../../features/accounts/accounts_screen.dart';
import '../../features/groups/group_detail_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/iou/iou_detail_screen.dart';
import '../../features/iou/iou_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/plan/plan_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transactions/add_expense_screen.dart';
import '../../features/transactions/add_income_screen.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import 'main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Provider for GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) => appRouter);

/// AppRouter setup with 5 primary destinations and specialized deep dive routes.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 2: Transactions
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
          ],
        ),
        // Tab 3: Groups
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/groups',
              builder: (context, state) => const GroupsScreen(),
            ),
          ],
        ),
        // Tab 4: Plan
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/plan',
              builder: (context, state) => const PlanScreen(),
            ),
          ],
        ),
        // Tab 5: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Onboarding
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Accounts
    GoRoute(
      path: '/accounts',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccountsScreen(),
    ),
    GoRoute(
      path: '/account-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final account = state.extra as Account;
        return AccountDetailScreen(account: account);
      },
    ),

    // Lending & Borrowing (IOUs)
    GoRoute(
      path: '/iou',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IouScreen(),
    ),
    GoRoute(
      path: '/iou-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final record = state.extra as IouRecord;
        return IouDetailScreen(iou: record);
      },
    ),

    // Group Detail
    GoRoute(
      path: '/group-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final group = state.extra as Group;
        return GroupDetailScreen(group: group);
      },
    ),

    // Modal / Slide routes
    GoRoute(
      path: '/add-expense',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddExpenseScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/add-income',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddIncomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/transaction-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final transaction = state.extra as Transaction;
        return TransactionDetailScreen(transaction: transaction);
      },
    ),
  ],
);
