import 'dart:io';
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
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/services/chorale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Écran pour ajouter des enregistrements et fichiers aux sections de messe avec organisation par pupitre
class AddFilesToMesseSectionScreen extends StatefulWidget {
  final MesseSection section;

  const AddFilesToMesseSectionScreen({super.key, required this.section});

  @override
  State<AddFilesToMesseSectionScreen> createState() => _AddFilesToMesseSectionScreenState();
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

class _AddFilesToMesseSectionScreenState extends State<AddFilesToMesseSectionScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final PhotoService _photoService = PhotoService();

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
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();
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
      // Récupérer l'ID de la chorale depuis les préférences
      final prefs = await SharedPreferences.getInstance();
      _choraleId = prefs.getInt('chorale_id');
      
      if (_choraleId == null) {
        setState(() {
          _loadingPupitres = false;
          _errorMessage = 'Aucune chorale sélectionnée. Veuillez sélectionner une chorale dans votre profil.';
        });
        return;
      }

      final response = await ChoraleService.getPupitres(_choraleId!);
      
      if (response.error != null) {
        setState(() {
          _loadingPupitres = false;
          _errorMessage = 'Erreur lors du chargement des pupitres: ${response.error}';
        });
        return;
      }

      if (response.data == null || response.data!.isEmpty) {
        setState(() {
          _loadingPupitres = false;
          _errorMessage = 'Aucun pupitre trouvé pour cette chorale. Veuillez créer des pupitres dans les paramètres de la chorale.';
        });
        return;
      }

