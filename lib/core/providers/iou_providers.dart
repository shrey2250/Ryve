import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/iou_repository_impl.dart';
import '../../domain/entities/iou.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/iou_repository.dart';
import 'database_providers.dart';

final iouRepositoryProvider = Provider<IouRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return IouRepositoryImpl(db);
});

final iouSummaryProvider = StreamProvider<IouSummary>((ref) {
  final repo = ref.watch(iouRepositoryProvider);
  return repo.watchIouSummary();
});

final allIousProvider = StreamProvider<List<IouRecord>>((ref) {
  final repo = ref.watch(iouRepositoryProvider);
  return repo.watchIous();
});

final lentIousProvider = Provider<AsyncValue<List<IouRecord>>>((ref) {
  final allAsync = ref.watch(allIousProvider);
  return allAsync.whenData((list) => list.where((i) => i.type == IouType.lent).toList());
});

final borrowedIousProvider = Provider<AsyncValue<List<IouRecord>>>((ref) {
  final allAsync = ref.watch(allIousProvider);
  return allAsync.whenData((list) => list.where((i) => i.type == IouType.borrowed).toList());
});

final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(iouRepositoryProvider);
  return repo.getPeople();
});

final personByIdProvider = FutureProvider.family<Person?, String>((ref, id) async {
  final repo = ref.watch(iouRepositoryProvider);
  return repo.getPersonById(id);
});
