import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/file_upload_service.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_de_messe.dart';

/// Écran pour ajouter des enregistrements et fichiers aux chants avec organisation par pupitre
class AddRecordingToChantScreen extends StatefulWidget {
  final ChantDeMesse chant;

  const AddRecordingToChantScreen({super.key, required this.chant});

  @override
  State<AddRecordingToChantScreen> createState() => _AddRecordingToChantScreenState();
}

class _AddRecordingToChantScreenState extends State<AddRecordingToChantScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();

  // Pupitre actuellement sélectionné
  String _selectedPupitre = 'tutti';

  // Fichiers organisés par pupitre
  final Map<String, List<FileItem>> _filesByPupitre = {
    'soprano': [],
    'alto': [],
    'tenor': [],
    'basse': [],
    'tutti': [],
  };

  bool _loading = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    // S'assurer qu'aucun enregistrement n'est en cours
    _ensureRecordingStopped();
  }

  /// S'assure qu'aucun enregistrement n'est en cours
  Future<void> _ensureRecordingStopped() async {
    if (_recorderService.isRecording) {
      debugPrint('🔄 Arrêt de l\'enregistrement en cours...');
      await _recorderService.resetRecordingState();
    }
  }

  void _initRecorder() {
    _recorderService.stateStream.listen((state) {
      setState(() {
        _isRecording = state == RecordingState.recording;
      });
    });

    _recorderService.durationStream.listen((duration) {
      setState(() {
        _recordingDuration = duration;
      });
    });
  }

  @override
  void dispose() {
    // Arrêter proprement l'enregistrement si nécessaire
    if (_recorderService.isRecording) {
      _recorderService.stopRecording();
    }
    // Ne pas appeler dispose() sur le service singleton car d'autres écrans peuvent l'utiliser
    super.dispose();
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
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _loading ? null : _saveFiles,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du chant
            _buildChantHeader(),

            const SizedBox(height: 20),

            // Sélecteur de pupitre
            _buildPupitreSelector(),

            const SizedBox(height: 20),

            // Section d'enregistrement
            _buildRecordingSection(),

            const SizedBox(height: 20),

            // Section d'upload de fichiers
            _buildUploadSection(),

            const SizedBox(height: 20),

            // Affichage des fichiers par pupitre
            _buildFilesByPupitreSection(),

            const SizedBox(height: 20),

            // Bouton de sauvegarde
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildChantHeader() {
    return Card(
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
    );
  }

  Widget _buildPupitreSelector() {
    final pupitres = [
      {'value': 'soprano', 'label': 'Soprano', 'icon': Icons.person, 'color': Colors.pink},
      {'value': 'alto', 'label': 'Alto', 'icon': Icons.person_outline, 'color': Colors.purple},
      {'value': 'tenor', 'label': 'Ténor', 'icon': Icons.person, 'color': Colors.blue},
      {'value': 'basse', 'label': 'Basse', 'icon': Icons.person_outline, 'color': Colors.indigo},
      {'value': 'tutti', 'label': 'Tutti (Tous)', 'icon': Icons.groups, 'color': Colors.green},
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppConstance.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Sélectionner le pupitre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pupitres.map((pupitre) {
                final isSelected = _selectedPupitre == pupitre['value'];
                final color = pupitre['color'] as Color;

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pupitre['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 4),
                      Text(pupitre['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: color.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPupitre = pupitre['value'] as String;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Enregistrement audio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Durée d'enregistrement
            if (_isRecording)
              Center(
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_recordingDuration),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enregistrement en cours...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Boutons d'enregistrement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isRecording)
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Démarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  )
                else ...[
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Arrêter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _cancelRecording,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Info sur le pupitre sélectionné
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstance.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppConstance.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'L\'enregistrement sera ajouté au pupitre: ${_getPupitreLabel(_selectedPupitre)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstance.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: AppConstance.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Upload de fichiers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Boutons d'upload
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadAudioFile,
                    icon: const Icon(Icons.audiotrack),
                    label: const Text('Audio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadImageFile,
                    icon: const Icon(Icons.image),
                    label: const Text('Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadPdfFile,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesByPupitreSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: AppConstance.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Fichiers par pupitre',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstance.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getTotalFileCount()}',
                    style: TextStyle(
                      color: AppConstance.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Afficher les fichiers pour chaque pupitre
            ..._filesByPupitre.entries.map((entry) {
              return _buildPupitreFilesSection(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPupitreFilesSection(String pupitre, List<FileItem> files) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _getPupitreColor(pupitre).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: _getPupitreColor(pupitre).withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPupitreIcon(pupitre),
                color: _getPupitreColor(pupitre),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getPupitreLabel(pupitre),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getPupitreColor(pupitre),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPupitreColor(pupitre),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${files.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...files.asMap().entries.map((entry) {
            int index = entry.key;
            FileItem file = entry.value;
            return _buildFileItem(file, pupitre, index);
          }),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileItem fileItem, String pupitre, int index) {
    IconData icon;
    Color color;

    switch (fileItem.type) {
      case FileType.audio:
        icon = Icons.audiotrack;
        color = Colors.green;
        break;
      case FileType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case FileType.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  fileItem.type.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _removeFile(pupitre, index),
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _saveFiles,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstance.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const MyText(
                text: 'Sauvegarder et Synchroniser',
                color: Colors.white,
                size: 16,
                fontweight: FontWeight.bold,
              ),
      ),
    );
  }

  // Méthodes d'action

  Future<void> _startRecording() async {
    try {
      // S'assurer qu'aucun enregistrement n'est en cours
      if (_recorderService.isRecording) {
        debugPrint('🔄 Arrêt de l\'enregistrement précédent...');
        await _recorderService.resetRecordingState();
      }

      bool started = await _recorderService.startRecording();
      if (!started) {
        ToastService.error(context, 'Impossible de démarrer l\'enregistrement');
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? recordingPath = await _recorderService.stopRecording();

      if (recordingPath != null) {
        // Ajouter l'enregistrement aux fichiers du pupitre sélectionné
        setState(() {
          _filesByPupitre[_selectedPupitre]!.add(
            FileItem(
              name: 'Enregistrement ${DateTime.now().toString().substring(11, 19)}',
              path: recordingPath,
              type: FileType.audio,
            ),
          );
        });

        if (mounted) {
          ToastService.success(context, 'Enregistrement ajouté au pupitre ${_getPupitreLabel(_selectedPupitre)}');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recorderService.cancelRecording();
      if (mounted) {
        ToastService.info(context, 'Enregistrement annulé');
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _uploadAudioFile() async {
    try {
      List<File> files = await FileUploadService.selectMultipleAudioFiles();

      if (files.isNotEmpty) {
        setState(() {
          for (var file in files) {
            _filesByPupitre[_selectedPupitre]!.add(
              FileItem(
                name: FileUploadService.getFileName(file.path),
                path: file.path,
                type: FileType.audio,
              ),
            );
          }
        });

        if (mounted) {
          ToastService.success(
            context,
            '${files.length} fichier(s) audio ajouté(s) au pupitre ${_getPupitreLabel(_selectedPupitre)}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Erreur lors de la sélection: $e');
      }
    }
  }

  Future<void> _uploadImageFile() async {
    try {
      List<File> files = await FileUploadService.selectMultipleImageFiles();

      if (files.isNotEmpty) {
        setState(() {
          for (var file in files) {
            _filesByPupitre[_selectedPupitre]!.add(
              FileItem(
                name: FileUploadService.getFileName(file.path),
                path: file.path,
                type: FileType.image,
              ),
            );
          }
        });

        if (mounted) {
          ToastService.success(
            context,
            '${files.length} image(s) ajoutée(s) au pupitre ${_getPupitreLabel(_selectedPupitre)}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Erreur lors de la sélection: $e');
      }
    }
  }

  Future<void> _uploadPdfFile() async {
    try {
      List<File> files = await FileUploadService.selectMultiplePdfFiles();

      if (files.isNotEmpty) {
        setState(() {
          for (var file in files) {
            _filesByPupitre[_selectedPupitre]!.add(
              FileItem(
                name: FileUploadService.getFileName(file.path),
                path: file.path,
                type: FileType.pdf,
              ),
            );
          }
        });

        if (mounted) {
          ToastService.success(
            context,
            '${files.length} fichier(s) PDF ajouté(s) au pupitre ${_getPupitreLabel(_selectedPupitre)}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Erreur lors de la sélection: $e');
      }
    }
  }

  void _removeFile(String pupitre, int index) {
    setState(() {
      _filesByPupitre[pupitre]!.removeAt(index);
    });
    if (mounted) {
      ToastService.info(context, 'Fichier supprimé');
    }
  }

  Future<void> _saveFiles() async {
    // Vérifier qu'il y a au moins un fichier à uploader
    if (_getTotalFileCount() == 0) {
      if (mounted) {
        ToastService.warning(context, 'Aucun fichier à sauvegarder');
      }
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      int totalFiles = _getTotalFileCount();
      int uploadedFiles = 0;
      List<String> errors = [];

      // Uploader les fichiers pour chaque pupitre
      for (var entry in _filesByPupitre.entries) {
        String pupitre = entry.key;
        List<FileItem> files = entry.value;

        if (files.isEmpty) continue;

        // Uploader chaque fichier du pupitre
        for (var fileItem in files) {
          try {
            File file = File(fileItem.path);

            // Déterminer le field name selon le type de fichier
            String fieldName = 'file';
            String fileType = '';

            switch (fileItem.type) {
              case FileType.audio:
                fieldName = 'audio_file';
                fileType = 'audio';
                break;
              case FileType.image:
                fieldName = 'image_file';
                fileType = 'image';
                break;
              case FileType.pdf:
                fieldName = 'pdf_file';
                fileType = 'pdf';
                break;
            }

            // Upload du fichier avec les métadonnées de pupitre
            var response = await FileUploadService.uploadFile(
              file: file,
              endpoint: '/api/chants/${widget.chant.id}/upload-file',
              fieldName: fieldName,
              additionalFields: {
                'pupitre': pupitre,
                'file_type': fileType,
                'chant_id': widget.chant.id.toString(),
              },
            );

            if (response.error == null) {
              uploadedFiles++;
              print('✅ Fichier uploadé: ${fileItem.name} (pupitre: $pupitre)');
            } else {
              errors.add('${fileItem.name}: ${response.error}');
              print('❌ Erreur upload ${fileItem.name}: ${response.error}');
            }
          } catch (e) {
            errors.add('${fileItem.name}: $e');
            print('❌ Exception upload ${fileItem.name}: $e');
          }
        }
      }

      if (mounted) {
        if (errors.isEmpty) {
          // Tous les fichiers ont été uploadés avec succès
          ToastService.success(
            context,
            '$uploadedFiles/$totalFiles fichier(s) synchronisé(s) avec succès',
          );
          Navigator.pop(context, true);
        } else if (uploadedFiles > 0) {
          // Certains fichiers ont été uploadés
          ToastService.warning(
            context,
            '$uploadedFiles/$totalFiles fichier(s) uploadé(s). ${errors.length} erreur(s)',
          );

          // Afficher les erreurs
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erreurs d\'upload'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: errors.map((e) => Text('• $e')).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Aucun fichier n'a été uploadé
          ToastService.error(context, 'Échec de l\'upload de tous les fichiers');

          // Afficher les erreurs
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erreurs d\'upload'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: errors.map((e) => Text('• $e')).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Méthodes utilitaires

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _getPupitreLabel(String pupitre) {
    switch (pupitre) {
      case 'soprano':
        return 'Soprano';
      case 'alto':
        return 'Alto';
      case 'tenor':
        return 'Ténor';
      case 'basse':
        return 'Basse';
      case 'tutti':
        return 'Tutti (Tous)';
      default:
        return pupitre;
    }
  }

  IconData _getPupitreIcon(String pupitre) {
    switch (pupitre) {
      case 'soprano':
        return Icons.person;
      case 'alto':
        return Icons.person_outline;
      case 'tenor':
        return Icons.person;
      case 'basse':
        return Icons.person_outline;
      case 'tutti':
        return Icons.groups;
      default:
        return Icons.person;
    }
  }

  Color _getPupitreColor(String pupitre) {
    switch (pupitre) {
      case 'soprano':
        return Colors.pink;
      case 'alto':
        return Colors.purple;
      case 'tenor':
        return Colors.blue;
      case 'basse':
        return Colors.indigo;
      case 'tutti':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  int _getTotalFileCount() {
    return _filesByPupitre.values.fold(0, (sum, files) => sum + files.length);
  }
}

/// Modèle pour un fichier avec son type
class FileItem {
  final String name;
  final String path;
  final FileType type;

  FileItem({
    required this.name,
    required this.path,
    required this.type,
  });
}

/// Types de fichiers supportés
enum FileType {
  audio,
  image,
  pdf,
}