      setState(() {
        _pupitres = response.data!;
        // Initialiser la map avec les pupitres
        for (var pupitre in _pupitres) {
          _filesByPupitre[pupitre.id] = [];
        }
        // Sélectionner le premier pupitre par défaut
        if (_pupitres.isNotEmpty) {
          _selectedPupitreId = _pupitres.first.id;
        }
        _loadingPupitres = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des pupitres: $e');
      setState(() {
        _loadingPupitres = false;
        _errorMessage = 'Erreur lors du chargement des pupitres: $e';
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
    // Arrêter proprement l'enregistrement si nécessaire
    if (_recorderService.isRecording) {
      _recorderService.stopRecording();
    }
    // Ne pas appeler dispose() sur le service singleton car d'autres écrans peuvent l'utiliser
    super.dispose();
  }

  int _getTotalFileCount() {
    int total = 0;
    for (var files in _filesByPupitre.values) {
      total += files.length;
    }
    return total;
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
      body: _loadingPupitres
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadPupitres,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstance.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête de la section
                      _buildSectionHeader(),

                      const SizedBox(height: 20),

                      // Sélecteur de pupitre
                      if (_pupitres.isNotEmpty) _buildPupitreSelector(),

                      if (_pupitres.isEmpty)
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Aucun pupitre disponible. Veuillez créer des pupitres dans les paramètres de la chorale.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

            // Section d'enregistrement audio
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

  Widget _buildSectionHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppConstance.primary,
              child: const Icon(Icons.folder, color: Colors.white),
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
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pupitre.icon != null ? _getIconFromString(pupitre.icon!) : Icons.person,
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 4),
                      Text(pupitre.nom),
                    ],
                  ),
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

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'person':
      case 'person_outline':
        return Icons.person;
      case 'group':
      case 'groups':
        return Icons.group;
      case 'music_note':
      case 'music':
        return Icons.music_note;
      default:
        return Icons.person;
    }
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
                Icon(Icons.mic, color: AppConstance.primary, size: 24),
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
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppConstance.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.red, size: 48),
                        onPressed: _stopRecording,
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic, color: Colors.white),
                    label: const Text('Commencer l\'enregistrement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstance.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _uploadAudioFile,
                  icon: const Icon(Icons.audiotrack),
                  label: const Text('Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadPdfFile,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
    if (_getTotalFileCount() == 0) {
      return const SizedBox.shrink();
    }

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
                  'Fichiers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_getTotalFileCount()} fichier(s)',
                  style: TextStyle(
                    color: AppConstance.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._pupitres.map((pupitre) {
              final files = _filesByPupitre[pupitre.id] ?? [];
              if (files.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          pupitre.icon != null ? _getIconFromString(pupitre.icon!) : Icons.person,
                          size: 20,
                          color: pupitre.color != null
                              ? Color(int.parse(pupitre.color!.replaceAll('#', '0xFF')))
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pupitre.nom} (${files.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...files.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return _buildFileItem(file, index, pupitre.id);
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(FileItem file, int index, int pupitreId) {
    IconData icon;
    Color color;
    final bool isAudio = file.type == FileType.audio;
    final bool isCurrentlyPlaying = _currentlyPlayingPath == file.path && _audioPlayerService.isPlaying;

    switch (file.type) {
      case FileType.audio:
        icon = isCurrentlyPlaying ? Icons.equalizer : Icons.audiotrack;
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatFileSize(File(file.path).lengthSync()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Bouton play/pause pour les fichiers audio
          if (isAudio)
            IconButton(
              icon: Icon(
                isCurrentlyPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.green,
              ),
              onPressed: () => _playOrPauseAudio(file.path),
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Arrêter la lecture si c'est le fichier en cours
              if (isAudio && _currentlyPlayingPath == file.path) {
                _audioPlayerService.pause();
                setState(() {
                  _currentlyPlayingPath = null;
                });
              }
              setState(() {
                _filesByPupitre[pupitreId]?.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _playOrPauseAudio(String path) async {
    try {
      if (_currentlyPlayingPath == path && _audioPlayerService.isPlaying) {
        // Pause si c'est le fichier en cours
        await _audioPlayerService.pause();
        setState(() {
          _currentlyPlayingPath = null;
        });
      } else if (_currentlyPlayingPath == path && _audioPlayerService.isPaused) {
        // Reprendre si c'est le fichier en pause
        await _audioPlayerService.play();
      } else {
        // Jouer le nouveau fichier
        final file = File(path);
        if (await file.exists()) {
          await _audioPlayerService.playAudio(path, title: path.split('/').last);
          setState(() {
            _currentlyPlayingPath = path;
          });
        } else {
          ToastService.error(context, 'Le fichier audio n\'existe pas');
        }
      }
    } catch (e) {
      ToastService.error(context, 'Erreur lors de la lecture: $e');
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading || _getTotalFileCount() == 0 ? null : _saveFiles,
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
            : MyText(
                text: 'Synchroniser ${_getTotalFileCount()} fichier(s)',
                color: Colors.white,
                size: 16,
                fontweight: FontWeight.bold,
              ),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_selectedPupitreId == null) {
      ToastService.warning(context, 'Veuillez sélectionner un pupitre');
      return;
    }

    try {
      // S'assurer qu'aucun enregistrement n'est en cours
      if (_recorderService.isRecording) {
        debugPrint('🔄 Arrêt de l\'enregistrement précédent...');
        await _recorderService.resetRecordingState();
      }

      final success = await _recorderService.startRecording();
      if (success) {
        ToastService.success(context, 'Enregistrement démarré');
      } else {
        ToastService.error(context, 'Erreur lors du démarrage de l\'enregistrement');
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingPath = await _recorderService.stopRecording();
      if (recordingPath != null && _selectedPupitreId != null) {
        final fileName = recordingPath.split('/').last;
        setState(() {
          _filesByPupitre[_selectedPupitreId!] ??= [];
          _filesByPupitre[_selectedPupitreId!]!.add(
            FileItem(
              path: recordingPath,
              name: fileName,
              type: FileType.audio,
              createdAt: DateTime.now(),
            ),
          );
        });
        ToastService.success(context, 'Enregistrement sauvegardé');
      }
    } catch (e) {
      ToastService.error(context, 'Erreur lors de l\'arrêt de l\'enregistrement: $e');
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
          _filesByPupitre[_selectedPupitreId!] ??= [];
          _filesByPupitre[_selectedPupitreId!]!.add(
            FileItem(
              path: file.path,
              name: file.path.split('/').last,
              type: FileType.audio,
              createdAt: DateTime.now(),
            ),
          );
        });
        ToastService.success(context, 'Fichier audio ajouté');
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
    }
  }

  /// Affiche un dialogue pour choisir entre galerie et caméra
  Future<void> _pickImage() async {
    if (_selectedPupitreId == null) {
      ToastService.warning(context, 'Veuillez sélectionner un pupitre');
      return;
    }

    // Afficher un bottom sheet pour choisir la source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text('Caméra'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      PhotoItem? photo;
      if (source == ImageSource.gallery) {
        photo = await _photoService.pickPhotoFromGallery();
      } else {
        photo = await _photoService.takePhoto();
      }

      if (photo != null) {
        setState(() {
          _filesByPupitre[_selectedPupitreId!] ??= [];
          _filesByPupitre[_selectedPupitreId!]!.add(
            FileItem(
              path: photo!.path,
              name: photo.name,
              type: FileType.image,
              createdAt: photo.createdAt,
            ),
          );
        });
        ToastService.success(
          context,
          source == ImageSource.gallery ? 'Photo ajoutée' : 'Photo prise et ajoutée',
        );
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
          _filesByPupitre[_selectedPupitreId!] ??= [];
          _filesByPupitre[_selectedPupitreId!]!.add(
            FileItem(
              path: file.path,
              name: file.path.split('/').last,
              type: FileType.pdf,
              createdAt: DateTime.now(),
            ),
          );
        });
        ToastService.success(context, 'Fichier PDF ajouté');
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

    setState(() {
      _loading = true;
    });

    try {
      int uploadedFiles = 0;
      int failedFiles = 0;
      List<String> errors = [];

      // Récupérer l'ID de la chorale et de la catégorie
      final prefs = await SharedPreferences.getInstance();
      final choraleId = prefs.getInt('chorale_id');
      final categoryId = prefs.getInt('category_id') ?? 1; // Catégorie par défaut

      if (choraleId == null) {
        ToastService.error(context, 'Chorale non trouvée. Veuillez vous reconnecter.');
        setState(() {
          _loading = false;
        });
        return;
      }

      // Créer une partition pour chaque fichier individuellement
      for (var entry in _filesByPupitre.entries) {
        final pupitreId = entry.key;
        final files = entry.value;

        if (files.isEmpty) continue;

        // Trouver le nom du pupitre
        final pupitre = _pupitres.firstWhere(
          (p) => p.id == pupitreId,
          orElse: () => _pupitres.first,
        );
        final pupitreNom = pupitre.nom;

        // Créer une partition pour chaque fichier
        for (var fileItem in files) {
          String? audioFile;
          String? pdfFile;
          String? imageFile;

          // Vérifier que le fichier existe avant de continuer
          final file = File(fileItem.path);
          if (!await file.exists()) {
            print('❌ Fichier introuvable: ${fileItem.path}');
            failedFiles++;
            errors.add('${fileItem.name}: Fichier introuvable');
            continue;
          }

          final fileSize = await file.length();
          print('📄 Fichier à uploader: ${fileItem.name} (${fileSize} bytes) - Type: ${fileItem.type}');

          switch (fileItem.type) {
            case FileType.audio:
              audioFile = fileItem.path;
              break;
            case FileType.pdf:
              pdfFile = fileItem.path;
              break;
            case FileType.image:
              imageFile = fileItem.path;
              break;
          }

          try {
            // Utiliser le nom du fichier comme titre
            final fileName = fileItem.name.split('.').first;
            final title = '${widget.section.nom} - ${pupitreNom} - $fileName';
            final description = 'Fichier ${_getFileTypeName(fileItem.type)} ajouté pour la section ${widget.section.nom}, pupitre ${pupitreNom}';

            print('🔄 Création partition pour: $title');
            print('   - Audio: ${audioFile ?? "aucun"}');
            print('   - PDF: ${pdfFile ?? "aucun"}');
            print('   - Image: ${imageFile ?? "aucun"}');

            final response = await PartitionService.createPartition(
              title: title,
              description: description,
              categoryId: categoryId,
              choraleId: choraleId,
              audioFilePath: audioFile,
              pdfFilePath: pdfFile,
              imageFilePath: imageFile,
              rubriqueSectionId: widget.section.messeId,
              pupitreId: pupitreId,
              messePart: widget.section.nom, // Nom de la section (ex: "Kyrié", "Sanctus")
              messeSubPart: null, // Pas de sous-partie pour l'instant
            );

            if (response.error == null) {
              uploadedFiles++;
              print('✅ Partition créée pour ${fileItem.name} (pupitre ${pupitreNom})');
            } else {
              failedFiles++;
              errors.add('${fileItem.name}: ${response.error}');
              print('❌ Erreur création partition pour ${fileItem.name}: ${response.error}');
            }
          } catch (e) {
            failedFiles++;
            errors.add('${fileItem.name}: $e');
            print('❌ Exception création partition pour ${fileItem.name}: $e');
          }
        }
      }

      if (mounted) {
        if (uploadedFiles > 0) {
          // Au moins un fichier a été uploadé avec succès
          if (failedFiles == 0) {
            ToastService.success(
              context,
              '$uploadedFiles fichier(s) synchronisé(s) avec succès',
            );
            Navigator.pop(context, true);
          } else {
            // Certains fichiers ont réussi, d'autres ont échoué
            ToastService.warning(
              context,
              '$uploadedFiles fichier(s) synchronisé(s), $failedFiles échec(s)',
            );
            // Afficher les erreurs si nécessaire
            if (errors.isNotEmpty && errors.length <= 3) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Erreurs'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: errors.map((error) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(error, style: const TextStyle(fontSize: 12)),
                          )).toList(),
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
              });
            }
            // Fermer quand même l'écran si au moins un fichier a été uploadé
            Navigator.pop(context, true);
          }
        } else {
          // Aucun fichier n'a été uploadé
          ToastService.error(context, 'Aucun fichier n\'a pu être synchronisé');
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFileTypeName(FileType type) {
    switch (type) {
      case FileType.audio:
        return 'audio';
      case FileType.image:
        return 'image';
      case FileType.pdf:
        return 'PDF';
    }
  }
}

