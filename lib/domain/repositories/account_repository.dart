import '../entities/account.dart';

/// Repository interface for account operations.
/// Implementations live in data/repositories/account_repository_impl.dart.
abstract class AccountRepository {
  /// All non-archived accounts, ordered by creation date.
  Future<List<Account>> getAccounts();

  /// Watch accounts (reactive stream).
  Stream<List<Account>> watchAccounts();

  /// Get a single account by ID.
  Future<Account?> getAccountById(String id);

  /// Create a new account. Returns the created account.
  Future<Account> createAccount(Account account);

  /// Update an existing account.
  Future<void> updateAccount(Account account);

  /// Archive an account (soft-delete equivalent for accounts).
  Future<void> archiveAccount(String id);

  /// Recalculate account balance from transaction history.
  /// Call after a restore or data integrity check.
  Future<int> recalculateBalance(String accountId);

  /// Sum of all non-archived account balances.
  Future<int> getTotalBalancePaise();

  /// Notify reactive streams that account balances have changed
  void notifyListeners();
}
