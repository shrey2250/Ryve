import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recurring_bill_repository_impl.dart';
import '../../domain/entities/recurring_bill.dart';
import '../../domain/repositories/recurring_bill_repository.dart';
import 'database_providers.dart';

final recurringBillRepositoryProvider = Provider<RecurringBillRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RecurringBillRepositoryImpl(db);
});

final allRecurringBillsProvider = StreamProvider<List<RecurringBill>>((ref) {
  final repo = ref.watch(recurringBillRepositoryProvider);
  return repo.watchRecurringBills();
});

/// Reactive stream of active recurring subscriptions and bills
final activeRecurringBillsProvider = Provider<AsyncValue<List<RecurringBill>>>((ref) {
  final allAsync = ref.watch(allRecurringBillsProvider);
  return allAsync.whenData((bills) => bills.where((b) => b.isActive).toList());
});

/// Total monthly normalized committed spend (in paise)
final totalMonthlyCommittedPaiseProvider = Provider<AsyncValue<int>>((ref) {
  final activeAsync = ref.watch(activeRecurringBillsProvider);
  return activeAsync.whenData((bills) {
    return bills.fold<int>(0, (sum, bill) => sum + bill.monthlyNormalizedPaise);
  });
});

/// Upcoming bills due within the next 30 days
final upcomingBillsProvider = Provider<AsyncValue<List<RecurringBill>>>((ref) {
  final activeAsync = ref.watch(activeRecurringBillsProvider);
  return activeAsync.whenData((bills) {
    final list = bills.where((b) => b.daysUntilDue >= 0 && b.daysUntilDue <= 30).toList();
    list.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return list;
  });
});
