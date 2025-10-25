import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/project_list_controller.dart';
import '../models/project.dart';

class ProjectListScreen extends StatelessWidget {
  final ProjectListController controller = Get.put(ProjectListController());

  ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Meus Projetos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: controller.showCreateProjectDialog,
            tooltip: 'Novo projeto',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Carregando projetos...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (!controller.hasProjects) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum projeto encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie seu primeiro projeto para começar',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: controller.showCreateProjectDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Projeto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshProjects,
          child: CustomScrollView(
            slivers: [
              // Seção de projetos recentes
              if (controller.recentProjects.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Projetos Recentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.recentProjects.length,
                      itemBuilder: (context, index) {
                        final project = controller.recentProjects[index];
                        return _buildRecentProjectCard(project);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // Cabeçalho da lista de todos os projetos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Todos os Projetos (${controller.projectsCount})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: controller.showCreateProjectDialog,
                        tooltip: 'Novo projeto',
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de todos os projetos
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final project = controller.projects[index];
                  return _buildProjectListItem(project);
                }, childCount: controller.projects.length),
              ),

              // Espaçamento no final
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.showCreateProjectDialog,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Projeto'),
      ),
    );
  }

  Widget _buildRecentProjectCard(Project project) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => controller.openProject(project),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Modificado em ${_formatDate(project.lastModified)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (project.hasOverlayImage)
                  Row(
                    children: [
                      Icon(Icons.image, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Com imagem',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectListItem(Project project) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.camera_alt, color: Colors.blue[700]),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Criado em ${_formatDate(project.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Modificado em ${_formatDate(project.lastModified)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (project.hasOverlayImage) ...[
                  Icon(Icons.image, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${project.overlayImagePaths.length} imagem${project.overlayImagePaths.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  project.showOverlayImage
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 14,
                  color: project.showOverlayImage ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  project.showOverlayImage ? 'Visível' : 'Oculto',
                  style: TextStyle(
                    fontSize: 11,
                    color: project.showOverlayImage ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, project),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: ListTile(
                leading: Icon(Icons.open_in_new),
                title: Text('Abrir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Duplicar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Renomear'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Excluir', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => controller.openProject(project),
      ),
    );
  }

  void _handleMenuAction(String action, Project project) {
    switch (action) {
      case 'open':
        controller.openProject(project);
        break;
      case 'duplicate':
        controller.duplicateProject(project);
        break;
      case 'rename':
        controller.renameProject(project);
        break;
      case 'delete':
        controller.deleteProject(project);
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}
