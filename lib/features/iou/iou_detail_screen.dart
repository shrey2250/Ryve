import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/iou_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/iou.dart';
import '../../presentation/widgets/shared_widgets.dart';
import 'add_repayment_dialog.dart';

class IouDetailScreen extends ConsumerWidget {
  final IouRecord iou;

  const IouDetailScreen({super.key, required this.iou});

  void _openAddRepayment(BuildContext context, IouRecord record) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddRepaymentDialog(iou: record),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allIousAsync = ref.watch(allIousProvider);
    final record = allIousAsync.value?.firstWhere((r) => r.id == iou.id, orElse: () => iou) ?? iou;

    final isLent = record.type == IouType.lent;
    final color = isLent ? AppColors.lent : AppColors.borrowed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(record.personName ?? 'IOU Details', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Record?', style: AppTypography.titleLarge),
                  content: const Text('Are you sure you want to delete this IOU record?'),
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
                await ref.read(iouRepositoryProvider).deleteIou(record.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Status Card
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      isLent ? 'YOU LENT (ASSET)' : 'YOU BORROWED (LIABILITY)',
                      style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('REMAINING BALANCE', style: AppTypography.caption),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(record.remainingAmountPaise),
                    style: AppTypography.hero.copyWith(color: color, fontSize: 36),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Original: ${CurrencyFormatter.format(record.originalAmountPaise)} • Repaid: ${CurrencyFormatter.format(record.paidAmountPaise)}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Metadata Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.shadowSm,
              ),
              child: Column(
                children: [
                  _buildRow('Contact', record.personName ?? 'Unknown'),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _buildRow('Status', record.status.name.toUpperCase()),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _buildRow('Created Date', DateFormatter.formatFullDate(record.createdAt)),
                  if (record.dueDate != null) ...[
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _buildRow('Due Date', DateFormatter.formatFullDate(record.dueDate!)),
                  ],
                  if (record.note != null && record.note!.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _buildRow('Note', record.note!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Repayments Timeline
            SectionHeader(
              title: 'Repayment History (${record.repayments.length})',
              actionText: record.status == IouStatus.active ? '+ Add Repayment' : '',
              onActionTap: () => _openAddRepayment(context, record),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (record.repayments.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text('No repayments recorded yet', style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled)),
              )
            else
              ...record.repayments.map((rep) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormatter.formatDate(rep.date), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          if (rep.note != null && rep.note!.isNotEmpty)
                            Text(rep.note!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                      Text(
                        '+${CurrencyFormatter.format(rep.amountPaise)}',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.income, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: record.status == IouStatus.active
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _openAddRepayment(context, record),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      elevation: 0,
                    ),
                    child: Text('Record Repayment', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
