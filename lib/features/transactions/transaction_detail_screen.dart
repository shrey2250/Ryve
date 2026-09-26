import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/transaction.dart';
import 'edit_transaction_dialog.dart';

/// Transaction Detail Screen - Detailed light view of a single transaction with editing and deletion.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  late Transaction _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  Color _getAmountColor() {
    switch (_transaction.type) {
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.transfer:
        return AppColors.textPrimary;
    }
  }

  String _getPrefix() {
    switch (_transaction.type) {
      case TransactionType.expense:
        return '-';
      case TransactionType.income:
        return '+';
      case TransactionType.transfer:
        return '';
    }
  }

  void _openEditDialog() async {
    HapticFeedback.lightImpact();
    final updated = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => EditTransactionDialog(transaction: _transaction),
    );

    if (updated != null && mounted) {
      setState(() {
        _transaction = updated;
      });
    }
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('Delete Transaction?', style: AppTypography.titleLarge),
        content: Text(
          'Are you sure you want to delete "${_transaction.description}"? The account balance will be automatically recalculated.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final rootNav = Navigator.of(context);
              Navigator.of(ctx).pop();
              final repo = ref.read(transactionRepositoryProvider);
              await repo.deleteTransaction(_transaction.id);
              if (mounted) {
                rootNav.pop();
              }
            },
            child: Text('Delete', style: AppTypography.labelLarge.copyWith(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _getAmountColor();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Transaction Details', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: _openEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            // Header Icon Badge
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  _transaction.type == TransactionType.expense
                      ? Icons.arrow_upward_rounded
                      : _transaction.type == TransactionType.income
                          ? Icons.arrow_downward_rounded
                          : Icons.swap_horiz_rounded,
                  color: amountColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount Display
            Text(
              '${_getPrefix()}${CurrencyFormatter.format(_transaction.amountPaise)}',
              style: AppTypography.hero.copyWith(
                color: amountColor,
                fontSize: 38,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _transaction.description,
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (_transaction.merchantName != null && _transaction.merchantName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _transaction.merchantName!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // Details Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.shadowSm,
              ),
              child: Column(
                children: [
                  _buildDetailRow('Type', _transaction.type.name.toUpperCase()),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _buildDetailRow('Category', _transaction.categoryName ?? 'General'),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _buildDetailRow('Account', _transaction.accountName ?? 'Primary Account'),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _buildDetailRow('Date', DateFormatter.formatFullDate(_transaction.date)),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _buildDetailRow('Time', DateFormatter.formatTime(_transaction.date)),
                  if (_transaction.note != null && _transaction.note!.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _buildDetailRow('Note', _transaction.note!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
