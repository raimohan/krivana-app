import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/project_model.dart';

abstract class ProjectRepository {
  static Box get _box => Hive.box(AppConstants.hiveProjectsBox);

  static List<ProjectModel> loadProjects() {
    final raw = _box.values.toList();
    return raw
        .whereType<Map>()
        .map((entry) =>
            ProjectModel.fromJson(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return (b.updatedAt ?? DateTime(2000))
            .compareTo(a.updatedAt ?? DateTime(2000));
      });
  }

  static ProjectModel? findById(String projectId) {
    final raw = _box.get(projectId);
    if (raw is! Map) return null;
    return ProjectModel.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<void> saveProject(ProjectModel project) async {
    await _box.put(project.id, project.toJson());
  }

  static Future<void> renameProject(String projectId, String name) async {
    final project = findById(projectId);
    if (project == null) return;
    await saveProject(
      project.copyWith(
        name: name,
        updatedAt: DateTime.now(),
      ),
    );
  }

  static Future<void> togglePin(String projectId) async {
    final project = findById(projectId);
    if (project == null) return;
    await saveProject(
      project.copyWith(
        isPinned: !project.isPinned,
        updatedAt: DateTime.now(),
      ),
    );
  }

  static Future<void> deleteProject(String projectId) async {
    await _box.delete(projectId);
  }
}