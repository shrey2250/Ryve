import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/category_providers.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/smart_transaction_parser.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../presentation/widgets/shared_widgets.dart';

/// Add Income Screen - Light keypad entry with destination account selector, category chips, and date/time selector.
class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  String _amountStr = '0';
  Category? _selectedCategory;
  Account? _selectedAccount;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _onNumpadTap(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      if (val == '⌫') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (val == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = val;
        } else {
          if (_amountStr.contains('.')) {
            final parts = _amountStr.split('.');
            if (parts.length > 1 && parts[1].length >= 2) return;
          }
          _amountStr += val;
        }
      }
    });
  }

  double get _parsedAmount => double.tryParse(_amountStr) ?? 0.0;

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveIncome() async {
    final amountPaise = CurrencyFormatter.parseToPaise(_amountStr);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an income amount greater than 0')),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account')),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repository = ref.read(transactionRepositoryProvider);
      final transaction = Transaction(
        id: const Uuid().v4(),
        accountId: _selectedAccount!.id,
        amountPaise: amountPaise,
        type: TransactionType.income,
        categoryId: _selectedCategory?.id ?? 'sys-income',
        categoryName: _selectedCategory?.name ?? 'Income',
        categoryIconName: _selectedCategory?.iconName ?? 'arrow_downward',
        categoryColorHex: _selectedCategory?.colorHex ?? '0xFF059669',
        description: _descriptionController.text.trim().isEmpty
            ? 'Income Deposit'
            : _descriptionController.text.trim(),
        merchantName: _sourceController.text.trim().isNotEmpty ? _sourceController.text.trim() : null,
        date: _selectedDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createTransaction(transaction);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving income: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(incomeCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    accountsAsync.whenData((accounts) {
      if (_selectedAccount == null && accounts.isNotEmpty) {
        setState(() => _selectedAccount = accounts.first);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Income', style: AppTypography.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: _isSaving ? null : _saveIncome,
              style: TextButton.styleFrom(foregroundColor: AppColors.income),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.income),
                    )
                  : Text(
                      'Save',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.income,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Amount Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text('INCOME AMOUNT', style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    CurrencyFormatter.format((_parsedAmount * 100).round()),
                    style: AppTypography.hero.copyWith(
                      color: AppColors.income,
                      fontSize: 38,
                    ),
                  ),
                ],
              ),
            ),

            // Form Fields
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // Destination Account and Date Row
                  Row(
                    children: [
                      // Destination Account
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showAccountPicker(context, accountsAsync),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedAccount != null
                                      ? IconData(_selectedAccount!.iconCodePoint, fontFamily: 'MaterialIcons')
                                      : Icons.account_balance_wallet_outlined,
                                  color: AppColors.income,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedAccount?.name ?? 'Select Account',
                                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Date Picker
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDateTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormatter.formatDate(_selectedDate),
                                    style: AppTypography.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Selector Chips
                  const Text('CATEGORY', style: AppTypography.caption),
                  const SizedBox(height: AppSpacing.xs),
                  categoriesAsync.when(
                    loading: () => const ShimmerBox(width: double.infinity, height: 40),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (categories) {
                      if (_selectedCategory == null && categories.isNotEmpty) {
                        _selectedCategory = categories.first;
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final isSelected = _selectedCategory?.id == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.xs),
                              child: ChoiceChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                selectedColor: AppColors.income.withValues(alpha: 0.15),
                                backgroundColor: AppColors.surface,
                                side: BorderSide(
                                  color: isSelected ? AppColors.income : AppColors.borderSubtle,
                                ),
                                labelStyle: AppTypography.bodySmall.copyWith(
                                  color: isSelected ? AppColors.income : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCategory = cat);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description / Source Fields
                  TextField(
                    controller: _descriptionController,
                    onChanged: (val) {
                      setState(() {});
                    },
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: "Description or quick note (e.g. 'Freelance stipend 45000 from Acme')",
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.income),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                    ),
                  ),

                  // Smart Natural Language Assist Chip
                  if (_descriptionController.text.trim().isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final parsed = SmartTransactionParser.parse(_descriptionController.text);
                        final hasAnyDetection = parsed.amountPaise != null ||
                            parsed.categoryId != null ||
                            parsed.merchant != null;

                        if (!hasAnyDetection) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: ApplePressable(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                if (parsed.amountPaise != null) {
                                  _amountStr = (parsed.amountPaise! / 100).toStringAsFixed(parsed.amountPaise! % 100 == 0 ? 0 : 2);
                                }
                                if (parsed.merchant != null) {
                                  _sourceController.text = parsed.merchant!;
                                }
                                if (parsed.categoryId != null) {
                                  final allCats = categoriesAsync.asData?.value ?? [];
                                  final match = allCats.where((c) => c.id == parsed.categoryId).firstOrNull;
                                  if (match != null) {
                                    _selectedCategory = match;
                                  }
                                }
                                if (parsed.description != null && parsed.description!.isNotEmpty) {
                                  _descriptionController.text = parsed.description!;
                                }
                              });
                            },
                            pressedScale: 0.98,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.incomeLight,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(color: AppColors.income.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.income),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Auto-fill: ${parsed.amountPaise != null ? CurrencyFormatter.format(parsed.amountPaise!) : ''}'
                                      '${parsed.merchant != null ? ' • ${parsed.merchant}' : ''}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.income,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _sourceController,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Source / Payer (Optional)',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
                      filled: true,
                      fillColor: AppColors.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.income),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Numpad Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                children: [
                  _buildNumpadRow(['1', '2', '3']),
                  _buildNumpadRow(['4', '5', '6']),
                  _buildNumpadRow(['7', '8', '9']),
                  _buildNumpadRow(['.', '0', '⌫']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((k) {
          if (k == '⌫') {
            return RyveNumpadKey(
              label: '',
              height: 48,
              icon: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.textPrimary),
              onTap: () => _onNumpadTap(k),
            );
          }
          return RyveNumpadKey(
            label: k,
            height: 48,
            onTap: () => _onNumpadTap(k),
          );
        }).toList(),
      ),
    );
  }

  void _showAccountPicker(BuildContext context, AsyncValue<List<Account>> accountsAsync) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return accountsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Error: $err'),
          ),
          data: (accounts) {
            return ListView(
              shrinkWrap: true,
              children: [
                const RyveBottomSheetHeader(title: 'Select Destination Account'),
                ...accounts.map((acc) => ListTile(
                      leading: Icon(
                        IconData(acc.iconCodePoint, fontFamily: 'MaterialIcons'),
                        color: AppColors.income,
                      ),
                      title: Text(acc.name, style: AppTypography.bodyMedium),
                      subtitle: Text(CurrencyFormatter.format(acc.balancePaise), style: AppTypography.bodySmall),
                      trailing: _selectedAccount?.id == acc.id
                          ? const Icon(Icons.check_rounded, color: AppColors.income)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAccount = acc);
                        Navigator.of(ctx).pop();
                      },
                    )),
              ],
            );
          },
        );
      },
    );
  }
}
