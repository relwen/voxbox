import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/file_upload_service.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_de_messe.dart';

class AddFilesToChantScreen extends StatefulWidget {
  final ChantDeMesse chant;

  const AddFilesToChantScreen({super.key, required this.chant});

  @override
  State<AddFilesToChantScreen> createState() => _AddFilesToChantScreenState();
}

class _AddFilesToChantScreenState extends State<AddFilesToChantScreen> {
  List<File> selectedAudioFiles = [];
  List<File> selectedPdfFiles = [];
  List<File> selectedImageFiles = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les fichiers existants
    selectedAudioFiles = List.from(widget.chant.audioFiles ?? []);
    selectedPdfFiles = List.from(widget.chant.pdfFiles ?? []);
    selectedImageFiles = List.from(widget.chant.imageFiles ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: 'Ajouter des fichiers',
          color: Colors.white,
          size: 18,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: loading ? null : _saveFiles,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppConstance.primary,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chant.titre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.chant.description != null)
                            Text(
                              widget.chant.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section Audio
            _buildFileSection(
              title: 'Fichiers Audio',
              icon: Icons.audiotrack,
              color: Colors.green,
              files: selectedAudioFiles,
              onAdd: _addAudioFiles,
              onRemove: _removeAudioFile,
            ),

            const SizedBox(height: 16),

            // Section PDF
            _buildFileSection(
              title: 'Partitions PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              files: selectedPdfFiles,
              onAdd: _addPdfFiles,
              onRemove: _removePdfFile,
            ),

            const SizedBox(height: 16),

            // Section Images
            _buildFileSection(
              title: 'Images',
              icon: Icons.image,
              color: Colors.blue,
              files: selectedImageFiles,
              onAdd: _addImageFiles,
              onRemove: _removeImageFile,
            ),

            const SizedBox(height: 20),

            // Bouton de sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _saveFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstance.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const MyText(
                        text: 'Sauvegarder les fichiers',
                        color: Colors.white,
                        size: 16,
                        fontweight: FontWeight.bold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<File> files,
    required VoidCallback onAdd,
    required Function(int) onRemove,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${files.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, color: color),
                  onPressed: onAdd,
                  tooltip: 'Ajouter des fichiers',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (files.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: Colors.grey, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun fichier ${title.toLowerCase()}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...files.asMap().entries.map((entry) {
                int index = entry.key;
                File file = entry.value;
                return _buildFileItem(file, index, color, () => onRemove(index));
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(File file, int index, Color color, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(color),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fichier ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  FileUploadService.getFileName(file.path),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onRemove,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(Color color) {
    if (color == Colors.green) return Icons.audiotrack;
    if (color == Colors.red) return Icons.picture_as_pdf;
    if (color == Colors.blue) return Icons.image;
    return Icons.insert_drive_file;
  }

  void _addAudioFiles() async {
    try {
      List<File> files = await FileUploadService.selectMultipleAudioFiles();
      
      if (files.isNotEmpty) {
        setState(() {
          selectedAudioFiles.addAll(files);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${files.length} fichier(s) audio ajouté(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection des fichiers audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addPdfFiles() async {
    try {
      List<File> files = await FileUploadService.selectMultiplePdfFiles();
      
      if (files.isNotEmpty) {
        setState(() {
          selectedPdfFiles.addAll(files);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${files.length} fichier(s) PDF ajouté(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection des fichiers PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addImageFiles() async {
    try {
      List<File> files = await FileUploadService.selectMultipleImageFiles();
      
      if (files.isNotEmpty) {
        setState(() {
          selectedImageFiles.addAll(files);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${files.length} image(s) ajoutée(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection des images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAudioFile(int index) {
    setState(() {
      selectedAudioFiles.removeAt(index);
    });
  }

  void _removePdfFile(int index) {
    setState(() {
      selectedPdfFiles.removeAt(index);
    });
  }

  void _removeImageFile(int index) {
    setState(() {
      selectedImageFiles.removeAt(index);
    });
  }

  void _saveFiles() async {
    setState(() {
      loading = true;
    });

    try {
      // TODO: Implémenter la sauvegarde des fichiers
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fichiers sauvegardés avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}
