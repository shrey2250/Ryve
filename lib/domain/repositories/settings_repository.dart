abstract class SettingsRepository {
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<String> getCurrency();
  Future<void> setCurrency(String currency);
  Future<bool> isAppLockEnabled();
  Future<void> setAppLockEnabled(bool enabled);
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete(bool complete);
  Future<String?> getPinHash();
  Future<void> setPinHash(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();
  Stream<String> watchCurrency();
}
