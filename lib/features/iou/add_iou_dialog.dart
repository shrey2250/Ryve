import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/iou_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/iou.dart';
import '../../domain/entities/person.dart';

class AddIouDialog extends ConsumerStatefulWidget {
  final IouType defaultType;

  const AddIouDialog({super.key, this.defaultType = IouType.lent});

  @override
  ConsumerState<AddIouDialog> createState() => _AddIouDialogState();
}

class _AddIouDialogState extends ConsumerState<AddIouDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late IouType _type;
  DateTime? _dueDate;
  Person? _selectedPerson;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
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

    final personName = _personNameController.text.trim();
    if (personName.isEmpty && _selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a contact name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(iouRepositoryProvider);
      final now = DateTime.now();

      String personId;
      if (_selectedPerson != null) {
        personId = _selectedPerson!.id;
      } else {
        final existingPeople = await repo.getPeople();
        final match = existingPeople.where(
          (p) => p.name.trim().toLowerCase() == personName.toLowerCase(),
        );
        if (match.isNotEmpty) {
          personId = match.first.id;
        } else {
          final newPerson = await repo.createPerson(personName);
          personId = newPerson.id;
        }
      }

      final iou = IouRecord(
        id: const Uuid().v4(),
        personId: personId,
        personName: personName.isNotEmpty ? personName : _selectedPerson?.name,
        type: _type,
        originalAmountPaise: amountPaise,
        dueDate: _dueDate,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      await repo.createIou(iou);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final accentColor = _type == IouType.lent ? AppColors.lent : AppColors.borrowed;

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
                  _type == IouType.lent ? 'Record Money Lent' : 'Record Money Borrowed',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),

                // Type Toggle (Lent vs Borrowed)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _type = IouType.lent);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _type == IouType.lent ? AppColors.lent.withValues(alpha: 0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: _type == IouType.lent ? AppColors.lent : AppColors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            'You Lent (Owed to you)',
                            style: AppTypography.bodySmall.copyWith(
                              color: _type == IouType.lent ? AppColors.lent : AppColors.textSecondary,
                              fontWeight: _type == IouType.lent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _type = IouType.borrowed);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _type == IouType.borrowed ? AppColors.borrowed.withValues(alpha: 0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: _type == IouType.borrowed ? AppColors.borrowed : AppColors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            'You Borrowed (You owe)',
                            style: AppTypography.bodySmall.copyWith(
                              color: _type == IouType.borrowed ? AppColors.borrowed : AppColors.textSecondary,
                              fontWeight: _type == IouType.borrowed ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Amount Field
                const Text('AMOUNT', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.hero.copyWith(fontSize: 28, color: accentColor),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: AppTypography.hero.copyWith(fontSize: 28, color: accentColor),
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

                // Contact Name
                const Text('PERSON / CONTACT', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _personNameController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. Rahul, Priya Sharma, Landlord',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a person name' : null,
                ),

                // Quick select from recent people
                peopleAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (people) {
                    if (people.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: people.take(5).map((p) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(p.name),
                                labelStyle: AppTypography.caption,
                                backgroundColor: AppColors.surfaceElevated,
                                onPressed: () {
                                  setState(() {
                                    _selectedPerson = p;
                                    _personNameController.text = p.name;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Due Date
                const Text('DUE DATE (OPTIONAL)', style: AppTypography.caption),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickDueDate,
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
                          _dueDate != null ? DateFormatter.formatDate(_dueDate!) : 'Select expected repayment date',
                          style: AppTypography.bodySmall.copyWith(
                            color: _dueDate != null ? AppColors.textPrimary : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Note
                TextFormField(
                  controller: _noteController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional, e.g. For concert tickets)',
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

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
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
                        : Text('Save Record', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
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
