import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/group_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../presentation/widgets/shared_widgets.dart';
import 'create_group_dialog.dart';

/// Groups Screen - Group expenses, balances, and settlements.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  void _openCreateGroup(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const CreateGroupDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final totalGroupBalanceAsync = ref.watch(totalGroupBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Groups & Split', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: AppColors.textPrimary),
            onPressed: () => _openCreateGroup(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Balance Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.lentLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: AppColors.lent, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GROUP NET BALANCE', style: AppTypography.caption),
                        const SizedBox(height: 2),
                        totalGroupBalanceAsync.when(
                          loading: () => const ShimmerBox(width: 120, height: 24),
                          error: (_, __) => Text(CurrencyFormatter.format(0), style: AppTypography.titleLarge),
                          data: (net) {
                            final isPositive = net > 0;
                            final isNegative = net < 0;
                            final color = isPositive
                                ? AppColors.income
                                : isNegative
                                    ? AppColors.expense
                                    : AppColors.textPrimary;
                            final prefix = isPositive ? '+' : '';

                            return Text(
                              '$prefix${CurrencyFormatter.format(net)}',
                              style: AppTypography.titleLarge.copyWith(color: color, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                            );
                          },
                        ),
                        Text(
                          'Net balance across all your active split groups',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SectionHeader(
              title: 'Your Groups',
              actionText: '+ New Group',
              onActionTap: () => _openCreateGroup(context),
            ),
            const SizedBox(height: AppSpacing.md),

            groupsAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ShimmerBox(width: double.infinity, height: 72),
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error loading groups: $err', style: AppTypography.bodySmall),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No groups yet',
                    subtitle: 'Create a group for trips, rent, or dinner splits with friends.',
                    actionText: '+ Create Group',
                    onActionTap: () => _openCreateGroup(context),
                  );
                }

                return Column(
                  children: groups.map((g) {
                    final memberCount = g.members.length;
                    final isOwed = g.userBalancePaise > 0;
                    final owes = g.userBalancePaise < 0;
                    final balanceText = isOwed
                        ? '+${CurrencyFormatter.format(g.userBalancePaise)}'
                        : owes
                            ? '-${CurrencyFormatter.format(-g.userBalancePaise)}'
                            : 'Settled';
                    final balanceColor = isOwed
                        ? AppColors.income
                        : owes
                            ? AppColors.expense
                            : AppColors.textDisabled;
                    final balanceBgColor = isOwed
                        ? AppColors.incomeLight
                        : owes
                            ? AppColors.expenseLight
                            : AppColors.surfaceElevated;
                    final initials = g.name.trim().isNotEmpty ? g.name.trim()[0].toUpperCase() : 'G';

                    return ApplePressable(
                      onTap: () => context.push('/group-detail', extra: g),
                      pressedScale: 0.98,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: AppColors.shadowSm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.borrowedLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.borrowed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$memberCount members • ${CurrencyFormatter.format(g.totalExpensePaise)} total',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: balanceBgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                balanceText,
                                style: AppTypography.caption.copyWith(
                                  color: balanceColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
