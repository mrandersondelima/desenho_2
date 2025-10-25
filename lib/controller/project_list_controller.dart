import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../screens/camera_overlay_screen.dart';

class ProjectListController extends GetxController {
  final ProjectService _projectService = ProjectService();

  // Observable variables
  RxList<Project> projects = <Project>[].obs;
  RxBool isLoading = true.obs;
  RxBool isCreatingProject = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeAndLoadProjects();
  }

  // Inicializa o service e carrega os projetos
  Future<void> initializeAndLoadProjects() async {
    try {
      isLoading.value = true;
      await _projectService.initialize();
      await loadProjects();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao inicializar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Carrega todos os projetos
  Future<void> loadProjects() async {
    try {
      final loadedProjects = await _projectService.loadAllProjects();
      projects.value = loadedProjects;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar projetos: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  // Cria um novo projeto
  Future<void> createProject(String name) async {
    if (name.trim().isEmpty) {
      Get.snackbar(
        'Erro',
        'Nome do projeto não pode estar vazio',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isCreatingProject.value = true;

      final project = await _projectService.createProject(name.trim());
      if (project != null) {
        await loadProjects(); // Recarrega a lista

        Get.snackbar(
          'Sucesso',
          'Projeto "${project.name}" criado com sucesso!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );

        // Navega diretamente para o projeto criado e seleciona imagens
        await openProjectWithImageSelection(project);
      } else {
        Get.snackbar(
          'Erro',
          'Erro ao criar projeto',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao criar projeto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isCreatingProject.value = false;
    }
  }

  // Abre um projeto na tela de câmera
  void openProject(Project project) {
    // Salva como último projeto usado
    _projectService.setLastProjectId(project.id);

    // Navega para a tela de câmera passando o projeto
    Get.to(() => CameraOverlayScreen(project: project))?.then((_) {
      // Quando volta da tela de câmera, recarrega os projetos
      loadProjects();
    });
  }

  // Abre um projeto e solicita seleção de imagens
  Future<void> openProjectWithImageSelection(Project project) async {
    // Primeiro, solicita a seleção de imagens
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        dialogTitle: 'Selecione uma ou mais imagens para o projeto',
      );

      if (result != null && result.files.isNotEmpty) {
        // Se imagens foram selecionadas, salva no projeto
        final imagePaths = result.paths
            .where((path) => path != null)
            .cast<String>()
            .toList();

        if (imagePaths.isNotEmpty) {
          // Atualiza o projeto com as imagens selecionadas
          final updatedProject = project.copyWith(
            overlayImagePaths: imagePaths,
            currentImageIndex: 0,
            lastModified: DateTime.now(),
          );

          // Salva o projeto atualizado
          final success = await _projectService.saveProject(updatedProject);
          if (success) {
            Get.snackbar(
              'Sucesso',
              '${imagePaths.length} imagem(ns) adicionada(s) ao projeto!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withValues(alpha: 0.8),
              colorText: Colors.white,
            );

            // Navega para a tela de câmera com o projeto atualizado
            openProject(updatedProject);
          } else {
            // Se falhou ao salvar, ainda navega mas sem as imagens
            Get.snackbar(
              'Aviso',
              'Erro ao salvar imagens no projeto, mas continuando...',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.withValues(alpha: 0.8),
              colorText: Colors.white,
            );
            openProject(project);
          }
        }
      } else {
        // Se não selecionou imagens, navega normalmente
        Get.snackbar(
          'Informação',
          'Nenhuma imagem selecionada. Você pode adicionar depois.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        openProject(project);
      }
    } catch (e) {
      // Se houve erro na seleção, navega normalmente
      Get.snackbar(
        'Erro',
        'Erro ao selecionar imagens: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      openProject(project);
    }
  }

  // Deleta um projeto
  Future<void> deleteProject(Project project) async {
    // Confirma a exclusão
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o projeto "${project.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _projectService.deleteProject(project.id);
        if (success) {
          await loadProjects(); // Recarrega a lista

          Get.snackbar(
            'Sucesso',
            'Projeto "${project.name}" excluído com sucesso!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Erro',
            'Erro ao excluir projeto',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Erro ao excluir projeto: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Duplica um projeto
  Future<void> duplicateProject(Project project) async {
    try {
      final duplicatedProject = await _projectService.duplicateProject(
        project.id,
      );
      if (duplicatedProject != null) {
        await loadProjects(); // Recarrega a lista

        Get.snackbar(
          'Sucesso',
          'Projeto duplicado como "${duplicatedProject.name}"!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Erro ao duplicar projeto',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao duplicar projeto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  // Renomeia um projeto
  Future<void> renameProject(Project project) async {
    final controller = TextEditingController(text: project.name);

    final newName = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Renomear Projeto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do projeto',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) => Get.back(result: value),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text('Renomear'),
          ),
        ],
      ),
    );

    if (newName != null &&
        newName.trim().isNotEmpty &&
        newName.trim() != project.name) {
      try {
        final success = await _projectService.renameProject(
          project.id,
          newName.trim(),
        );
        if (success) {
          await loadProjects(); // Recarrega a lista

          Get.snackbar(
            'Sucesso',
            'Projeto renomeado para "${newName.trim()}"!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Erro',
            'Erro ao renomear projeto',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Erro ao renomear projeto: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  // Mostra diálogo para criar novo projeto
  void showCreateProjectDialog() {
    final controller = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Novo Projeto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do projeto',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Get.back();
            if (value.trim().isNotEmpty) {
              createProject(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => TextButton(
              onPressed: isCreatingProject.value
                  ? null
                  : () {
                      Get.back();
                      if (controller.text.trim().isNotEmpty) {
                        createProject(controller.text);
                      }
                    },
              child: isCreatingProject.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar'),
            ),
          ),
        ],
      ),
    );
  }

  // Atualiza a lista (pull to refresh)
  Future<void> refreshProjects() async {
    await loadProjects();
  }

  // Carrega e abre o último projeto usado
  Future<void> openLastProject() async {
    try {
      final lastProject = await _projectService.loadLastProject();
      if (lastProject != null) {
        openProject(lastProject);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar último projeto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  // Getters de conveniência
  bool get hasProjects => projects.isNotEmpty;
  int get projectsCount => projects.length;

  List<Project> get recentProjects {
    final sortedProjects = List<Project>.from(projects);
    sortedProjects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return sortedProjects.take(5).toList();
  }
}
