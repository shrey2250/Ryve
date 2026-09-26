import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import 'shared_widgets.dart';

/// TransactionRow widget with category icon badge, description, and muted amount color.
class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionRow({
    super.key,
    required this.transaction,
    this.onTap,
  });

  (Color, Color) _getColors() {
    switch (transaction.type) {
      case TransactionType.expense:
        return (AppColors.expense, AppColors.expenseLight);
      case TransactionType.income:
        return (AppColors.income, AppColors.incomeLight);
      case TransactionType.transfer:
        return (AppColors.lent, AppColors.lentLight);
    }
  }

  String _getPrefix() {
    switch (transaction.type) {
      case TransactionType.expense:
        return '-';
      case TransactionType.income:
        return '+';
      case TransactionType.transfer:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final (amountColor, badgeBgColor) = _getColors();

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Category Icon Badge with soft pastel tint
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: badgeBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.type == TransactionType.expense
                    ? Icons.arrow_upward_rounded
                    : transaction.type == TransactionType.income
                        ? Icons.arrow_downward_rounded
                        : Icons.swap_horiz_rounded,
                size: 20,
                color: amountColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Description & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.merchantName ?? transaction.categoryName ?? 'General',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Amount Display
            Text(
              '${_getPrefix()}${CurrencyFormatter.format(transaction.amountPaise)}',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Header label for grouping transactions by date
class TransactionDateHeader extends StatelessWidget {
  final String dateLabel;

  const TransactionDateHeader({
    super.key,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        dateLabel.toUpperCase(),
        style: AppTypography.caption,
      ),
    );
  }
}

/// Category Select Chip for Add Expense screen
class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.name,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.surface : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
