import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/group_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/group.dart';
import '../../presentation/widgets/shared_widgets.dart';
import 'add_group_expense_dialog.dart';
import 'settle_debt_dialog.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddExpense(Group currentGroup) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddGroupExpenseDialog(group: currentGroup),
    ).then((_) {
      ref.invalidate(groupExpensesProvider(widget.group.id));
      ref.invalidate(groupDebtsProvider(widget.group.id));
      ref.invalidate(groupsProvider);
    });
  }

  void _openSettleDebt(Group currentGroup, [MemberDebt? debt]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SettleDebtDialog(group: currentGroup, defaultDebt: debt),
    ).then((_) {
      ref.invalidate(groupExpensesProvider(widget.group.id));
      ref.invalidate(groupDebtsProvider(widget.group.id));
      ref.invalidate(groupSettlementsProvider(widget.group.id));
      ref.invalidate(groupsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final group = groupsAsync.value?.firstWhere(
          (g) => g.id == widget.group.id,
          orElse: () => widget.group,
        ) ??
        widget.group;

    final expensesAsync = ref.watch(groupExpensesProvider(group.id));
    final debtsAsync = ref.watch(groupDebtsProvider(group.id));
    final settlementsAsync = ref.watch(groupSettlementsProvider(group.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(group.name, style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Group?', style: AppTypography.titleLarge),
                  content: Text('Are you sure you want to delete "${group.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(groupRepositoryProvider).deleteGroup(group.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textDisabled,
          indicatorColor: AppColors.textPrimary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Settlements'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Group Summary Header
          Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('TOTAL EXPENSES', style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(group.totalExpensePaise),
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(width: 1, height: 32, color: AppColors.borderSubtle),
                Column(
                  children: [
                    const Text('YOUR BALANCE', style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(
                      group.userBalancePaise > 0
                          ? '+${CurrencyFormatter.format(group.userBalancePaise)}'
                          : CurrencyFormatter.format(group.userBalancePaise),
                      style: AppTypography.titleMedium.copyWith(
                        color: group.userBalancePaise > 0
                            ? AppColors.income
                            : group.userBalancePaise < 0
                                ? AppColors.expense
                                : AppColors.textDisabled,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Expenses Tab
                expensesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No group expenses',
                        subtitle: 'Log an expense to split costs automatically among members.',
                        actionText: '+ Add Expense',
                        onActionTap: () => _openAddExpense(group),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final exp = expenses[index];
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: const Icon(Icons.receipt_rounded, size: 20, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(exp.description, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Paid by ${exp.paidByMemberName ?? "Unknown"} • ${DateFormatter.formatDate(exp.date)}',
                                      style: AppTypography.caption.copyWith(color: AppColors.textDisabled),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(exp.amountPaise),
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // 2. Balances & Who Owes Who Tab
                debtsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (debts) {
                    if (debts.isEmpty) {
                      return const EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'All Settled Up!',
                        subtitle: 'No one owes anyone in this group right now.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: debts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final debt = debts[index];
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(debt.fromMemberName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                        Text(' owes ', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                        Text(debt.toMemberName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.format(debt.amountPaise),
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.expense, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _openSettleDebt(group, debt),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textPrimary,
                                  foregroundColor: AppColors.surface,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  elevation: 0,
                                ),
                                child: Text('Settle', style: AppTypography.bodySmall.copyWith(color: AppColors.surface, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // 3. Settlements Tab
                settlementsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (settlements) {
                    if (settlements.isEmpty) {
                      return const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No settlements yet',
                        subtitle: 'Settlements recorded between members will appear here.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: settlements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final s = settlements[index];
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.income.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: const Icon(Icons.check_rounded, size: 20, color: AppColors.income),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${s.fromMemberName ?? "Member"} paid ${s.toMemberName ?? "Member"}',
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(DateFormatter.formatDate(s.date), style: AppTypography.caption.copyWith(color: AppColors.textDisabled)),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(s.amountPaise),
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.income, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSettleDebt(group),
                  icon: const Icon(Icons.handshake_outlined, size: 18),
                  label: const Text('Settle Up'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAddExpense(group),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
