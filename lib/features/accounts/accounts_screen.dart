import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/account_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/account.dart';
import '../../presentation/widgets/shared_widgets.dart';
import 'add_edit_account_dialog.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _openAddAccount(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const AddEditAccountDialog(),
    );
  }

  void _openEditAccount(BuildContext context, Account account) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddEditAccountDialog(account: account),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Accounts', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            onPressed: () => _openAddAccount(context),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 80),
        ),
        error: (err, _) => Center(
          child: Text('Error loading accounts: $err', style: AppTypography.bodySmall),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              subtitle: 'Add bank accounts, cash, or credit cards to track your net worth.',
              actionText: '+ Add Account',
              onActionTap: () => _openAddAccount(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Total Balance Summary Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: AppColors.shadowSm,
                ),
                child: Column(
                  children: [
                    const Text('TOTAL ACCOUNTS BALANCE', style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.xs),
                    totalBalanceAsync.when(
                      loading: () => const ShimmerBox(width: 140, height: 36),
                      error: (_, __) => Text(CurrencyFormatter.format(0), style: AppTypography.hero),
                      data: (total) => Text(
                        CurrencyFormatter.format(total),
                        style: AppTypography.hero.copyWith(fontSize: 32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              SectionHeader(
                title: 'All Accounts (${accounts.length})',
                actionText: '+ Add',
                onActionTap: () => _openAddAccount(context),
              ),
              const SizedBox(height: AppSpacing.sm),

              ...accounts.map((acc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        IconData(acc.iconCodePoint, fontFamily: 'MaterialIcons'),
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                    title: Text(acc.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      acc.type.label,
                      style: AppTypography.caption.copyWith(color: AppColors.textDisabled),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(acc.balancePaise),
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: acc.balancePaise < 0 ? AppColors.expense : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                          onSelected: (action) async {
                            if (action == 'edit') {
                              _openEditAccount(context, acc);
                            } else if (action == 'archive') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text('Archive Account?', style: AppTypography.titleLarge),
                                  content: Text(
                                    'Archiving "${acc.name}" will hide it from the active list. Existing transactions will be preserved.',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: Text('Archive', style: AppTypography.labelLarge.copyWith(color: AppColors.expense)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(accountRepositoryProvider).archiveAccount(acc.id);
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit Account')),
                            const PopupMenuItem(value: 'archive', child: Text('Archive Account')),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/account-detail', extra: acc);
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
