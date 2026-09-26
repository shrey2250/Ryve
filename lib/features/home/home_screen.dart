import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/iou_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/update_service.dart';
import '../../presentation/widgets/account_card.dart';
import '../../presentation/widgets/shared_widgets.dart';
import '../../presentation/widgets/transaction_widgets.dart';
import '../../presentation/widgets/update_dialog.dart';

/// Home Screen - Primary visual anchor with net balance, monthly overview, accounts, IOU summary, and recent activity.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final updateService = ref.read(updateServiceProvider.notifier);
      final hasUpdate = await updateService.checkForUpdates();
      if (hasUpdate && mounted) {
        showUpdateDialog(context, ref: ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    final monthlySummaryAsync = ref.watch(currentMonthSummaryProvider);
    final iouSummaryAsync = ref.watch(iouSummaryProvider);
    final isPrivacyActive = ref.watch(privacyModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RYVE', style: AppTypography.titleMedium.copyWith(letterSpacing: 2.5)),
            Text('Silent Wealth Architecture', style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isPrivacyActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: isPrivacyActive ? AppColors.primary : AppColors.textPrimary,
              size: 22,
            ),
            tooltip: isPrivacyActive ? 'Show Balances' : 'Mask Balances (Privacy Shield)',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(privacyModeProvider.notifier).state = !isPrivacyActive;
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/accounts');
            },
          ),
          IconButton(
            icon: const Icon(Icons.handshake_outlined, color: AppColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/iou');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsProvider);
          ref.invalidate(allTransactionsProvider);
          ref.invalidate(iouSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Hero Visual Anchor: Net Total Balance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: AppColors.shadowSm,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'TOTAL NET BALANCE',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    totalBalanceAsync.when(
                      loading: () => const ShimmerBox(width: 180, height: 44),
                      error: (err, _) => Text(CurrencyFormatter.format(0), style: AppTypography.hero),
                      data: (balance) => AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        style: AppTypography.hero.copyWith(
                          fontSize: 38,
                          color: balance < 0 ? AppColors.expense : AppColors.textPrimary,
                          letterSpacing: isPrivacyActive ? 3.0 : -1.2,
                        ),
                        child: Text(
                          CurrencyFormatter.formatWithPrivacy(balance, isPrivate: isPrivacyActive),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(height: 1, color: AppColors.borderSubtle.withValues(alpha: 0.6)),
                    const SizedBox(height: AppSpacing.sm),
                    ref.watch(financialHealthProvider).when(
                      loading: () => const SizedBox(height: 24),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (metrics) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                'RUNWAY',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                metrics.runwayMonths != null
                                    ? '${metrics.runwayMonths!.toStringAsFixed(1)} mo'
                                    : '—',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: metrics.runwayMonths != null && metrics.runwayMonths! < 1.0
                                      ? AppColors.warning
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 22, color: AppColors.borderSubtle),
                          Column(
                            children: [
                              Text(
                                'SAVINGS RATE',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${metrics.savingsRatePercent.toStringAsFixed(0)}%',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: metrics.savingsRatePercent >= 20
                                      ? AppColors.income
                                      : (metrics.savingsRatePercent < 0
                                          ? AppColors.expense
                                          : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Monthly Summary Row (Inflow / Outflow / Saved)
              monthlySummaryAsync.when(
                loading: () => const ShimmerBox(width: double.infinity, height: 60),
                error: (err, _) => const SizedBox.shrink(),
                data: (summary) => SummaryRow(
                  incomePaise: summary.incomePaise,
                  expensePaise: summary.expensePaise,
                  netSavingsPaise: summary.savedPaise,
                  isPrivate: isPrivacyActive,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Lending & Borrowing Quick Preview Cards (IOU)
              iouSummaryAsync.when(
                loading: () => const ShimmerBox(width: double.infinity, height: 64),
                error: (_, __) => const SizedBox.shrink(),
                data: (iouSummary) {
                  if (iouSummary.totalLentPaise == 0 && iouSummary.totalBorrowedPaise == 0) {
                    return const SizedBox.shrink();
                  }

                  return Row(
                    children: [
                      // Lent (Owed to you)
                      Expanded(
                        child: ApplePressable(
                          onTap: () => context.push('/iou'),
                          pressedScale: 0.96,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.income.withValues(alpha: 0.25)),
                              boxShadow: AppColors.shadowSm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppColors.incomeLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_outward_rounded, size: 10, color: AppColors.income),
                                    ),
                                    const SizedBox(width: 6),
                                    Text("YOU'RE OWED", style: AppTypography.caption.copyWith(fontSize: 9.5, color: AppColors.income, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  CurrencyFormatter.format(iouSummary.totalLentPaise),
                                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.income, letterSpacing: -0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Borrowed (You owe)
                      Expanded(
                        child: ApplePressable(
                          onTap: () => context.push('/iou'),
                          pressedScale: 0.96,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.expense.withValues(alpha: 0.25)),
                              boxShadow: AppColors.shadowSm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppColors.expenseLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.call_received_rounded, size: 10, color: AppColors.expense),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('YOU OWE', style: AppTypography.caption.copyWith(fontSize: 9.5, color: AppColors.expense, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  CurrencyFormatter.format(iouSummary.totalBorrowedPaise),
                                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.expense, letterSpacing: -0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),


              // Accounts Section
              SectionHeader(
                title: 'Accounts',
                actionText: 'See All',
                onActionTap: () => context.push('/accounts'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 116,
                child: accountsAsync.when(
                  loading: () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, __) => const ShimmerBox(width: 140, height: 116),
                  ),
                  error: (err, _) => const Center(
                    child: Text('Error loading accounts', style: AppTypography.bodySmall),
                  ),
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return const Center(
                        child: Text('No accounts created', style: AppTypography.bodySmall),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final acc = accounts[index];
                        return AccountCard(
                          account: acc,
                          onTap: () => context.push('/account-detail', extra: acc),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recent Transactions Section
              SectionHeader(
                title: 'Recent Activity',
                actionText: 'View All',
                onActionTap: () => context.go('/transactions'),
              ),
              const SizedBox(height: AppSpacing.sm),

              recentTransactionsAsync.when(
                loading: () => Column(
                  children: List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ShimmerBox(width: double.infinity, height: 56),
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading activity: $err', style: AppTypography.bodySmall),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No recent transactions',
                      subtitle: 'Tap Quick Action + below to record your first transaction.',
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return TransactionRow(
                          transaction: tx,
                          onTap: () => context.push('/transaction-detail', extra: tx),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
