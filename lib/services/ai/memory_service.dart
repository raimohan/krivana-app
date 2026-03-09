import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

class MemoryService {
  MemoryService._();
  static final instance = MemoryService._();

  Box<dynamic> get _box => Hive.box(AppConstants.hiveSettingsBox);

  Future<void> savePlanningMemory(String description) async {
    await _box.put('planning_memory', description);
  }

  String? getPlanningMemory() {
    return _box.get('planning_memory') as String?;
  }

  Future<void> saveProjectMemory(
      String projectId, String description) async {
    await _box.put('project_memory_$projectId', description);
  }

  String? getProjectMemory(String projectId) {
    return _box.get('project_memory_$projectId') as String?;
  }
}
