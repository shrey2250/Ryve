import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/account_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/services/backup_restore_service.dart';
import '../../core/services/csv_export_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'pin_setup_dialog.dart';

/// Settings Screen - App Lock, Backup/Restore, CSV Export, Theme, and Currency preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  final List<(String, String)> _currencyOptions = const [
    ('INR', 'Indian Rupee (₹)'),
    ('USD', 'US Dollar (\$)'),
    ('EUR', 'Euro (€)'),
    ('GBP', 'British Pound (£)'),
    ('JPY', 'Japanese Yen (¥)'),
    ('CAD', 'Canadian Dollar (CA\$)'),
    ('AUD', 'Australian Dollar (AU\$)'),
  ];

  Future<void> _toggleAppLock(bool enable) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    if (enable) {
      final success = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        builder: (ctx) => const PinSetupDialog(),
      );
      if (success == true) {
        ref.invalidate(appLockEnabledProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App PIN Lock enabled successfully')),
          );
        }
      }
    } else {
      await settingsRepo.setAppLockEnabled(false);
      await settingsRepo.clearPin();
      ref.invalidate(appLockEnabledProvider);
      ref.invalidate(biometricEnabledProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App Lock disabled')),
        );
      }
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setBiometricEnabled(enable);
    ref.invalidate(biometricEnabledProvider);
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();
    try {
      final txRepo = ref.read(transactionRepositoryProvider);
      await CsvExportService.generateAndShareCsv(txRepo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _backupDatabase() async {
    setState(() => _isBackingUp = true);
    HapticFeedback.lightImpact();
    try {
      final db = DatabaseHelper.instance;
      await BackupRestoreService.createAndShareBackup(db);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error backing up data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreDatabase() async {
    setState(() => _isRestoring = true);
    HapticFeedback.mediumImpact();
    try {
      final db = DatabaseHelper.instance;
      final success = await BackupRestoreService.restoreBackup(db);
      if (success && mounted) {
        ref.invalidate(accountsProvider);
        ref.invalidate(allTransactionsProvider);
        ref.invalidate(totalBalanceProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showCurrencyPicker(String currentCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Select Currency', style: AppTypography.titleLarge),
            ),
            ..._currencyOptions.map((c) => ListTile(
                  title: Text(c.$2, style: AppTypography.bodyMedium),
                  trailing: currentCurrency == c.$1 ? const Icon(Icons.check_rounded, color: AppColors.textPrimary) : null,
                  onTap: () async {
                    await ref.read(settingsRepositoryProvider).setCurrency(c.$1);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLockAsync = ref.watch(appLockEnabledProvider);
    final biometricAsync = ref.watch(biometricEnabledProvider);
    final currencyAsync = ref.watch(currencyProvider);

    final appLockEnabled = appLockAsync.value ?? false;
    final biometricEnabled = biometricAsync.value ?? false;
    final currency = currencyAsync.value ?? 'INR';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Settings', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Security Section
          const Text('SECURITY & LOCK', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('App Lock (PIN)', style: AppTypography.bodyMedium),
                  subtitle: Text('Require 4-digit PIN on launch', style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled)),
                  value: appLockEnabled,
                  activeColor: AppColors.textPrimary,
                  onChanged: (val) => _toggleAppLock(val),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                SwitchListTile(
                  title: const Text('Biometric Authentication', style: AppTypography.bodyMedium),
                  subtitle: Text('Fingerprint / Face ID unlock', style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled)),
                  value: biometricEnabled,
                  activeColor: AppColors.textPrimary,
                  onChanged: appLockEnabled ? (val) => _toggleBiometrics(val) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Data Management Section
          const Text('DATA PORTABILITY & BACKUP', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _isExporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.table_chart_outlined, color: AppColors.textPrimary),
                  title: const Text('Export CSV Statement', style: AppTypography.bodyMedium),
                  subtitle: Text('Share clean transaction history spreadsheet', style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled)),
                  onTap: _isExporting ? null : _exportCsv,
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  leading: _isBackingUp
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined, color: AppColors.textPrimary),
                  title: const Text('Export Database Backup', style: AppTypography.bodyMedium),
                  subtitle: Text('Generate encrypted .ryve backup archive', style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled)),
                  onTap: _isBackingUp ? null : _backupDatabase,
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  leading: _isRestoring
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_download_outlined, color: AppColors.textPrimary),
                  title: const Text('Restore from Backup', style: AppTypography.bodyMedium),
                  subtitle: Text('Restore database from a saved file', style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled)),
                  onTap: _isRestoring ? null : _restoreDatabase,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Preferences Section
          const Text('PREFERENCES', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.textPrimary),
                  title: const Text('Primary Currency', style: AppTypography.bodyMedium),
                  trailing: Text(
                    currency,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showCurrencyPicker(currency),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.textPrimary),
                  title: const Text('Design Theme', style: AppTypography.bodyMedium),
                  trailing: Text('Silent Wealth (Off-White)', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // About Section
          Center(
            child: Column(
              children: [
                Text('RYVE Personal Money OS', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Version 1.0.0 (Build 100) • Integer Precision', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
