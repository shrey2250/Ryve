import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import 'database_providers.dart';

/// Account repository provider
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepositoryImpl(db);
});

/// Reactive stream of all non-archived accounts
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAccounts();
});

/// Total balance across all non-archived accounts (in paise) - reactive with accounts stream
final totalBalanceProvider = Provider<AsyncValue<int>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.whenData((accounts) {
    return accounts.fold<int>(0, (sum, acc) => sum + acc.balancePaise);
  });
});

/// Single account by ID
final accountByIdProvider = FutureProvider.family<Account?, String>((ref, id) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.getAccountById(id);
});
