import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../presentation/widgets/shared_widgets.dart';

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _errorMessage;
  final LocalAuthentication _localAuth = LocalAuthentication();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );
    _checkBiometrics();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isBioEnabled = await ref.read(settingsRepositoryProvider).isBiometricEnabled();
      if (!isBioEnabled) return;

      final canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access RYVE Money OS',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );
        if (authenticated) {
          HapticFeedback.mediumImpact();
          widget.onUnlocked();
        }
      }
    } catch (_) {}
  }

  void _onKeyTap(String key) {
    setState(() {
      _errorMessage = null;
      if (key == '⌫') {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else if (key == 'bio') {
        _checkBiometrics();
      } else {
        if (_enteredPin.length < 4) {
          _enteredPin += key;
          if (_enteredPin.length == 4) {
            _verifyPin();
          }
        }
      }
    });
  }

  Future<void> _verifyPin() async {
    final repo = ref.read(settingsRepositoryProvider);
    final isValid = await repo.verifyPin(_enteredPin);

    if (isValid) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = 'Incorrect PIN';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Logo Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.textPrimary, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('RYVE', style: AppTypography.titleLarge.copyWith(letterSpacing: 3.0)),
            const SizedBox(height: 4),
            Text('Enter your 4-digit PIN', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),

            // PIN Dots Indicator with Shake Animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = math.sin(_shakeAnimation.value * math.pi * 6) * 12 * (1 - _shakeAnimation.value);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
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
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_errorMessage!, style: AppTypography.caption.copyWith(color: AppColors.expense)),
            ],

            const Spacer(),

            // Keypad with Tactile Spring Keys
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Column(
                children: [
                  _buildNumpadRow(['1', '2', '3']),
                  _buildNumpadRow(['4', '5', '6']),
                  _buildNumpadRow(['7', '8', '9']),
                  _buildNumpadRow(['bio', '0', '⌫']),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((k) {
          if (k == 'bio') {
            return RyveNumpadKey(
              label: '',
              icon: const Icon(Icons.fingerprint_rounded, size: 24, color: AppColors.textPrimary),
              onTap: () => _onKeyTap(k),
            );
          }
          if (k == '⌫') {
            return RyveNumpadKey(
              label: '',
              icon: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.textPrimary),
              onTap: () => _onKeyTap(k),
            );
          }
          return RyveNumpadKey(
            label: k,
            onTap: () => _onKeyTap(k),
          );
        }).toList(),
      ),
    );
  }
}
