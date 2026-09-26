import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../presentation/widgets/shared_widgets.dart';
import '../../presentation/widgets/transaction_widgets.dart';
import 'add_edit_account_dialog.dart';

class AccountDetailScreen extends ConsumerWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = TransactionFilter(accountId: account.id);
    final transactionsAsync = ref.watch(transactionsProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(account.name, style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
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
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.shadowSm,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconData(account.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(account.type.label.toUpperCase(), style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    CurrencyFormatter.format(account.balancePaise),
                    style: AppTypography.hero.copyWith(
                      color: account.balancePaise < 0 ? AppColors.expense : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SectionHeader(
              title: 'Activity for this account',
              actionText: '',
              onActionTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),

            transactionsAsync.when(
              loading: () => ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 60),
              ),
              error: (err, _) => Center(
                child: Text('Error loading transactions: $err', style: AppTypography.bodySmall),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No activity yet',
                    subtitle: 'Transactions linked to this account will show here.',
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
          ],
        ),
      ),
    );
  }
}
