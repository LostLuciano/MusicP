import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/project_repository.dart';
import 'package:flutter_app/models/audio_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProjectRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('add and load projects', () async {
      final repo = ProjectRepository();
      
      final project = AudioProject(
        id: 'p1',
        title: 'Project 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProjectStatus.draft,
        stemStatus: AnalysisStatus.unavailable,
        chordStatus: AnalysisStatus.unavailable,
        beatStatus: AnalysisStatus.unavailable,
      );

      await repo.addProject(project);
      final list = await repo.loadProjects();
      
      expect(list.length, 1);
      expect(list.first.id, 'p1');
      expect(list.first.title, 'Project 1');
    });

    test('update and delete project', () async {
      final repo = ProjectRepository();
      final project = AudioProject(
        id: 'p1',
        title: 'Project 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProjectStatus.draft,
        stemStatus: AnalysisStatus.unavailable,
        chordStatus: AnalysisStatus.unavailable,
        beatStatus: AnalysisStatus.unavailable,
      );

      await repo.addProject(project);
      
      final updated = project.copyWith(title: 'Project Updated');
      await repo.updateProject(updated);
      
      var list = await repo.loadProjects();
      expect(list.first.title, 'Project Updated');
      
      await repo.deleteProject('p1');
      list = await repo.loadProjects();
      expect(list.isEmpty, true);
    });
  });
}
