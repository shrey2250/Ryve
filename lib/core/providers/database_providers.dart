import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';

/// Provides the singleton DatabaseHelper instance.
/// All repository providers depend on this.
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});
