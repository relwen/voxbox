import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/creation_folder.dart';
import 'package:voxbox/models/creation_item.dart';
import 'package:voxbox/services/creation_folder_service.dart';
import 'package:voxbox/view/creations/add_item_dialog.dart';

class FolderDetailScreen extends StatefulWidget {
  final CreationFolder folder;

  const FolderDetailScreen({
    super.key,
    required this.folder,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final CreationFolderService _folderService = CreationFolderService();
  late CreationFolder _currentFolder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentFolder = widget.folder;
  }

  Future<void> _refreshFolder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final folders = await _folderService.getFolders();
      final updatedFolder = folders.firstWhere(
        (folder) => folder.id == _currentFolder.id,
        orElse: () => _currentFolder,
      );
      
      setState(() {
        _currentFolder = updatedFolder;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement');
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<CreationItem>(
      context: context,
      builder: (context) => AddItemDialog(folderId: _currentFolder.id),
    );

    if (result != null) {
      await _refreshFolder();
      _showSuccessSnackBar('Élément ajouté avec succès');
    }
  }

  Future<void> _deleteItem(CreationItem item) async {
    final confirmed = await _showDeleteConfirmation(item.name);
    if (confirmed) {
      final success = await _folderService.removeItemFromFolder(
        _currentFolder.id,
        item.id,
      );
      if (success) {
        await _refreshFolder();
        _showSuccessSnackBar('Élément supprimé');
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String itemName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'élément'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$itemName" ?'),
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
        title: MyText(
          text: _currentFolder.name,
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: _getColorFromString(_currentFolder.color ?? '#2196F3'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addItem,
            tooltip: 'Ajouter un élément',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // En-tête du dossier
                _buildFolderHeader(),
                
                // Liste des éléments
                Expanded(
                  child: _currentFolder.items.isEmpty
                      ? _buildEmptyState()
                      : _buildItemsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFolderHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getColorFromString(_currentFolder.color ?? '#2196F3').withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorFromString(_currentFolder.color ?? '#2196F3').withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Icône du dossier
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getColorFromString(_currentFolder.color ?? '#2196F3'),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconFromString(_currentFolder.icon ?? 'folder'),
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Informations du dossier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentFolder.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentFolder.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentFolder.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentFolder.totalItems} éléments',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    if (_currentFolder.audioCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.audiotrack, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentFolder.audioCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    if (_currentFolder.imageCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentFolder.imageCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    if (_currentFolder.textCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.text_fields, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentFolder.textCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconFromString(_currentFolder.icon ?? 'folder'),
            size: 80,
            color: _getColorFromString(_currentFolder.color ?? '#2196F3').withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Dossier vide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier élément à ce dossier',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un élément'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getColorFromString(_currentFolder.color ?? '#2196F3'),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentFolder.items.length,
      itemBuilder: (context, index) {
        final item = _currentFolder.items[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(CreationItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône de l'élément
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getItemColor(item.type),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getItemIcon(item.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations de l'élément
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          item.typeDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (item.type == CreationType.audio && item.duration != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                item.formattedDuration,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        if (item.fileSize != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storage, size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                item.formattedFileSize,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Menu d'actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteItem(item);
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

  void _openItem(CreationItem item) {
    // TODO: Implémenter l'ouverture des éléments selon leur type
    switch (item.type) {
      case CreationType.audio:
        _showErrorSnackBar('Lecteur audio en cours de développement');
        break;
      case CreationType.image:
        _showErrorSnackBar('Visionneuse d\'images en cours de développement');
        break;
      case CreationType.text:
        _showErrorSnackBar('Éditeur de texte en cours de développement');
        break;
    }
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

  Color _getItemColor(CreationType type) {
    switch (type) {
      case CreationType.audio:
        return AppConstance.primary;
      case CreationType.image:
        return AppConstance.secondary;
      case CreationType.text:
        return AppConstance.accent;
    }
  }

  IconData _getItemIcon(CreationType type) {
    switch (type) {
      case CreationType.audio:
        return Icons.audiotrack;
      case CreationType.image:
        return Icons.image;
      case CreationType.text:
        return Icons.text_fields;
    }
  }
}
