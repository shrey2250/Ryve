import '../entities/iou.dart';
import '../entities/person.dart';

abstract class IouRepository {
  Future<List<Person>> getPeople();
  Future<Person?> getPersonById(String id);
  Future<Person> createPerson(String name);

  Future<List<IouRecord>> getIouRecords({IouType? type, IouStatus? status, String? personId});
  Future<IouRecord?> getIouById(String id);
  Future<IouRecord> createIou(IouRecord iou);
  Future<void> updateIou(IouRecord iou);
  Future<void> deleteIou(String id);

  Future<IouRepayment> addRepayment({
    required String iouId,
    required int amountPaise,
    required DateTime date,
    String? note,
  });

  Future<IouSummary> getIouSummary();
  Stream<IouSummary> watchIouSummary();
  Stream<List<IouRecord>> watchIous({IouType? type});
  void notifyListeners();
}
