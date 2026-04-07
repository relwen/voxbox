import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/models/vocalise_section.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/models/category.dart';
import 'package:voxbox/services/partition_service.dart';
import 'package:voxbox/services/category_service.dart';
import 'package:voxbox/services/chorale_service.dart';
import 'package:voxbox/services/file_upload_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddVocaliseScreen extends StatefulWidget {
  final VocaliseSection section;
  
  const AddVocaliseScreen({Key? key, required this.section}) : super(key: key);

  @override
  _AddVocaliseScreenState createState() => _AddVocaliseScreenState();
}

class _AddVocaliseScreenState extends State<AddVocaliseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int? _selectedPupitreId;
  int? _categoryId;
  int? _choraleId;
  File? _selectedAudioFile;
  bool _isLoading = false;
  bool _loadingData = true;
  List<ChoralePupitre> _pupitres = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
    });

    try {
      // Charger les informations de l'utilisateur
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userString = prefs.getString('user');
      if (userString != null) {
        Map<String, dynamic> userMap = jsonDecode(userString);
        User user = User.fromJson(userMap);
        _choraleId = user.choraleId;

        if (_choraleId != null) {
          // Charger la catégorie "Vocalises"
          var categoriesResponse = await CategoryService.getCategories();
          if (categoriesResponse.error == null && categoriesResponse.data != null) {
            var categories = categoriesResponse.data as List<Category>;
            try {
              var vocalisesCategory = categories.firstWhere(
                (cat) => cat.name == 'Vocalises',
              );
              _categoryId = vocalisesCategory.id;
            } catch (e) {
              print('Catégorie Vocalises non trouvée: $e');
            }
          }

          // Charger les pupitres
          var pupitresResponse = await ChoraleService.getPupitres(_choraleId!);
          if (pupitresResponse.error == null && pupitresResponse.data != null) {
            _pupitres = pupitresResponse.data as List<ChoralePupitre>;
            if (_pupitres.isNotEmpty) {
              _selectedPupitreId = _pupitres.first.id;
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      ToastService.error(context, 'Erreur lors du chargement des données');
    } finally {
      setState(() {
        _loadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: "Ajouter une Vocalise",
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
      body: _loadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  labelText: 'Titre de la vocalise',
                  hintText: 'Ex: Échauffement Soprane - Do Ré Mi',
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
                  hintText: 'Description de l\'exercice...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              
              SizedBox(height: 24),
              
              // Classification
              _buildSectionTitle('Classification'),
              SizedBox(height: 16),
              
                    // Pupitre
                    DropdownButtonFormField<int>(
                      value: _selectedPupitreId,
                decoration: InputDecoration(
                        labelText: 'Pupitre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.record_voice_over),
                ),
                      items: _pupitres.map((pupitre) {
                        return DropdownMenuItem<int>(
                          value: pupitre.id,
                          child: Text(pupitre.nom),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                          _selectedPupitreId = value;
                  });
                },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un pupitre';
                        }
                        return null;
                },
              ),
              
              SizedBox(height: 24),
              
              // Fichier audio
              _buildSectionTitle('Fichier audio'),
              SizedBox(height: 16),
              
              _buildAudioFileSelector(),
              
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
                      onPressed: _isLoading ? null : _saveVocalise,
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

  Widget _buildAudioFileSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.audio_file,
            size: 48,
            color: _selectedAudioFile != null ? AppConstance.primary : Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            _selectedAudioFile != null 
                ? 'Fichier sélectionné: ${_selectedAudioFile!.path.split('/').last}'
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: _selectedAudioFile != null ? AppConstance.primary : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectAudioFile,
            icon: Icon(Icons.upload_file),
            label: Text(_selectedAudioFile != null ? 'Changer le fichier' : 'Sélectionner un fichier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Formats supportés: MP3, WAV, OGG, M4A (max 10MB)',
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

  Future<void> _selectAudioFile() async {
    try {
      File? selectedFile = await FileUploadService.selectAudioFile();
      
      if (selectedFile != null) {
        setState(() {
          _selectedAudioFile = selectedFile;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier sélectionné: ${FileUploadService.getFileName(selectedFile.path)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Future<void> _saveVocalise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAudioFile == null) {
      ToastService.warning(context, 'Veuillez sélectionner un fichier audio');
      return;
    }

    if (_categoryId == null) {
      ToastService.error(context, 'Catégorie Vocalises introuvable');
      return;
    }

    if (_choraleId == null) {
      ToastService.error(context, 'Chorale introuvable');
      return;
    }

    if (_selectedPupitreId == null) {
      ToastService.warning(context, 'Veuillez sélectionner un pupitre');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer la partition (vocalise) via PartitionService
      final response = await PartitionService.createPartition(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _categoryId!,
        choraleId: _choraleId!,
        audioFilePath: _selectedAudioFile?.path,
        pdfFilePath: null,
        imageFilePath: null,
        rubriqueSectionId: widget.section.id,
        pupitreId: _selectedPupitreId,
        messePart: null,
        messeSubPart: null,
      );

      if (response.error == null) {
        ToastService.success(context, 'Vocalise créée avec succès !');
        Navigator.of(context).pop(true); // Retour avec succès
      } else {
        throw Exception(response.error);
      }
      
    } catch (e) {
      ToastService.error(context, 'Erreur lors de la création: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
