import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/creation_folder_service.dart';

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final CreationFolderService _folderService = CreationFolderService();
  
  String _selectedColor = '#2196F3';
  String _selectedIcon = 'folder';
  bool _isCreating = false;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Bleu', 'value': '#2196F3'},
    {'name': 'Vert', 'value': '#4CAF50'},
    {'name': 'Orange', 'value': '#FF9800'},
    {'name': 'Rouge', 'value': '#F44336'},
    {'name': 'Violet', 'value': '#9C27B0'},
    {'name': 'Rose', 'value': '#E91E63'},
    {'name': 'Indigo', 'value': '#3F51B5'},
    {'name': 'Teal', 'value': '#009688'},
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'Dossier', 'value': 'folder'},
    {'name': 'Musique', 'value': 'music'},
    {'name': 'Image', 'value': 'image'},
    {'name': 'Texte', 'value': 'text'},
    {'name': 'Étoile', 'value': 'star'},
    {'name': 'Cœur', 'value': 'favorite'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final folder = await _folderService.createFolder(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
      );

      if (mounted) {
        Navigator.of(context).pop(folder);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un nouveau dossier'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom du dossier
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du dossier',
                  hintText: 'Entrez le nom du dossier',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  if (value.trim().length < 2) {
                    return 'Le nom doit contenir au moins 2 caractères';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Décrivez le contenu du dossier',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 20),
              
              // Couleur
              const Text(
                'Couleur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color['value'];
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColorFromString(color['value']),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              // Icône
              const Text(
                'Icône',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon['value'];
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? AppConstance.primary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppConstance.primary : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getIconFromString(icon['value']),
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createFolder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstance.primary,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Créer'),
        ),
      ],
    );
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
