import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/services/vocalise_service.dart';
import 'package:voxbox/services/file_upload_service.dart';
import 'package:voxbox/widgets/widgets.dart';

class AddVocaliseScreen extends StatefulWidget {
  const AddVocaliseScreen({Key? key}) : super(key: key);

  @override
  _AddVocaliseScreenState createState() => _AddVocaliseScreenState();
}

class _AddVocaliseScreenState extends State<AddVocaliseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedVoicePart = 'SOPRANE';
  int _selectedChoraleId = 1;
  File? _selectedAudioFile;
  bool _isLoading = false;

  final List<String> _voiceParts = [
    'SOPRANE',
    'TENOR', 
    'MEZOSOPRANE',
    'ALTO',
    'BASSE',
    'BARITON'
  ];

  final List<Map<String, dynamic>> _chorales = [
    
  ];

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
              
              // Partie vocale
              DropdownButtonFormField<String>(
                value: _selectedVoicePart,
                decoration: InputDecoration(
                  labelText: 'Partie vocale',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.record_voice_over),
                ),
                items: _voiceParts.map((voicePart) {
                  return DropdownMenuItem(
                    value: voicePart,
                    child: Text(voicePart),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVoicePart = value!;
                  });
                },
              ),
              
              SizedBox(height: 16),
              
              // Chorale
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un fichier audio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer la vocalise via le service
      final response = await VocaliseService.createVocalise(
        title: _titleController.text,
        description: _descriptionController.text,
        voicePart: _selectedVoicePart,
        choraleId: _selectedChoraleId,
        audioFilePath: _selectedAudioFile?.path,
      );

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vocalise créée avec succès !'),
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
}
