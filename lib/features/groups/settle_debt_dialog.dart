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

class SettleDebtDialog extends ConsumerStatefulWidget {
  final Group group;
  final MemberDebt? defaultDebt;

  const SettleDebtDialog({super.key, required this.group, this.defaultDebt});

  @override
  ConsumerState<SettleDebtDialog> createState() => _SettleDebtDialogState();
}

class _SettleDebtDialogState extends ConsumerState<SettleDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();

  GroupMember? _fromMember;
  GroupMember? _toMember;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final members = widget.group.members;
    final debt = widget.defaultDebt;

    if (debt != null) {
      _amountController = TextEditingController(
        text: (debt.amountPaise / 100.0).toStringAsFixed(2),
      );
      _fromMember = members.firstWhere((m) => m.id == debt.fromMemberId, orElse: () => members.first);
      _toMember = members.firstWhere((m) => m.id == debt.toMemberId, orElse: () => members.last);
    } else {
      _amountController = TextEditingController();
      if (members.isNotEmpty) {
        _fromMember = members.first;
        _toMember = members.length > 1 ? members[1] : members.first;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitSettlement() async {
    if (!_formKey.currentState!.validate()) return;

    final amountPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid settlement amount')),
      );
      return;
    }

    if (_fromMember == null || _toMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select payer and payee')),
      );
      return;
    }

    if (_fromMember!.id == _toMember!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payer and payee must be different members')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.createSettlement(
        groupId: widget.group.id,
        fromMemberId: _fromMember!.id,
        toMemberId: _toMember!.id,
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
          SnackBar(content: Text('Error recording settlement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;

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
                const Text('Record Settlement', style: AppTypography.titleLarge),
                const SizedBox(height: 2),
                Text('Settle debt in ${widget.group.name}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),

                // Amount
                const Text('SETTLEMENT AMOUNT', style: AppTypography.eyebrow),
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

                // From & To Member Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WHO PAID', style: AppTypography.eyebrow),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _fromMember?.id,
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
                            items: members.map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.name, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _fromMember = members.firstWhere((m) => m.id == val);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PAID TO', style: AppTypography.eyebrow),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _toMember?.id,
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
                            items: members.map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.name, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _toMember = members.firstWhere((m) => m.id == val);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Note
                TextFormField(
                  controller: _noteController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional, e.g. UPI payment)',
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
                  onTap: _isSaving ? null : _submitSettlement,
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
                        : Text('Confirm Settlement', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
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
