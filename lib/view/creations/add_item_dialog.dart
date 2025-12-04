import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/creation_item.dart';
import 'package:voxbox/services/creation_folder_service.dart';
import 'package:voxbox/services/audio_recorder_service.dart';

class AddItemDialog extends StatefulWidget {
  final String folderId;

  const AddItemDialog({
    super.key,
    required this.folderId,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _textController = TextEditingController();
  final CreationFolderService _folderService = CreationFolderService();
  final AudioRecorderService _audioService = AudioRecorderService();
  final ImagePicker _imagePicker = ImagePicker();
  
  CreationType _selectedType = CreationType.text;
  bool _isCreating = false;
  String? _selectedFilePath;
  String? _selectedImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _createItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      CreationItem? item;

      switch (_selectedType) {
        case CreationType.audio:
          if (_selectedFilePath == null) {
            _showErrorSnackBar('Veuillez enregistrer un audio');
            return;
          }
          item = await _folderService.createAudioItem(
            name: _nameController.text.trim(),
            filePath: _selectedFilePath!,
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
          );
          break;

        case CreationType.image:
          if (_selectedImagePath == null) {
            _showErrorSnackBar('Veuillez sélectionner une image');
            return;
          }
          item = await _folderService.createImageItem(
            name: _nameController.text.trim(),
            filePath: _selectedImagePath!,
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
          );
          break;

        case CreationType.text:
          if (_textController.text.trim().isEmpty) {
            _showErrorSnackBar('Veuillez saisir du texte');
            return;
          }
          item = await _folderService.createTextItem(
            name: _nameController.text.trim(),
            content: _textController.text.trim(),
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
          );
          break;
      }

      if (item != null) {
        final success = await _folderService.addItemToFolder(widget.folderId, item);
        if (success) {
          if (mounted) {
            Navigator.of(context).pop(item);
          }
        } else {
          _showErrorSnackBar('Erreur lors de l\'ajout');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la création: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _recordAudio() async {
    try {
      final success = await _audioService.startRecording();
      if (success) {
        _showSuccessSnackBar('Enregistrement démarré');
        
        // Attendre que l'utilisateur arrête l'enregistrement
        final path = await _showRecordingDialog();
        if (path != null) {
          setState(() {
            _selectedFilePath = path;
          });
        }
      } else {
        _showErrorSnackBar('Impossible de démarrer l\'enregistrement');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<String?> _showRecordingDialog() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrement Audio'),
        content: const Text('Appuyez sur "Arrêter" pour terminer l\'enregistrement'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final path = await _audioService.stopRecording();
              Navigator.of(context).pop(path);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Arrêter'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        _showSuccessSnackBar('Image sélectionnée');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorSnackBar('Aucune caméra disponible');
        return;
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _selectedImagePath = photo.path;
        });
        _showSuccessSnackBar('Photo prise');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la prise de photo: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un élément'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type d'élément
              const Text(
                'Type d\'élément',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      CreationType.text,
                      'Texte',
                      Icons.text_fields,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeButton(
                      CreationType.audio,
                      'Audio',
                      Icons.audiotrack,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeButton(
                      CreationType.image,
                      'Image',
                      Icons.image,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Nom
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Entrez le nom de l\'élément',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
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
                  hintText: 'Décrivez l\'élément',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 16),
              
              // Contenu selon le type
              _buildContentSection(),
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
          onPressed: _isCreating ? null : _createItem,
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

  Widget _buildTypeButton(CreationType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedFilePath = null;
          _selectedImagePath = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    switch (_selectedType) {
      case CreationType.text:
        return TextFormField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Contenu',
            hintText: 'Saisissez votre texte',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
        );

      case CreationType.audio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enregistrement Audio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedFilePath == null) ...[
              ElevatedButton.icon(
                onPressed: _recordAudio,
                icon: const Icon(Icons.mic),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audio enregistré',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilePath = null;
                        });
                      },
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case CreationType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedImagePath == null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image sélectionnée',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedImagePath = null;
                        });
                      },
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
    }
  }
}
