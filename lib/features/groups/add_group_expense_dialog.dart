import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/group_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/group.dart';
import '../../presentation/widgets/shared_widgets.dart';

class AddGroupExpenseDialog extends ConsumerStatefulWidget {
  final Group group;

  const AddGroupExpenseDialog({super.key, required this.group});

  @override
  ConsumerState<AddGroupExpenseDialog> createState() => _AddGroupExpenseDialogState();
}

class _AddGroupExpenseDialogState extends ConsumerState<AddGroupExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  GroupMember? _paidByMember;
  bool _splitEqually = true;
  final Map<String, TextEditingController> _customSplitControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.group.members.isNotEmpty) {
      _paidByMember = widget.group.members.first;
      for (final m in widget.group.members) {
        final ctrl = TextEditingController();
        ctrl.addListener(() => setState(() {}));
        _customSplitControllers[m.id] = ctrl;
      }
    }
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final c in _customSplitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefillCustomSplits() {
    final totalPaise = CurrencyFormatter.parseToPaise(_amountController.text) ?? 0;
    final members = widget.group.members;
    if (totalPaise > 0 && members.isNotEmpty) {
      final count = members.length;
      final baseShare = totalPaise ~/ count;
      final remainder = totalPaise % count;

      for (var i = 0; i < count; i++) {
        final share = baseShare + (i < remainder ? 1 : 0);
        _customSplitControllers[members[i].id]?.text = (share / 100.0).toStringAsFixed(2);
      }
    }
  }

  int get _allocatedPaise {
    int sum = 0;
    for (final c in _customSplitControllers.values) {
      sum += CurrencyFormatter.parseToPaise(c.text) ?? 0;
    }
    return sum;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final totalPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (totalPaise == null || totalPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense amount')),
      );
      return;
    }

    if (_paidByMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who paid for this expense')),
      );
      return;
    }

    final members = widget.group.members;
    final splitMap = <String, int>{};

    if (_splitEqually) {
      // Deterministic integer split with remainder allocation
      final count = members.length;
      final baseShare = totalPaise ~/ count;
      final remainder = totalPaise % count;

      for (var i = 0; i < count; i++) {
        final share = baseShare + (i < remainder ? 1 : 0);
        splitMap[members[i].id] = share;
      }
    } else {
      // Custom split: verify sum equals total
      int sum = 0;
      for (final m in members) {
        final share = CurrencyFormatter.parseToPaise(_customSplitControllers[m.id]?.text ?? '0') ?? 0;
        splitMap[m.id] = share;
        sum += share;
      }

      if (sum != totalPaise) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sum of custom splits (${CurrencyFormatter.format(sum)}) must equal total (${CurrencyFormatter.format(totalPaise)})',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.createGroupExpense(
        groupId: widget.group.id,
        description: _descController.text.trim(),
        amountPaise: totalPaise,
        paidByMemberId: _paidByMember!.id,
        date: DateTime.now(),
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        splitMap: splitMap,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving group expense: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;
    final totalPaise = CurrencyFormatter.parseToPaise(_amountController.text) ?? 0;
    final allocatedPaise = _allocatedPaise;
    final remainingPaise = totalPaise - allocatedPaise;

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
                const Text('Add Group Expense', style: AppTypography.titleLarge),
                const SizedBox(height: 2),
                Text('In group: ${widget.group.name}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),

                // Expense Description
                const Text('DESCRIPTION', style: AppTypography.eyebrow),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. Dinner, Hotel booking, Taxi ride',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter description' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Total Amount
                const Text('TOTAL AMOUNT', style: AppTypography.eyebrow),
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

                // Paid By Dropdown
                const Text('PAID BY', style: AppTypography.eyebrow),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _paidByMember?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: members.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name, style: AppTypography.bodyMedium),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _paidByMember = members.firstWhere((m) => m.id == val);
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Split Type Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SPLIT TYPE', style: AppTypography.eyebrow),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Equally'),
                          selected: _splitEqually,
                          selectedColor: AppColors.textPrimary,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: _splitEqually ? AppColors.textPrimary : AppColors.borderSubtle,
                          ),
                          labelStyle: AppTypography.bodySmall.copyWith(
                            color: _splitEqually ? AppColors.surface : AppColors.textPrimary,
                            fontWeight: _splitEqually ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _splitEqually = true);
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Custom'),
                          selected: !_splitEqually,
                          selectedColor: AppColors.textPrimary,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: !_splitEqually ? AppColors.textPrimary : AppColors.borderSubtle,
                          ),
                          labelStyle: AppTypography.bodySmall.copyWith(
                            color: !_splitEqually ? AppColors.surface : AppColors.textPrimary,
                            fontWeight: !_splitEqually ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _splitEqually = false;
                              _prefillCustomSplits();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Custom Split Breakdown Fields with Live Feedback
                if (!_splitEqually) ...[
                  // Live Allocation Indicator Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: remainingPaise == 0 && totalPaise > 0
                          ? AppColors.incomeLight
                          : remainingPaise < 0
                              ? AppColors.expenseLight
                              : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: remainingPaise == 0 && totalPaise > 0
                            ? AppColors.income.withValues(alpha: 0.3)
                            : remainingPaise < 0
                                ? AppColors.expense.withValues(alpha: 0.3)
                                : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              remainingPaise == 0 && totalPaise > 0
                                  ? Icons.check_circle_rounded
                                  : remainingPaise < 0
                                      ? Icons.error_outline_rounded
                                      : Icons.pie_chart_outline_rounded,
                              size: 16,
                              color: remainingPaise == 0 && totalPaise > 0
                                  ? AppColors.income
                                  : remainingPaise < 0
                                      ? AppColors.expense
                                      : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Allocated: ${CurrencyFormatter.format(allocatedPaise)}',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: remainingPaise == 0 && totalPaise > 0
                                    ? AppColors.income
                                    : remainingPaise < 0
                                        ? AppColors.expense
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          remainingPaise == 0 && totalPaise > 0
                              ? 'Exact match'
                              : remainingPaise > 0
                                  ? '${CurrencyFormatter.format(remainingPaise)} left'
                                  : 'Over by ${CurrencyFormatter.format(-remainingPaise)}',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: remainingPaise == 0 && totalPaise > 0
                                ? AppColors.income
                                : remainingPaise < 0
                                    ? AppColors.expense
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: members.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(m.name, style: AppTypography.bodyMedium)),
                              SizedBox(
                                width: 110,
                                height: 38,
                                child: TextFormField(
                                  controller: _customSplitControllers[m.id],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    prefixText: '₹ ',
                                    filled: true,
                                    fillColor: AppColors.surfaceElevated,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

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

                // Submit Button with ApplePressable
                ApplePressable(
                  onTap: _isSaving ? null : _saveExpense,
                  pressedScale: 0.97,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    alignment: Alignment.center,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                          )
                        : Text('Add Group Expense', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
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
