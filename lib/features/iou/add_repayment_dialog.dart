import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/iou_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/iou.dart';

class AddRepaymentDialog extends ConsumerStatefulWidget {
  final IouRecord iou;

  const AddRepaymentDialog({super.key, required this.iou});

  @override
  ConsumerState<AddRepaymentDialog> createState() => _AddRepaymentDialogState();
}

class _AddRepaymentDialogState extends ConsumerState<AddRepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.iou.remainingAmountPaise / 100.0).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amountPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid repayment amount')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(iouRepositoryProvider);
      await repo.addRepayment(
        iouId: widget.iou.id,
        amountPaise: amountPaise,
        date: DateTime.now(),
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording repayment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLent = widget.iou.type == IouType.lent;
    final color = isLent ? AppColors.lent : AppColors.borrowed;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
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
                Text(
                  isLent ? 'Record Received Repayment' : 'Record Paid Repayment',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Remaining balance: ${CurrencyFormatter.format(widget.iou.remainingAmountPaise)} (${widget.iou.personName ?? "Person"})',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                const Text('REPAYMENT AMOUNT', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.hero.copyWith(fontSize: 28, color: color),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: AppTypography.hero.copyWith(fontSize: 28, color: color),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _noteController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional, e.g. GPay / Cash)',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
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
                      backgroundColor: color,
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
                        : Text('Record Repayment', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
