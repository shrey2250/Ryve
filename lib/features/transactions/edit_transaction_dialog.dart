import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/category_providers.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';

class EditTransactionDialog extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EditTransactionDialog({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends ConsumerState<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _merchantController;
  late TextEditingController _noteController;

  late TransactionType _type;
  late DateTime _date;
  Account? _selectedAccount;
  Category? _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(
      text: (tx.amountPaise / 100.0).toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(text: tx.description);
    _merchantController = TextEditingController(text: tx.merchantName ?? '');
    _noteController = TextEditingController(text: tx.note ?? '');
    _type = tx.type;
    _date = tx.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final updated = widget.transaction.copyWith(
        accountId: _selectedAccount!.id,
        amountPaise: amountPaise,
        type: _type,
        categoryId: _selectedCategory?.id ?? widget.transaction.categoryId,
        categoryName: _selectedCategory?.name ?? widget.transaction.categoryName,
        categoryIconName: _selectedCategory?.iconName ?? widget.transaction.categoryIconName,
        description: _descriptionController.text.trim().isEmpty
            ? (_selectedCategory?.name ?? 'Transaction')
            : _descriptionController.text.trim(),
        merchantName: _merchantController.text.trim().isNotEmpty
            ? _merchantController.text.trim()
            : null,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        date: _date,
        updatedAt: DateTime.now(),
      );

      await repo.updateTransaction(updated);

      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = _type == TransactionType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    accountsAsync.whenData((accounts) {
      _selectedAccount ??= accounts.firstWhere(
          (a) => a.id == widget.transaction.accountId,
          orElse: () => accounts.first,
        );
    });

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
                const Text('Edit Transaction', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.md),

                // Amount Field
                const Text('AMOUNT', style: AppTypography.caption),
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
                const SizedBox(height: AppSpacing.md),

                // Account & Date Pickers Row
                Row(
                  children: [
                    // Account
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACCOUNT', style: AppTypography.caption),
                          const SizedBox(height: 4),
                          accountsAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (accounts) {
                              return DropdownButtonFormField<String>(
                                value: _selectedAccount?.id,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: accounts.map((acc) => DropdownMenuItem(
                                  value: acc.id,
                                  child: Text(acc.name, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAccount = accounts.firstWhere((a) => a.id == val);
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Date & Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE & TIME', style: AppTypography.caption),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _pickDateTime,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      DateFormatter.formatDate(_date),
                                      style: AppTypography.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Category Chips
                const Text('CATEGORY', style: AppTypography.caption),
                const SizedBox(height: 4),
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = (_selectedCategory?.id ?? widget.transaction.categoryId) == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: AppColors.textPrimary,
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: isSelected ? AppColors.textPrimary : AppColors.borderSubtle,
                              ),
                              labelStyle: AppTypography.bodySmall.copyWith(
                                color: isSelected ? AppColors.surface : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Merchant / Payer
                TextFormField(
                  controller: _merchantController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: _type == TransactionType.expense ? 'Merchant' : 'Source / Payer',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Note
                TextFormField(
                  controller: _noteController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Save Button
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
                        : Text('Update Transaction', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
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
