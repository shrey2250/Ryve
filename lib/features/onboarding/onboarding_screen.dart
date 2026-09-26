import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/account.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _selectedCurrency = 'INR';
  final TextEditingController _cashBalanceController = TextEditingController();
  final TextEditingController _bankBalanceController = TextEditingController();
  bool _isFinalizing = false;

  final List<(String, String, String)> _currencies = const [
    ('INR', 'Indian Rupee', '₹'),
    ('USD', 'US Dollar', '\$'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound', '£'),
    ('JPY', 'Japanese Yen', '¥'),
    ('CAD', 'Canadian Dollar', 'CA\$'),
    ('AUD', 'Australian Dollar', 'AU\$'),
    ('AED', 'UAE Dirham', 'AED'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _cashBalanceController.dispose();
    _bankBalanceController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isFinalizing = true);
    HapticFeedback.mediumImpact();

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final accountRepo = ref.read(accountRepositoryProvider);

      await settingsRepo.setCurrency(_selectedCurrency);
      await settingsRepo.setOnboardingComplete(true);

      // Create initial accounts if cash/bank balances were specified
      final cashPaise = CurrencyFormatter.parseToPaise(_cashBalanceController.text) ?? 0;
      final bankPaise = CurrencyFormatter.parseToPaise(_bankBalanceController.text) ?? 0;

      final existingAccounts = await accountRepo.getAccounts();
      if (existingAccounts.isNotEmpty) {
        // Update default cash account balance
        final cashAcc = existingAccounts.firstWhere(
          (a) => a.type == AccountType.cash,
          orElse: () => existingAccounts.first,
        );
        if (cashPaise > 0) {
          await accountRepo.updateAccount(cashAcc.copyWith(balancePaise: cashPaise));
        }

        // Create Bank account
        if (bankPaise > 0) {
          final now = DateTime.now();
          await accountRepo.createAccount(Account(
            id: 'acc_bank_primary',
            name: 'Primary Bank',
            type: AccountType.bank,
            balancePaise: bankPaise,
            currency: _selectedCurrency,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFinalizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing onboarding: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Page Indicator Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isCurrent = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 24 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.textPrimary : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildIntroStep(),
                  _buildCurrencyStep(),
                  _buildAccountsStep(),
                ],
              ),
            ),

            // Navigation Bottom Controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isFinalizing ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    elevation: 0,
                  ),
                  child: _isFinalizing
                      ? const CircularProgressIndicator(color: AppColors.surface)
                      : Text(
                          _currentPage == 2 ? 'Get Started' : 'Continue',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.surface),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.shadowSm,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, size: 36, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('RYVE', style: AppTypography.hero.copyWith(letterSpacing: 4.0, fontSize: 32)),
          const SizedBox(height: AppSpacing.xs),
          Text('Silent Wealth Architecture', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xl),

          // Privacy Trust Guarantee Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '100% Local-First & Private',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your financial data is encrypted and stays strictly on your device. Zero cloud sync, zero telemetry, zero trackers.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Calm personal money OS engineered with atomic accuracy, group splits, and intelligent bills radar.',
            style: AppTypography.caption.copyWith(color: AppColors.textDisabled, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Text('Select Primary Currency', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text('All net worth calculations will default to this currency.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: _currencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = _currencies[index];
                final isSelected = _selectedCurrency == c.$1;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCurrency = c.$1);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected ? AppColors.textPrimary : AppColors.borderSubtle,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(c.$3, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.$1, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                              Text(c.$2, style: AppTypography.caption.copyWith(color: AppColors.textDisabled)),
                            ],
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.textPrimary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Text('Initial Balances', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text('Enter your current cash and primary bank balances.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),

          // Cash Account
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text('Cash Balance', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cashBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.titleLarge,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    hintText: '0.00',
                    hintStyle: AppTypography.titleLarge.copyWith(color: AppColors.textDisabled),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Bank Account
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text('Bank Balance', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bankBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.titleLarge,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    hintText: '0.00',
                    hintStyle: AppTypography.titleLarge.copyWith(color: AppColors.textDisabled),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
