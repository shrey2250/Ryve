import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/account.dart';
import 'shared_widgets.dart';

/// Account Card for horizontal scroll list on Home screen
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  (Color, Color) _getAccountColors() {
    switch (account.type) {
      case AccountType.online:
        return (AppColors.onlineColor, AppColors.lentLight);
      case AccountType.bank:
        return (AppColors.bankColor, AppColors.primaryLight);
      case AccountType.upi:
        return (AppColors.upiColor, AppColors.borrowedLight);
      case AccountType.cash:
        return (AppColors.cashColor, AppColors.incomeLight);
      case AccountType.creditCard:
        return (AppColors.cardColor, AppColors.warningLight);
      case AccountType.other:
        return (AppColors.otherColor, AppColors.lentLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (accentColor, bgColor) = _getAccountColors();

    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        width: 156,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    IconData(account.iconCodePoint, fontFamily: 'MaterialIcons'),
                    size: 18,
                    color: accentColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    account.type.name.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      fontSize: 8.5,
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(account.balancePaise),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

