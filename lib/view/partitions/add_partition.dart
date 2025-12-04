import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/services/partition_service.dart';
import 'package:voxbox/services/category_service.dart';
import 'package:voxbox/services/file_upload_service.dart';
import 'package:voxbox/models/category.dart';
import 'package:voxbox/widgets/widgets.dart';

class AddPartitionScreen extends StatefulWidget {
  const AddPartitionScreen({Key? key}) : super(key: key);

  @override
  _AddPartitionScreenState createState() => _AddPartitionScreenState();
}

class _AddPartitionScreenState extends State<AddPartitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int _selectedCategoryId = 1;
  int _selectedChoraleId = 1;
  File? _selectedAudioFile;
  File? _selectedPdfFile;
  File? _selectedImageFile;
  bool _isLoading = false;
  List<Category> _categories = [];
  List<Map<String, dynamic>> _chorales = [
    
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    try {
      var response = await CategoryService.getCategories();
      if (response.error == null) {
        setState(() {
          _categories = response.data as List<Category>;
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: "Ajouter une Partition",
          size: 20,
          color: Colors.white,
          fontweight: FontWeight.w800,
        ),
        foregroundColor: Colors.white,
        backgroundColor: theme,
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informations de base
              _buildSectionTitle('Informations de base'),
              SizedBox(height: 16),
              
              // Titre
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de la partition',
                  hintText: 'Ex: Ave Maria - Schubert',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.music_note),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Description de la partition...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              
              SizedBox(height: 24),
              
              // Catégorie
              _buildSectionTitle('Catégorie'),
              SizedBox(height: 16),
              
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Row(
                      children: [
                        if (category.icon != null) ...[
                          Icon(
                            _getIconData(category.icon!),
                            size: 20,
                            color: _getColorFromHex(category.color),
                          ),
                          SizedBox(width: 8),
                        ],
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value!;
                  });
                },
              ),
              
              SizedBox(height: 16),
              
              // Chorale
              _buildSectionTitle('Chorale'),
              SizedBox(height: 16),
              
              DropdownButtonFormField<int>(
                value: _selectedChoraleId,
                decoration: InputDecoration(
                  labelText: 'Chorale',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.group),
                ),
                items: _chorales.map((chorale) {
                  return DropdownMenuItem<int>(
                    value: chorale['id'],
                    child: Text(chorale['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedChoraleId = value!;
                  });
                },
              ),
              
              SizedBox(height: 24),
              
              // Fichiers
              _buildSectionTitle('Fichiers (au moins un requis)'),
              SizedBox(height: 16),
              
              // Fichier audio
              _buildFileSelector(
                'Fichier Audio',
                Icons.audio_file,
                _selectedAudioFile,
                'Sélectionner un fichier audio',
                _selectAudioFile,
                'Formats: MP3, WAV, OGG, M4A (max 10MB)',
              ),
              
              SizedBox(height: 16),
              
              // Fichier PDF
              _buildFileSelector(
                'Fichier PDF',
                Icons.picture_as_pdf,
                _selectedPdfFile,
                'Sélectionner un fichier PDF',
                _selectPdfFile,
                'Format: PDF (max 20MB)',
              ),
              
              SizedBox(height: 16),
              
              // Image
              _buildFileSelector(
                'Image',
                Icons.image,
                _selectedImageFile,
                'Sélectionner une image',
                _selectImageFile,
                'Formats: JPG, PNG, GIF (max 5MB)',
              ),
              
              SizedBox(height: 24),
              
              // Indicateur de validation
              if (!_hasAtLeastOneFile())
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Au moins un fichier (audio, PDF ou image) est requis',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 32),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _cancel,
                      child: Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppConstance.primary),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading || !_hasAtLeastOneFile() ? null : _savePartition,
                      child: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Sauvegarder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstance.primary,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppConstance.primary,
      ),
    );
  }

  Widget _buildFileSelector(
    String title,
    IconData icon,
    File? selectedFile,
    String buttonText,
    VoidCallback onPressed,
    String hint,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: selectedFile != null ? AppConstance.primary : Colors.grey,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selectedFile != null ? AppConstance.primary : Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            selectedFile != null 
                ? 'Fichier sélectionné: ${selectedFile.path.split('/').last}'
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: selectedFile != null ? AppConstance.primary : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(Icons.upload_file),
            label: Text(selectedFile != null ? 'Changer le fichier' : buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _hasAtLeastOneFile() {
    return _selectedAudioFile != null || 
           _selectedPdfFile != null || 
           _selectedImageFile != null;
  }

  Future<void> _selectAudioFile() async {
    try {
      File? selectedFile = await FileUploadService.selectAudioFile();
      
      if (selectedFile != null) {
        setState(() {
          _selectedAudioFile = selectedFile;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier audio sélectionné: ${FileUploadService.getFileName(selectedFile.path)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectPdfFile() async {
    try {
      File? selectedFile = await FileUploadService.selectPdfFile();
      
      if (selectedFile != null) {
        setState(() {
          _selectedPdfFile = selectedFile;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier PDF sélectionné: ${FileUploadService.getFileName(selectedFile.path)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectImageFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Future<void> _savePartition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasAtLeastOneFile()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner au moins un fichier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer la partition via le service
      final response = await PartitionService.createPartition(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId,
        choraleId: _selectedChoraleId,
        audioFilePath: _selectedAudioFile?.path,
        pdfFilePath: _selectedPdfFile?.path,
        imageFilePath: _selectedImageFile?.path,
      );

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partition créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true); // Retour avec succès
      } else {
        throw Exception(response.error);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Convertir le nom d'icône en IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'church':
        return Icons.church;
      case 'library_music':
        return Icons.library_music;
      case 'favorite':
        return Icons.favorite;
      case 'flag':
        return Icons.flag;
      default:
        return Icons.category;
    }
  }

  // Convertir la couleur hex en Color
  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }
    
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Ajouter l'alpha si absent
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
