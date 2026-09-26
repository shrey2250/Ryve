import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/goal_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/goal.dart';

class ContributeGoalDialog extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const ContributeGoalDialog({super.key, required this.goal});

  @override
  ConsumerState<ContributeGoalDialog> createState() => _ContributeGoalDialogState();
}

class _ContributeGoalDialogState extends ConsumerState<ContributeGoalDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(goalRepositoryProvider);
      await repo.addContribution(widget.goal.id, amountPaise);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding contribution: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Add to ${widget.goal.name}', style: AppTypography.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Currently saved: ${CurrencyFormatter.format(widget.goal.savedAmountPaise)} of ${CurrencyFormatter.format(widget.goal.targetAmountPaise)}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Text('DEPOSIT AMOUNT', style: AppTypography.caption),
            const SizedBox(height: 4),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.hero.copyWith(fontSize: 28),
              decoration: InputDecoration(
                prefixText: '₹ ',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                      )
                    : Text('Add Savings', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
