import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/file_upload_service.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/services/photo_service.dart';
import 'package:voxbox/services/partition_service.dart';
import 'package:voxbox/services/global_audio_player_service.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_section.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/services/chorale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/widgets/offline_indicator.dart';
import 'package:voxbox/widgets/shimmer_loading.dart';

/// Écran pour ajouter des enregistrements et fichiers aux sections de chants avec organisation par pupitre
class AddFilesToChantSectionScreen extends StatefulWidget {
  final ChantSection section;

  const AddFilesToChantSectionScreen({super.key, required this.section});

  @override
  State<AddFilesToChantSectionScreen> createState() =>
      _AddFilesToChantSectionScreenState();
}

enum FileType {
  audio,
  image,
  pdf,
}

class FileItem {
  final String path;
  final String name;
  final FileType type;
  final DateTime createdAt;

  FileItem({
    required this.path,
    required this.name,
    required this.type,
    required this.createdAt,
  });
}

class _AddFilesToChantSectionScreenState
    extends State<AddFilesToChantSectionScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final PhotoService _photoService = PhotoService();
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();

  // Pupitre actuellement sélectionné (ID du pupitre)
  int? _selectedPupitreId;
  List<ChoralePupitre> _pupitres = [];

  // Fichiers organisés par pupitre (clé = ID du pupitre)
  final Map<int, List<FileItem>> _filesByPupitre = {};

  bool _loading = false;
  bool _loadingPupitres = true;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  int? _choraleId;
  String? _errorMessage;
  String? _currentlyPlayingPath;

  @override
  void initState() {
    super.initState();
    _loadPupitres();
    _initRecorder();
    _setupAudioListeners();
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

  void _setupAudioListeners() {
    _audioPlayerService.isPlayingStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadPupitres() async {
    setState(() {
      _loadingPupitres = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _choraleId = prefs.getInt('chorale_id');

      if (_choraleId == null) {
        final userString = prefs.getString('user');
        if (userString != null) {
          final user = Map<String, dynamic>.from(jsonDecode(userString));
          _choraleId = user['chorale_id'];
        }
      }

      if (_choraleId != null) {
        final response = await ChoraleService.getPupitres(_choraleId!);
        if (response.error == null && response.data != null) {
          setState(() {
            _pupitres = response.data as List<ChoralePupitre>;
            _loadingPupitres = false;

            // Initialiser la map
            for (var p in _pupitres) {
              _filesByPupitre[p.id] = [];
            }

            // Sélectionner le premier par défaut
            if (_pupitres.isNotEmpty) {
              _selectedPupitreId = _pupitres.first.id;
            }
          });
        } else {
          setState(() {
            _errorMessage = response.error ?? 'Erreur lors du chargement des pupitres';
            _loadingPupitres = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'ID de chorale non trouvé';
          _loadingPupitres = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _loadingPupitres = false;
      });
    }
  }

  void _initRecorder() {
    _recorderService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isRecording = state == RecordingState.recording;
        });
      }
    });

    _recorderService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _recordingDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_recorderService.isRecording) {
      _recorderService.stopRecording();
    }
    super.dispose();
  }

  int _getTotalFileCount() {
    int count = 0;
    _filesByPupitre.forEach((key, value) => count += value.length);
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des fichiers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppConstance.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _loading ? null : _saveFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: _loadingPupitres
                ? const ShimmerListLoading()
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadPupitres,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(),
                          const SizedBox(height: 20),
                          if (_pupitres.isNotEmpty) _buildPupitreSelector(),
                          const SizedBox(height: 20),
                          _buildRecordingSection(),
                          const SizedBox(height: 20),
                          _buildUploadSection(),
                          const SizedBox(height: 20),
                          _buildFilesByPupitreSection(),
                        ],
                      ),
                    ),
                    if (_loading)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text('Synchronisation en cours...',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    widget.section.nom,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.section.description != null)
                    Text(
                      widget.section.description!,
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              children: _pupitres.map((pupitre) {
                final isSelected = _selectedPupitreId == pupitre.id;
                final color = pupitre.color != null
                    ? Color(int.parse(pupitre.color!.replaceAll('#', '0xFF')))
                    : Colors.blue;

                return ChoiceChip(
                  label: Text(pupitre.nom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPupitreId = pupitre.id;
                    });
                  },
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
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
            if (_isRecording)
              Column(
                children: [
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.stop_circle, color: Colors.red, size: 64),
                      onPressed: _stopRecording,
                    ),
                  ),
                ],
              )
            else
              Center(
                child: ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text('Commencer l\'enregistrement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  'Ajouter des fichiers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadButton(Icons.audiotrack, 'Audio', Colors.orange, _uploadAudioFile),
                _buildUploadButton(Icons.image, 'Photo', Colors.blue, _pickImage),
                _buildUploadButton(Icons.picture_as_pdf, 'PDF', Colors.red.shade800, _uploadPdfFile),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesByPupitreSection() {
    if (_getTotalFileCount() == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Fichiers ajoutés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ..._pupitres.map((pupitre) {
          final files = _filesByPupitre[pupitre.id] ?? [];
          if (files.isEmpty) return const SizedBox.shrink();

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: Icon(Icons.folder, color: pupitre.color != null
                ? Color(int.parse(pupitre.color!.replaceAll('#', '0xFF')))
                : AppConstance.primary),
              title: Text('${pupitre.nom} (${files.length})', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              children: files.asMap().entries.map((entry) => 
                _buildFileItem(entry.value, entry.key, pupitre.id)).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFileItem(FileItem file, int index, int pId) {
    IconData icon;
    Color color;

    switch (file.type) {
      case FileType.audio:
        icon = Icons.audiotrack;
        color = Colors.orange;
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

    final isPlaying = _currentlyPlayingPath == file.path && _audioPlayerService.isPlaying;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_formatDate(file.createdAt), style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (file.type == FileType.audio)
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: AppConstance.primary),
              onPressed: () => _playAudio(file.path),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeFile(index, pId),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _removeFile(int index, int pId) {
    setState(() {
      _filesByPupitre[pId]?.removeAt(index);
    });
  }

  Future<void> _playAudio(String path) async {
    try {
      if (_currentlyPlayingPath == path && _audioPlayerService.isPlaying) {
        await _audioPlayerService.pause();
      } else if (_currentlyPlayingPath == path && _audioPlayerService.isPaused) {
        await _audioPlayerService.play();
      } else {
        setState(() => _currentlyPlayingPath = path);
        await _audioPlayerService.playAudio(path, title: path.split('/').last);
      }
      setState(() {});
    } catch (e) {
      ToastService.error(context, 'Erreur lors de la lecture: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_selectedPupitreId == null) {
      ToastService.warning(context, 'Veuillez sélectionner un pupitre');
      return;
    }

    try {
      final hasPermission = await _recorderService.requestPermissions();
      if (!hasPermission) {
        ToastService.error(context, 'Permission d\'enregistrement refusée');
        return;
      }

      if (_recorderService.isRecording) {
        await _recorderService.resetRecordingState();
      }

      final success = await _recorderService.startRecording();
      if (success) {
        ToastService.success(context, 'Enregistrement démarré');
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorderService.stopRecording();
      if (path != null && _selectedPupitreId != null) {
        final newFile = FileItem(
          path: path,
          name: 'Enregistrement_${DateTime.now().millisecondsSinceEpoch}.m4a',
          type: FileType.audio,
          createdAt: DateTime.now(),
        );

        setState(() {
          _filesByPupitre[_selectedPupitreId!]?.add(newFile);
        });
        ToastService.success(context, 'Enregistrement sauvegardé');
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  Future<void> _uploadAudioFile() async {
    if (_selectedPupitreId == null) {
      ToastService.warning(context, 'Veuillez sélectionner un pupitre');
      return;
    }
    try {
      final file = await FileUploadService.selectAudioFile();
      if (file != null) {
        setState(() {
          _filesByPupitre[_selectedPupitreId!]?.add(FileItem(
            path: file.path,
            name: file.path.split('/').last,
            type: FileType.audio,
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_selectedPupitreId == null) {
      ToastService.warning(context, 'Veuillez sélectionner un pupitre');
      return;
    }
    try {
      final photo = await _photoService.pickPhotoFromGallery();
      if (photo != null) {
        setState(() {
          _filesByPupitre[_selectedPupitreId!]?.add(FileItem(
            path: photo.path,
            name: photo.name,
            type: FileType.image,
            createdAt: photo.createdAt,
          ));
        });
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  Future<void> _uploadPdfFile() async {
    if (_selectedPupitreId == null) {
      ToastService.warning(context, 'Veuillez sélectionner un pupitre');
      return;
    }
    try {
      final file = await FileUploadService.selectPdfFile();
      if (file != null) {
        setState(() {
          _filesByPupitre[_selectedPupitreId!]?.add(FileItem(
            path: file.path,
            name: file.path.split('/').last,
            type: FileType.pdf,
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  Future<void> _saveFiles() async {
    if (_getTotalFileCount() == 0) {
      ToastService.warning(context, 'Aucun fichier à synchroniser');
      return;
    }

    setState(() => _loading = true);

    try {
      int uploadedFiles = 0;
      final prefs = await SharedPreferences.getInstance();
      final choraleId = _choraleId ?? prefs.getInt('chorale_id');
      final categoryId = prefs.getInt('category_id') ?? 1;

      if (choraleId == null) {
        ToastService.error(context, 'Chorale non trouvée');
        setState(() => _loading = false);
        return;
      }

      for (var entry in _filesByPupitre.entries) {
        final pupitreId = entry.key;
        final files = entry.value;
        if (files.isEmpty) continue;

        final pupitre = _pupitres.firstWhere((p) => p.id == pupitreId);

        for (var fileItem in files) {
          final title = '${widget.section.nom} - ${pupitre.nom} - ${fileItem.name.split('.').first}';
          final response = await PartitionService.createPartition(
            title: title,
            description: 'Ajouté pour ${widget.section.nom}',
            categoryId: categoryId,
            choraleId: choraleId,
            audioFilePath: fileItem.type == FileType.audio ? fileItem.path : null,
            pdfFilePath: fileItem.type == FileType.pdf ? fileItem.path : null,
            imageFilePath: fileItem.type == FileType.image ? fileItem.path : null,
            rubriqueSectionId: widget.section.id,
            pupitreId: pupitreId,
            messePart: widget.section.nom,
          );

          if (response.error == null) uploadedFiles++;
        }
      }

      if (uploadedFiles > 0) {
        ToastService.success(context, '$uploadedFiles fichier(s) synchronisé(s)');
        Navigator.pop(context, true);
      } else {
        ToastService.error(context, 'Échec de la synchronisation');
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}
