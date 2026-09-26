import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/recurring_bill_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/recurring_bill.dart';
import '../../presentation/widgets/shared_widgets.dart';

class AddEditRecurringBillDialog extends ConsumerStatefulWidget {
  final RecurringBill? bill;

  const AddEditRecurringBillDialog({super.key, this.bill});

  @override
  ConsumerState<AddEditRecurringBillDialog> createState() =>
      _AddEditRecurringBillDialogState();
}

class _AddEditRecurringBillDialogState
    extends ConsumerState<AddEditRecurringBillDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late BillingCycle _cycle;
  late DateTime _nextDueDate;
  String? _selectedCategoryId;
  bool _isSaving = false;

  final List<(String, String, int, BillingCycle)> _presets = const [
    ('Netflix', 'cat_bills', 649, BillingCycle.monthly),
    ('Spotify', 'cat_bills', 119, BillingCycle.monthly),
    ('Rent', 'cat_rent', 15000, BillingCycle.monthly),
    ('WiFi / Internet', 'cat_bills', 799, BillingCycle.monthly),
    ('Gym / Fitness', 'cat_health', 2000, BillingCycle.monthly),
    ('iCloud', 'cat_bills', 75, BillingCycle.monthly),
    ('Amazon Prime', 'cat_bills', 1499, BillingCycle.yearly),
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _nameController = TextEditingController(text: b?.name ?? '');
    _amountController = TextEditingController(
      text: b != null ? CurrencyFormatter.formatForInput(b.amountPaise) : '',
    );
    _cycle = b?.cycle ?? BillingCycle.monthly;
    _nextDueDate = b?.nextDueDate ?? DateTime.now().add(const Duration(days: 30));
    _selectedCategoryId = b?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) {
      setState(() => _nextDueDate = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subscription or bill name.')),
      );
      return;
    }

    final amountPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(recurringBillRepositoryProvider);
      final now = DateTime.now();

      if (widget.bill != null) {
        final updated = widget.bill!.copyWith(
          name: name,
          amountPaise: amountPaise,
          cycle: _cycle,
          nextDueDate: _nextDueDate,
          categoryId: _selectedCategoryId ?? widget.bill!.categoryId,
          updatedAt: now,
        );
        await repo.updateRecurringBill(updated);
      } else {
        final newBill = RecurringBill(
          id: const Uuid().v4(),
          name: name,
          amountPaise: amountPaise,
          cycle: _cycle,
          nextDueDate: _nextDueDate,
          categoryId: _selectedCategoryId,
          createdAt: now,
          updatedAt: now,
        );
        await repo.createRecurringBill(newBill);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bill != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Recurring Bill' : 'New Recurring Bill',
                  style: AppTypography.titleMedium,
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Bill'),
                          content: Text('Remove "${widget.bill!.name}" from recurring radar?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.expense))),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await ref.read(recurringBillRepositoryProvider).deleteRecurringBill(widget.bill!.id);
                        if (mounted) nav.pop();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Quick Preset Chips (if creating new)
            if (!isEditing) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presets.map((preset) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ApplePressable(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _nameController.text = preset.$1;
                            _amountController.text = preset.$3.toString();
                            _cycle = preset.$4;
                          });
                        },
                        pressedScale: 0.96,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            '+ ${preset.$1}',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Name
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Subscription / Bill Name',
                hintText: 'e.g. Netflix, Rent, Spotify',
                labelStyle: AppTypography.caption,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount & Cycle Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      labelStyle: AppTypography.caption,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BillingCycle>(
                        value: _cycle,
                        isExpanded: true,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        items: BillingCycle.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _cycle = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Next Due Date
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Next Due Date', style: AppTypography.bodySmall),
                      ],
                    ),
                    Text(
                      DateFormatter.formatDate(_nextDueDate),
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        isEditing ? 'Save Changes' : 'Add to Recurring Radar',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
