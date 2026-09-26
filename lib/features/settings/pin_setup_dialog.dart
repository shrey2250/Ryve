import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class PinSetupDialog extends ConsumerStatefulWidget {
  const PinSetupDialog({super.key});

  @override
  ConsumerState<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends ConsumerState<PinSetupDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      if (key == '⌫') {
        if (_isConfirming) {
          if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (!_isConfirming) {
          if (_pin.length < 4) {
            _pin += key;
            if (_pin.length == 4) {
              _isConfirming = true;
            }
          }
        } else {
          if (_confirmPin.length < 4) {
            _confirmPin += key;
            if (_confirmPin.length == 4) {
              _validateAndSave();
            }
          }
        }
      }
    });
  }

  Future<void> _validateAndSave() async {
    if (_pin != _confirmPin) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setPinHash(_pin);
    await repo.setAppLockEnabled(true);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = _isConfirming ? _confirmPin : _pin;

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
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _isConfirming ? 'Confirm 4-Digit PIN' : 'Set Up App Lock PIN',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                _isConfirming
                    ? 'Re-enter your 4-digit PIN to confirm'
                    : 'Enter a 4-digit PIN to secure your RYVE Money OS',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // PIN Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < currentCode.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.textPrimary : AppColors.surfaceElevated,
                      border: Border.all(
                        color: isFilled ? AppColors.textPrimary : AppColors.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_errorMessage!, style: AppTypography.caption.copyWith(color: AppColors.expense)),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Keypad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    _buildNumpadRow(['1', '2', '3']),
                    _buildNumpadRow(['4', '5', '6']),
                    _buildNumpadRow(['7', '8', '9']),
                    _buildNumpadRow(['', '0', '⌫']),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildNumpadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((k) {
          if (k.isEmpty) {
            return const Expanded(child: SizedBox.shrink());
          }
          return Expanded(
            child: InkWell(
              onTap: () => _onKeyTap(k),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  k,
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
