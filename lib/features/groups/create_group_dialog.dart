import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/group_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [
    TextEditingController(text: 'You'),
    TextEditingController(),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    HapticFeedback.lightImpact();
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  void _removeMemberField(int index) {
    if (_memberControllers.length <= 2) return;
    HapticFeedback.lightImpact();
    setState(() {
      _memberControllers[index].dispose();
      _memberControllers.removeAt(index);
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final memberNames = _memberControllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (memberNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A group needs at least 2 members')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(groupRepositoryProvider);
      final group = await repo.createGroup(_nameController.text.trim(), memberNames);

      if (mounted) {
        Navigator.of(context).pop(group);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
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
                const Text('Create New Group', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.md),

                // Group Name
                const Text('GROUP NAME', style: AppTypography.caption),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. Goa Trip 2026, Flatmates, Dinner Club',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a group name' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Members
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MEMBERS', style: AppTypography.caption),
                    TextButton.icon(
                      onPressed: _addMemberField,
                      icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.textPrimary),
                      label: Text('Add Member', style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                ...List.generate(_memberControllers.length, (index) {
                  final isFirst = index == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _memberControllers[index],
                            readOnly: isFirst, // 'You' is fixed for primary member
                            style: AppTypography.bodyMedium,
                            decoration: InputDecoration(
                              hintText: isFirst ? 'You (Primary)' : 'Member Name',
                              prefixIcon: Icon(
                                isFirst ? Icons.person_rounded : Icons.person_outline_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: isFirst ? AppColors.surfaceElevated : AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        if (!isFirst && _memberControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.expense),
                            onPressed: () => _removeMemberField(index),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _createGroup,
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
                        : Text('Create Group', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
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
