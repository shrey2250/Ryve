import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/budget_providers.dart';
import '../../core/providers/goal_providers.dart';
import '../../core/providers/recurring_bill_providers.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/recurring_bill.dart';
import '../../presentation/widgets/shared_widgets.dart';
import 'add_edit_goal_dialog.dart';
import 'add_edit_recurring_bill_dialog.dart';
import 'contribute_goal_dialog.dart';
import 'set_budget_dialog.dart';

/// Plan Screen - Monthly budget overview, savings goals, and savings calculator.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  // Calculator state
  double _calcMonthlyAmount = 10000;
  double _calcYears = 5;
  double _calcRate = 12;

  void _openSetBudget(BuildContext context, budget, String month) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SetBudgetDialog(currentBudget: budget, month: month),
    );
  }

  void _openAddGoal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddEditGoalDialog(),
    );
  }

  void _openEditGoal(BuildContext context, SavingsGoal goal) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddEditGoalDialog(goal: goal),
    );
  }

  void _openContributeGoal(BuildContext context, SavingsGoal goal) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => ContributeGoalDialog(goal: goal),
    );
  }

  void _openAddRecurringBill(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddEditRecurringBillDialog(),
    );
  }

  void _openEditRecurringBill(BuildContext context, RecurringBill bill) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddEditRecurringBillDialog(bill: bill),
    );
  }

  (Color, Color) _getGoalColors(String icon) {
    switch (icon) {
      case 'flight':
        return (AppColors.lent, AppColors.lentLight);
      case 'shield':
        return (AppColors.income, AppColors.incomeLight);
      case 'laptop':
        return (AppColors.primary, AppColors.primaryLight);
      case 'car':
        return (AppColors.warning, AppColors.warningLight);
      case 'home':
        return (AppColors.borrowed, AppColors.borrowedLight);
      case 'favorite':
        return (AppColors.expense, AppColors.expenseLight);
      default:
        return (AppColors.primary, AppColors.primaryLight);
    }
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'shield':
        return Icons.shield_outlined;
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  int _calculateFutureValuePaise() {
    final r = (_calcRate / 100.0) / 12.0;
    final n = _calcYears * 12.0;
    final p = _calcMonthlyAmount;
    if (r == 0) return ((p * n) * 100).round();
    final fv = p * ((pow(1 + r, n) - 1) / r) * (1 + r);
    return (fv * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = ref.watch(currentMonthKeyProvider);
    final budgetAsync = ref.watch(currentMonthBudgetProvider);
    final summaryAsync = ref.watch(currentMonthSummaryProvider);
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Plan', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            onPressed: () => _openAddGoal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Budget Card
            budgetAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 140),
              error: (err, _) => const SizedBox.shrink(),
              data: (budget) {
                final budgetCapPaise = budget?.amountPaise ?? 5000000;
                final expensePaise = summaryAsync.value?.expensePaise ?? 0;
                final progress = budgetCapPaise > 0 ? (expensePaise / budgetCapPaise).clamp(0.0, 1.0) : 0.0;
                final percentUsed = (progress * 100).toInt();
                final isOverBudget = expensePaise > budgetCapPaise;
                final statusColor = isOverBudget
                    ? AppColors.expense
                    : percentUsed > 80
                        ? AppColors.warning
                        : AppColors.primary;
                final statusBgColor = isOverBudget
                    ? AppColors.expenseLight
                    : percentUsed > 80
                        ? AppColors.warningLight
                        : AppColors.primaryLight;

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MONTHLY BUDGET ($monthKey)', style: AppTypography.caption),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isOverBudget ? 'Over Budget' : '$percentUsed% Used',
                                      style: AppTypography.caption.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _openSetBudget(context, budget, monthKey),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(budget == null ? '+ Set Cap' : 'Edit Cap', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Spent: ${CurrencyFormatter.format(expensePaise)}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Cap: ${CurrencyFormatter.format(budgetCapPaise)}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category Spending Breakdown
            ref.watch(categorySpendingBreakdownProvider).when(
              loading: () => const ShimmerBox(width: double.infinity, height: 120),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) {
                if (categories.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SPENDING BREAKDOWN',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${categories.length} categories',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Multi-segment horizontal distribution bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          width: double.infinity,
                          color: AppColors.surfaceElevated,
                          child: Row(
                            children: categories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final color = AppColors.categoryPalette[index % AppColors.categoryPalette.length];
                              return Expanded(
                                flex: (item.percentage * 10).round().clamp(1, 1000),
                                child: Container(
                                  color: color,
                                  margin: const EdgeInsets.only(right: 1.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Category items list
                      ...categories.take(5).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final color = AppColors.categoryPalette[index % AppColors.categoryPalette.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.categoryName,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item.percentage.toStringAsFixed(0)}%',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                CurrencyFormatter.format(item.amountPaise),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            // Savings Goals Section
            SectionHeader(
              title: 'Savings Goals',
              actionText: '+ New Goal',
              onActionTap: () => _openAddGoal(context),
            ),
            const SizedBox(height: AppSpacing.sm),

            goalsAsync.when(
              loading: () => Column(
                children: List.generate(
                  2,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ShimmerBox(width: double.infinity, height: 96),
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error loading goals: $err', style: AppTypography.bodySmall),
              ),
              data: (goals) {
                if (goals.isEmpty) {
                  return EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No savings goals',
                    subtitle: 'Create a goal to track your milestones (e.g. Emergency Fund).',
                    actionText: '+ Create Goal',
                    onActionTap: () => _openAddGoal(context),
                  );
                }

                return Column(
                  children: goals.map((goal) {
                    final progress = goal.progress;
                    final (accentColor, bgColor) = _getGoalColors(goal.icon);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: AppColors.shadowSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                child: Icon(_getIconData(goal.icon), color: accentColor, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(goal.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${CurrencyFormatter.format(goal.savedAmountPaise)} of ${CurrencyFormatter.format(goal.targetAmountPaise)}',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${(progress * 100).toInt()}%',
                                  style: AppTypography.caption.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (goal.targetDate != null)
                                Text(
                                  'Target: ${DateFormatter.formatDate(goal.targetDate!)}',
                                  style: AppTypography.caption.copyWith(color: AppColors.textDisabled),
                                )
                              else
                                const SizedBox.shrink(),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _openContributeGoal(context, goal),
                                    icon: Icon(Icons.add_rounded, size: 16, color: accentColor),
                                    label: Text('Deposit', style: AppTypography.caption.copyWith(color: accentColor, fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                                    padding: EdgeInsets.zero,
                                    onSelected: (val) async {
                                      if (val == 'edit') {
                                        _openEditGoal(context, goal);
                                      } else if (val == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: AppColors.surface,
                                            title: const Text('Delete Goal?', style: AppTypography.titleLarge),
                                            content: Text('Delete "${goal.name}"? This action cannot be undone.', style: AppTypography.bodyMedium),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: AppColors.expense))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ref.read(goalRepositoryProvider).deleteGoal(goal.id);
                                        }
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete Goal')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recurring Bills & Subscriptions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recurring Bills', style: AppTypography.titleMedium),
                    ref.watch(totalMonthlyCommittedPaiseProvider).when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (committed) => Text(
                            '${CurrencyFormatter.format(committed)}/mo committed spend',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                  ],
                ),
                TextButton(
                  onPressed: () => _openAddRecurringBill(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('+ New Bill', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            ref.watch(allRecurringBillsProvider).when(
              loading: () => const ShimmerBox(width: double.infinity, height: 80),
              error: (err, _) => Text('Error loading bills: $err', style: AppTypography.bodySmall),
              data: (bills) {
                if (bills.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No recurring bills',
                    subtitle: 'Track your subscriptions (Netflix, Spotify, Rent, Gym, WiFi).',
                    actionText: '+ Add Recurring Bill',
                    onActionTap: () => _openAddRecurringBill(context),
                  );
                }

                return Column(
                  children: bills.map((bill) {
                    final days = bill.daysUntilDue;
                    final isDueSoon = days >= 0 && days <= 3;
                    final isOverdue = days < 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: AppColors.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: const Icon(Icons.subscriptions_outlined, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        bill.name,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: bill.isActive ? AppColors.textPrimary : AppColors.textDisabled,
                                          decoration: bill.isActive ? null : TextDecoration.lineThrough,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOverdue
                                            ? AppColors.expenseLight
                                            : (isDueSoon ? AppColors.warningLight : AppColors.surfaceElevated),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isOverdue
                                            ? 'Overdue'
                                            : (days == 0 ? 'Due Today' : 'Due in ${days}d'),
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isOverdue
                                              ? AppColors.expense
                                              : (isDueSoon ? AppColors.warning : AppColors.textSecondary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${bill.cycle.value.toUpperCase()} • ${DateFormatter.formatDate(bill.nextDueDate)}',
                                      style: AppTypography.caption.copyWith(fontSize: 10.5, color: AppColors.textDisabled),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(bill.amountPaise),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: bill.isActive ? AppColors.textPrimary : AppColors.textDisabled,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                            padding: EdgeInsets.zero,
                            onSelected: (val) async {
                              if (val == 'edit') {
                                _openEditRecurringBill(context, bill);
                              } else if (val == 'toggle') {
                                await ref.read(recurringBillRepositoryProvider).toggleActive(bill.id, !bill.isActive);
                              } else if (val == 'delete') {
                                await ref.read(recurringBillRepositoryProvider).deleteRecurringBill(bill.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(bill.isActive ? 'Pause Subscription' : 'Resume Subscription'),
                              ),
                              const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.expense))),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),


            // Interactive Savings Growth Projection Calculator
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: AppColors.textPrimary, size: 22),
                      SizedBox(width: AppSpacing.sm),
                      Text('Wealth Compound Calculator', style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Sliders wrapped in custom tactile SliderTheme
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 2),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primaryLight,
                      thumbColor: AppColors.primary,
                    ),
                    child: Column(
                      children: [
                        // Monthly Investment Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monthly Savings', style: AppTypography.caption),
                            Text(
                              CurrencyFormatter.format((_calcMonthlyAmount * 100).round()),
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: _calcMonthlyAmount,
                          min: 1000,
                          max: 100000,
                          divisions: 99,
                          onChanged: (val) {
                            if (val != _calcMonthlyAmount) HapticFeedback.selectionClick();
                            setState(() => _calcMonthlyAmount = val);
                          },
                        ),

                        // Time Horizon Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Duration', style: AppTypography.caption),
                            Text('${_calcYears.toInt()} Years', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        Slider(
                          value: _calcYears,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          onChanged: (val) {
                            if (val != _calcYears) HapticFeedback.selectionClick();
                            setState(() => _calcYears = val);
                          },
                        ),

                        // Return Rate Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expected Annual Return', style: AppTypography.caption),
                            Text('${_calcRate.toInt()}% p.a.', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        Slider(
                          value: _calcRate,
                          min: 4,
                          max: 20,
                          divisions: 16,
                          onChanged: (val) {
                            if (val != _calcRate) HapticFeedback.selectionClick();
                            setState(() => _calcRate = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: AppSpacing.md),

                  // Projected Corpus Display (Primary Indigo — not Realized Inflow Emerald)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROJECTED WEALTH', style: AppTypography.caption),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(_calculateFutureValuePaise()),
                            style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('TOTAL INVESTED', style: AppTypography.caption),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format((_calcMonthlyAmount * _calcYears * 12 * 100).round()),
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),

                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
