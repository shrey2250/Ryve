import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';

class AddEditAccountDialog extends ConsumerStatefulWidget {
  final Account? account;

  const AddEditAccountDialog({super.key, this.account});

  @override
  ConsumerState<AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends ConsumerState<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late AccountType _selectedType;
  bool _isSaving = false;

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account != null
          ? (widget.account!.balancePaise / 100.0).toStringAsFixed(2)
          : '0.00',
    );
    _selectedType = widget.account?.type ?? AccountType.bank;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final accountRepo = ref.read(accountRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);
      final now = DateTime.now();

      if (isEditing) {
        final updated = widget.account!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          updatedAt: now,
        );
        await accountRepo.updateAccount(updated);
      } else {
        final newId = const Uuid().v4();
        final openingPaise = CurrencyFormatter.parseToPaise(_balanceController.text) ?? 0;

        final newAccount = Account(
          id: newId,
          name: _nameController.text.trim(),
          type: _selectedType,
          balancePaise: 0,
          createdAt: now,
          updatedAt: now,
        );

        await accountRepo.createAccount(newAccount);

        if (openingPaise > 0) {
          final openingTx = Transaction(
            id: const Uuid().v4(),
            accountId: newId,
            type: TransactionType.income,
            amountPaise: openingPaise,
            description: 'Opening Balance',
            categoryName: 'Initial Deposit',
            categoryIcon: 'account_balance_wallet',
            date: now,
            note: 'Initial account opening balance',
            createdAt: now,
            updatedAt: now,
          );
          await txRepo.createTransaction(openingTx);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving account: $e')),
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
                  isEditing ? 'Edit Account' : 'Add New Account',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),

                // Account Name
                const Text('ACCOUNT NAME', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. HDFC Salary, Main Cash, GPay UPI',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Please enter account name' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Account Type Selector
                const Text('ACCOUNT TYPE', style: AppTypography.caption),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: AccountType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text('${type.icon} ${type.label}'),
                      selected: isSelected,
                      selectedColor: AppColors.textPrimary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected ? AppColors.textPrimary : AppColors.borderSubtle,
                      ),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: isSelected ? AppColors.surface : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = type);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Opening Balance (only when adding new account)
                if (!isEditing) ...[
                  const Text('OPENING BALANCE', style: AppTypography.caption),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                          )
                        : Text(
                            isEditing ? 'Save Changes' : 'Create Account',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.surface),
                          ),
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
