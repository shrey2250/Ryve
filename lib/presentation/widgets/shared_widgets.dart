import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';

/// Hero Financial Amount Display with clean light typography & optical tracking
class AmountDisplay extends StatelessWidget {
  final int amountPaise;
  final String label;
  final TextStyle? amountStyle;
  final Color? color;

  const AmountDisplay({
    super.key,
    required this.amountPaise,
    required this.label,
    this.amountStyle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          CurrencyFormatter.format(amountPaise),
          style: amountStyle ??
              AppTypography.hero.copyWith(
                color: color ?? AppColors.textPrimary,
                letterSpacing: -1.2,
              ),
        ),
      ],
    );
  }
}

/// Tactile Apple-grade Pressable with immediate spring scale & haptic feedback
class ApplePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const ApplePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.borderRadius,
  });

  @override
  State<ApplePressable> createState() => _ApplePressableState();
}

class _ApplePressableState extends State<ApplePressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}


/// Monthly Income, Spent, and Savings Summary Row
class SummaryRow extends StatelessWidget {
  final int incomePaise;
  final int expensePaise;
  final int netSavingsPaise;
  final bool isPrivate;

  const SummaryRow({
    super.key,
    required this.incomePaise,
    required this.expensePaise,
    required this.netSavingsPaise,
    this.isPrivate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            label: 'Inflow',
            paise: incomePaise,
            color: AppColors.income,
            bgColor: AppColors.incomeLight,
            icon: Icons.arrow_downward_rounded,
          ),
          Container(width: 1, height: 36, color: AppColors.borderSubtle),
          _buildSummaryItem(
            label: 'Outflow',
            paise: expensePaise,
            color: AppColors.expense,
            bgColor: AppColors.expenseLight,
            icon: Icons.arrow_upward_rounded,
          ),
          Container(width: 1, height: 36, color: AppColors.borderSubtle),
          _buildSummaryItem(
            label: 'Saved',
            paise: netSavingsPaise,
            color: netSavingsPaise >= 0 ? AppColors.lent : AppColors.expense,
            bgColor: netSavingsPaise >= 0 ? AppColors.lentLight : AppColors.expenseLight,
            icon: Icons.savings_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required int paise,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 11, color: color),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isPrivate ? '••••' : CurrencyFormatter.formatCompact(paise),
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}


/// Standardized Section Header with action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium,
        ),
        if (actionText != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty State placeholder with calm light aesthetics
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onActionTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionText,
    this.onAction,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = actionText ?? actionLabel;
    final callback = onActionTap ?? onAction;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.textDisabled),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (label != null && callback != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: callback,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderMedium),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: Text(label, style: AppTypography.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Light Shimmer loading placeholder
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.surfaceElevated,
              AppColors.borderSubtle,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Bottom Sheet Header bar
class RyveBottomSheetHeader extends StatelessWidget {
  final String title;

  const RyveBottomSheetHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(title, style: AppTypography.titleMedium),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Unified Apple-grade Numpad Key with spring compression & optical styling
class RyveNumpadKey extends StatelessWidget {
  final String label;
  final Widget? icon;
  final VoidCallback onTap;
  final double height;

  const RyveNumpadKey({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: ApplePressable(
          onTap: onTap,
          pressedScale: 0.94,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.shadowSm,
            ),
            child: icon ??
                Text(
                  label,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 21,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

