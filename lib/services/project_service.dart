import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class ProjectService {
  static const String _projectsKey = 'projects_list';
  static const String _lastProjectKey = 'last_project_id';

  // Singleton pattern
  static final ProjectService _instance = ProjectService._internal();
  factory ProjectService() => _instance;
  ProjectService._internal();

  SharedPreferences? _prefs;

  // Inicializa o SharedPreferences
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Garante que o SharedPreferences está inicializado
  Future<SharedPreferences> get prefs async {
    await initialize();
    return _prefs!;
  }

  // Carrega todos os projetos
  Future<List<Project>> loadAllProjects() async {
    try {
      final prefsInstance = await prefs;
      final projectsJson = prefsInstance.getStringList(_projectsKey) ?? [];

      return projectsJson
          .map((projectJson) => Project.fromJson(projectJson))
          .toList()
        ..sort(
          (a, b) => b.lastModified.compareTo(a.lastModified),
        ); // Ordena por última modificação
    } catch (e) {
      print('Erro ao carregar projetos: $e');
      return [];
    }
  }

  // Salva um projeto (novo ou atualização)
  Future<bool> saveProject(Project project) async {
    try {
      final projects = await loadAllProjects();

      // Remove projeto existente se houver
      projects.removeWhere((p) => p.id == project.id);

      // Adiciona o projeto atualizado
      projects.add(project);

      // Salva a lista atualizada
      return await _saveProjectsList(projects);
    } catch (e) {
      print('Erro ao salvar projeto: $e');
      return false;
    }
  }

  // Cria um novo projeto
  Future<Project?> createProject(String name) async {
    try {
      if (name.trim().isEmpty) {
        return null;
      }

      final project = Project.create(name.trim());
      final success = await saveProject(project);

      if (success) {
        await setLastProjectId(project.id);
        return project;
      }
      return null;
    } catch (e) {
      print('Erro ao criar projeto: $e');
      return null;
    }
  }

  // Carrega um projeto específico por ID
  Future<Project?> loadProject(String projectId) async {
    try {
      final projects = await loadAllProjects();
      return projects.where((p) => p.id == projectId).firstOrNull;
    } catch (e) {
      print('Erro ao carregar projeto $projectId: $e');
      return null;
    }
  }

  // Deleta um projeto
  Future<bool> deleteProject(String projectId) async {
    try {
      final projects = await loadAllProjects();
      final initialLength = projects.length;

      projects.removeWhere((p) => p.id == projectId);

      // Se removeu algum projeto, salva a lista atualizada
      if (projects.length < initialLength) {
        // Se era o último projeto usado, limpa a referência
        final lastProjectId = await getLastProjectId();
        if (lastProjectId == projectId) {
          await clearLastProjectId();
        }

        return await _saveProjectsList(projects);
      }

      return false; // Projeto não encontrado
    } catch (e) {
      print('Erro ao deletar projeto: $e');
      return false;
    }
  }

  // Duplica um projeto
  Future<Project?> duplicateProject(String projectId) async {
    try {
      final originalProject = await loadProject(projectId);
      if (originalProject == null) return null;

      final duplicatedProject = originalProject.copyWith(
        id: Project.generateId(),
        name: '${originalProject.name} (Cópia)',
      );

      final success = await saveProject(duplicatedProject);
      return success ? duplicatedProject : null;
    } catch (e) {
      print('Erro ao duplicar projeto: $e');
      return null;
    }
  }

  // Renomeia um projeto
  Future<bool> renameProject(String projectId, String newName) async {
    try {
      if (newName.trim().isEmpty) return false;

      final project = await loadProject(projectId);
      if (project == null) return false;

      final updatedProject = project.copyWith(name: newName.trim());
      return await saveProject(updatedProject);
    } catch (e) {
      print('Erro ao renomear projeto: $e');
      return false;
    }
  }

  // Atualiza as configurações de um projeto
  Future<bool> updateProjectSettings(Project project) async {
    return await saveProject(project);
  }

  // Salva a lista de projetos no SharedPreferences
  Future<bool> _saveProjectsList(List<Project> projects) async {
    try {
      final prefsInstance = await prefs;
      final projectsJson = projects.map((p) => p.toJson()).toList();
      return await prefsInstance.setStringList(_projectsKey, projectsJson);
    } catch (e) {
      print('Erro ao salvar lista de projetos: $e');
      return false;
    }
  }

  // Gerencia o último projeto usado
  Future<String?> getLastProjectId() async {
    try {
      final prefsInstance = await prefs;
      return prefsInstance.getString(_lastProjectKey);
    } catch (e) {
      print('Erro ao carregar último projeto: $e');
      return null;
    }
  }

  Future<bool> setLastProjectId(String projectId) async {
    try {
      final prefsInstance = await prefs;
      return await prefsInstance.setString(_lastProjectKey, projectId);
    } catch (e) {
      print('Erro ao salvar último projeto: $e');
      return false;
    }
  }

  Future<bool> clearLastProjectId() async {
    try {
      final prefsInstance = await prefs;
      return await prefsInstance.remove(_lastProjectKey);
    } catch (e) {
      print('Erro ao limpar último projeto: $e');
      return false;
    }
  }

  // Carrega o último projeto usado
  Future<Project?> loadLastProject() async {
    try {
      final lastProjectId = await getLastProjectId();
      if (lastProjectId != null) {
        return await loadProject(lastProjectId);
      }
      return null;
    } catch (e) {
      print('Erro ao carregar último projeto: $e');
      return null;
    }
  }

  // Utilitários
  Future<int> getProjectsCount() async {
    final projects = await loadAllProjects();
    return projects.length;
  }

  Future<bool> hasProjects() async {
    final count = await getProjectsCount();
    return count > 0;
  }

  // Limpa todos os dados (útil para testes ou reset)
  Future<bool> clearAllData() async {
    try {
      final prefsInstance = await prefs;
      await prefsInstance.remove(_projectsKey);
      await prefsInstance.remove(_lastProjectKey);
      return true;
    } catch (e) {
      print('Erro ao limpar todos os dados: $e');
      return false;
    }
  }

  // Exporta todos os projetos como JSON (backup)
  Future<String> exportProjects() async {
    try {
      final projects = await loadAllProjects();
      final exportData = {
        'projects': projects.map((p) => p.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      return json.encode(exportData);
    } catch (e) {
      print('Erro ao exportar projetos: $e');
      return '{}';
    }
  }

  // Importa projetos de JSON (restaurar backup)
  Future<bool> importProjects(String jsonData) async {
    try {
      final data = json.decode(jsonData) as Map<String, dynamic>;
      final projectsData = data['projects'] as List<dynamic>;

      final projects = projectsData
          .map(
            (projectData) =>
                Project.fromMap(projectData as Map<String, dynamic>),
          )
          .toList();

      return await _saveProjectsList(projects);
    } catch (e) {
      print('Erro ao importar projetos: $e');
      return false;
    }
  }
}
