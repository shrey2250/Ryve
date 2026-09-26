import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/budget_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/budget.dart';

class SetBudgetDialog extends ConsumerStatefulWidget {
  final MonthlyBudget? currentBudget;
  final String month;

  const SetBudgetDialog({super.key, this.currentBudget, required this.month});

  @override
  ConsumerState<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends ConsumerState<SetBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentBudget != null
          ? (widget.currentBudget!.amountPaise / 100.0).toStringAsFixed(2)
          : '30000.00',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(budgetRepositoryProvider);
      final now = DateTime.now();
      final budget = MonthlyBudget(
        id: widget.currentBudget?.id ?? const Uuid().v4(),
        month: widget.month,
        amountPaise: amountPaise,
        createdAt: widget.currentBudget?.createdAt ?? now,
        updatedAt: now,
      );

      await repo.setMonthlyBudget(budget);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving budget: $e')),
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
        child: Form(
          key: _formKey,
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
              const Text('Monthly Budget Cap', style: AppTypography.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Set the maximum total spending target for ${widget.month}.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text('MONTHLY LIMIT', style: AppTypography.caption),
              const SizedBox(height: 4),
              TextFormField(
                controller: _amountController,
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
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
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
                      : Text('Set Budget Limit', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
