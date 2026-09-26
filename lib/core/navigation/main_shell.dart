import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transfer.dart';
import '../../presentation/widgets/shared_widgets.dart';
import '../providers/account_providers.dart';
import '../providers/transaction_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency_formatter.dart';

/// MainShell navigation containing the 5 primary destinations (Home, Transactions, Groups, Plan, Settings)
/// and a refined, subtle Quick-Add action.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _showQuickAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                const Text('Quick Action', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 20),
                  ),
                  title: Text('Add Expense', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Record an outgoing payment', style: AppTypography.bodySmall),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/add-expense');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 20),
                  ),
                  title: Text('Add Income', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Record incoming money', style: AppTypography.bodySmall),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/add-income');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.lent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: AppColors.lent, size: 20),
                  ),
                  title: Text('Transfer Funds', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Move money between accounts', style: AppTypography.bodySmall),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showTransferDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransferDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const _TransferModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          border: const Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Transactions'),
                _buildQuickAddButton(context),
                _buildNavItem(2, Icons.people_outline_rounded, Icons.people_rounded, 'Groups'),
                _buildNavItem(3, Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Plan'),
                _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = navigationShell.currentIndex == index;
    return ApplePressable(
      onTap: () => _onTabTapped(index),
      pressedScale: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected ? AppColors.textPrimary : AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: isSelected ? AppColors.textPrimary : AppColors.textDisabled,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton(BuildContext context) {
    return ApplePressable(
      onTap: () => _showQuickAddModal(context),
      pressedScale: 0.88,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.surface,
          size: 24,
        ),
      ),
    );
  }

}

class _TransferModalSheet extends ConsumerStatefulWidget {
  const _TransferModalSheet();

  @override
  ConsumerState<_TransferModalSheet> createState() => _TransferModalSheetState();
}

class _TransferModalSheetState extends ConsumerState<_TransferModalSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  Account? _fromAccount;
  Account? _toAccount;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer() async {
    final amountPaise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount')),
      );
      return;
    }
    if (_fromAccount == null || _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both source and destination accounts')),
      );
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts must be different')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      final transfer = Transfer(
        id: const Uuid().v4(),
        fromAccountId: _fromAccount!.id,
        toAccountId: _toAccount!.id,
        amountPaise: amountPaise,
        date: DateTime.now(),
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fromAccountName: _fromAccount!.name,
        toAccountName: _toAccount!.name,
      );

      await repo.createTransfer(transfer);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferred ${CurrencyFormatter.format(amountPaise)} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error transferring funds: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
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
              const Text('Transfer Funds', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.md),

              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.hero.copyWith(fontSize: 28),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: AppTypography.hero.copyWith(fontSize: 28, color: AppColors.textPrimary),
                  hintText: '0.00',
                  hintStyle: AppTypography.hero.copyWith(fontSize: 28, color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Account Selection
              accountsAsync.when(
                loading: () => const ShimmerBox(width: double.infinity, height: 80),
                error: (err, _) => Text('Error loading accounts: $err', style: AppTypography.bodySmall),
                data: (accounts) {
                  if (accounts.length < 2) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('You need at least 2 accounts to make a transfer.', style: AppTypography.bodySmall),
                    );
                  }
                  _fromAccount ??= accounts.first;
                  _toAccount ??= accounts.length > 1 ? accounts[1] : accounts.first;

                  return Column(
                    children: [
                      // From Account Dropdown
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FROM', style: AppTypography.caption),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _fromAccount?.id,
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
                                  items: accounts.map((acc) => DropdownMenuItem(
                                    value: acc.id,
                                    child: Text(acc.name, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                                  )).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _fromAccount = accounts.firstWhere((a) => a.id == val);
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
                                const Text('TO', style: AppTypography.caption),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _toAccount?.id,
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
                                  items: accounts.map((acc) => DropdownMenuItem(
                                    value: acc.id,
                                    child: Text(acc.name, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                                  )).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _toAccount = accounts.firstWhere((a) => a.id == val);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Note Input
              TextField(
                controller: _noteController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Note (Optional)',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.textPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitTransfer,
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
                      : Text('Confirm Transfer', style: AppTypography.labelLarge.copyWith(color: AppColors.surface)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
