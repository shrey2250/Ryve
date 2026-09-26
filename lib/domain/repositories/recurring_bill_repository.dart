import '../entities/recurring_bill.dart';

abstract class RecurringBillRepository {
  void notifyListeners();
  Stream<List<RecurringBill>> watchRecurringBills();
  Future<List<RecurringBill>> getRecurringBills();
  Future<RecurringBill?> getRecurringBillById(String id);
  Future<RecurringBill> createRecurringBill(RecurringBill bill);
  Future<void> updateRecurringBill(RecurringBill bill);
  Future<void> deleteRecurringBill(String id);
  Future<void> toggleActive(String id, bool isActive);
}
