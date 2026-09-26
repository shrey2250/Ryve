import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import 'database_providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepositoryImpl(db);
});

final currencyProvider = StreamProvider<String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchCurrency();
});

final appLockEnabledProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.isAppLockEnabled();
});

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.isBiometricEnabled();
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.isOnboardingComplete();
});

/// In-memory reactive privacy shield provider (toggles masking of balances across the app)
final privacyModeProvider = StateProvider<bool>((ref) => false);

