import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/creation_folder.dart';
import 'package:voxbox/services/creation_folder_service.dart';
import 'package:voxbox/view/creations/folder_detail_screen.dart';
import 'package:voxbox/view/creations/create_folder_dialog.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final CreationFolderService _folderService = CreationFolderService();
  List<CreationFolder> _folders = [];
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final folders = await _folderService.getFolders();
      final stats = await _folderService.getGlobalStats();
      
      setState(() {
        _folders = folders;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des dossiers');
    }
  }

  Future<void> _createFolder() async {
    final result = await showDialog<CreationFolder>(
      context: context,
      builder: (context) => const CreateFolderDialog(),
    );

    if (result != null) {
      await _loadFolders();
      _showSuccessSnackBar('Dossier créé avec succès');
    }
  }

  Future<void> _deleteFolder(CreationFolder folder) async {
    final confirmed = await _showDeleteConfirmation(folder.name);
    if (confirmed) {
      final success = await _folderService.deleteFolder(folder.id);
      if (success) {
        await _loadFolders();
        _showSuccessSnackBar('Dossier supprimé');
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String folderName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le dossier'),
        content: Text('Êtes-vous sûr de vouloir supprimer le dossier "$folderName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(
          text: "Mes Dossiers",
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createFolder,
            tooltip: 'Créer un dossier',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques
                _buildStatsCard(),
                
                // Liste des dossiers
                Expanded(
                  child: _folders.isEmpty
                      ? _buildEmptyState()
                      : _buildFoldersList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstance.primary, AppConstance.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppConstance.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Dossiers', _stats['folders'] ?? 0, Icons.folder),
          _buildStatItem('Éléments', _stats['items'] ?? 0, Icons.description),
          _buildStatItem('Audio', _stats['audio'] ?? 0, Icons.audiotrack),
          _buildStatItem('Images', _stats['images'] ?? 0, Icons.image),
          _buildStatItem('Textes', _stats['texts'] ?? 0, Icons.text_fields),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun dossier créé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier dossier pour organiser vos créations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createFolder,
            icon: const Icon(Icons.add),
            label: const Text('Créer un dossier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return _buildFolderCard(folder);
      },
    );
  }

  Widget _buildFolderCard(CreationFolder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openFolder(folder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône du dossier
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorFromString(folder.color ?? '#2196F3'),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconFromString(folder.icon ?? 'folder'),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations du dossier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (folder.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        folder.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${folder.totalItems} éléments',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (folder.audioCount > 0) ...[
                          Icon(Icons.audiotrack, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${folder.audioCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (folder.imageCount > 0) ...[
                          Icon(Icons.image, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${folder.imageCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (folder.textCount > 0) ...[
                          Icon(Icons.text_fields, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${folder.textCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Menu d'actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteFolder(folder);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFolder(CreationFolder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderDetailScreen(folder: folder),
      ),
    ).then((_) => _loadFolders()); // Recharger après retour
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return AppConstance.primary;
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'folder':
        return Icons.folder;
      case 'music':
        return Icons.music_note;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_fields;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.folder;
    }
  }
}
