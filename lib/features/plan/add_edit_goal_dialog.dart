import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/goal_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/goal.dart';

class AddEditGoalDialog extends ConsumerStatefulWidget {
  final SavingsGoal? goal;

  const AddEditGoalDialog({super.key, this.goal});

  @override
  ConsumerState<AddEditGoalDialog> createState() => _AddEditGoalDialogState();
}

class _AddEditGoalDialogState extends ConsumerState<AddEditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _savedAmountController;
  late TextEditingController _monthlyContributionController;
  DateTime? _targetDate;
  String _selectedIcon = 'star';
  bool _isSaving = false;

  bool get isEditing => widget.goal != null;

  final List<(String, IconData)> _icons = const [
    ('star', Icons.star_rounded),
    ('shield', Icons.shield_outlined),
    ('laptop', Icons.laptop_mac_rounded),
    ('flight', Icons.flight_takeoff_rounded),
    ('home', Icons.home_rounded),
    ('car', Icons.directions_car_rounded),
    ('school', Icons.school_rounded),
    ('favorite', Icons.favorite_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? (g.targetAmountPaise / 100.0).toStringAsFixed(2) : '',
    );
    _savedAmountController = TextEditingController(
      text: g != null ? (g.savedAmountPaise / 100.0).toStringAsFixed(2) : '0.00',
    );
    _monthlyContributionController = TextEditingController(
      text: g?.monthlyContributionPaise != null
          ? (g!.monthlyContributionPaise! / 100.0).toStringAsFixed(2)
          : '',
    );
    _targetDate = g?.targetDate;
    _selectedIcon = g?.icon ?? 'star';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
    _monthlyContributionController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final targetPaise = CurrencyFormatter.parseToPaise(_targetAmountController.text);
    if (targetPaise == null || targetPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    final savedPaise = CurrencyFormatter.parseToPaise(_savedAmountController.text) ?? 0;
    final monthlyPaise = _monthlyContributionController.text.isNotEmpty
        ? CurrencyFormatter.parseToPaise(_monthlyContributionController.text)
        : null;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(goalRepositoryProvider);
      final now = DateTime.now();

      if (isEditing) {
        final updated = widget.goal!.copyWith(
          name: _nameController.text.trim(),
          targetAmountPaise: targetPaise,
          savedAmountPaise: savedPaise,
          monthlyContributionPaise: monthlyPaise,
          targetDate: _targetDate,
          icon: _selectedIcon,
          updatedAt: now,
        );
        await repo.updateGoal(updated);
      } else {
        final newGoal = SavingsGoal(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          targetAmountPaise: targetPaise,
          savedAmountPaise: savedPaise,
          monthlyContributionPaise: monthlyPaise,
          targetDate: _targetDate,
          icon: _selectedIcon,
          createdAt: now,
          updatedAt: now,
        );
        await repo.createGoal(newGoal);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goal: $e')),
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
                  isEditing ? 'Edit Savings Goal' : 'New Savings Goal',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),

                // Icon Selection Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _icons.map((item) {
                      final isSelected = _selectedIcon == item.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = item.$1),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.textPrimary : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isSelected ? AppColors.textPrimary : AppColors.borderSubtle,
                            ),
                          ),
                          child: Icon(
                            item.$2,
                            size: 20,
                            color: isSelected ? AppColors.surface : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Goal Name
                const Text('GOAL NAME', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. Emergency Fund, New Laptop, Japan Trip',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a goal name' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Target Amount
                const Text('TARGET AMOUNT', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _targetAmountController,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Current Saved Amount
                const Text('CURRENT SAVED AMOUNT', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _savedAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Target Date
                const Text('TARGET DATE (OPTIONAL)', style: AppTypography.caption),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickTargetDate,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          _targetDate != null ? DateFormatter.formatDate(_targetDate!) : 'Select target completion date',
                          style: AppTypography.bodySmall.copyWith(
                            color: _targetDate != null ? AppColors.textPrimary : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
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
                        : Text(
                            isEditing ? 'Save Changes' : 'Create Goal',
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
