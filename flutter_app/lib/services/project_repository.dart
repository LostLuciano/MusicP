import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_project.dart';

class ProjectRepository {
  static const String _storageKey = 'music_stem_studio_projects';

  Future<List<AudioProject>> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString == null) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => AudioProject.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveProjects(List<AudioProject> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(
        projects.map((proj) => proj.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (_) {}
  }

  Future<void> addProject(AudioProject project) async {
    final List<AudioProject> projects = await loadProjects();
    projects.add(project);
    await saveProjects(projects);
  }

  Future<void> updateProject(AudioProject project) async {
    final List<AudioProject> projects = await loadProjects();
    final int index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      await saveProjects(projects);
    }
  }

  Future<void> deleteProject(String projectId) async {
    final List<AudioProject> projects = await loadProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
  }

  Future<AudioProject?> getProjectById(String projectId) async {
    final List<AudioProject> projects = await loadProjects();
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      return projects[index];
    }
    return null;
  }
}
