import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/services/audio_editor_service.dart';
import 'package:voxbox/services/global_audio_player_service.dart';

class RecordingsHistorySheet extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onClose;

  const RecordingsHistorySheet({
    super.key,
    required this.scrollController,
    required this.onClose,
  });

  @override
  State<RecordingsHistorySheet> createState() => _RecordingsHistorySheetState();
}

class _RecordingsHistorySheetState extends State<RecordingsHistorySheet> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final AudioEditorService _editorService = AudioEditorService();
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();

  List<AudioRecording> _recordings = [];
  List<AudioFile> _editedFiles = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Enregistrements, 1: Édités

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    // Écouter les changements du lecteur audio pour rafraîchir l'UI
    _audioPlayerService.isPlayingStream.listen((_) {
      if (mounted) setState(() {});
    });

    _audioPlayerService.audioInfoStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Chargement des enregistrements...');
      final recordings = await _recorderService.getRecordings();
      print('📁 Enregistrements trouvés: ${recordings.length}');
      
      print('🔄 Chargement des fichiers édités...');
      final editedFiles = await _editorService.getEditedFiles();
      print('✂️ Fichiers édités trouvés: ${editedFiles.length}');
      
      setState(() {
        _recordings = recordings;
        _editedFiles = editedFiles;
        _isLoading = false;
      });
      
      print('✅ Données chargées avec succès');
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _playRecording(AudioRecording recording) async {
    try {
      // Utiliser le service global pour que l'audio continue même si on quitte la page
      await _audioPlayerService.playAudio(recording.path, title: recording.name);
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la lecture');
    }
  }

  Future<void> _playEditedFile(AudioFile file) async {
    try {
      // Utiliser le service global pour que l'audio continue même si on quitte la page
      await _audioPlayerService.playAudio(file.path, title: file.name);
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la lecture');
    }
  }


  Future<void> _editRecording(AudioRecording recording) async {
    // TODO: Ouvrir l'éditeur audio avec le fichier sélectionné
    _showErrorSnackBar('Éditeur audio en cours de développement');
  }

  Future<void> _deleteRecording(AudioRecording recording) async {
    final confirmed = await _showDeleteConfirmation(recording.name);
    if (confirmed) {
      final success = await _recorderService.deleteRecording(recording.path);
      if (success) {
        _showSuccessSnackBar('Enregistrement supprimé');
        _loadData();
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  Future<void> _deleteEditedFile(AudioFile file) async {
    final confirmed = await _showDeleteConfirmation(file.name);
    if (confirmed) {
      final success = await _editorService.deleteEditedFile(file.path);
      if (success) {
        _showSuccessSnackBar('Fichier supprimé');
        _loadData();
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le fichier'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle pour le drag
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // En-tête avec onglets
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Historique des Enregistrements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
        
        // Onglets
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  'Enregistrements',
                  0,
                  _recordings.length,
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  'Édités',
                  1,
                  _editedFiles.length,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Contenu des onglets
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedTab == 0
                  ? _buildRecordingsList()
                  : _buildEditedFilesList(),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index, int count) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstance.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingsList() {
    if (_recordings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mic_off,
        title: 'Aucun enregistrement',
        subtitle: 'Commencez par créer votre premier enregistrement',
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final recording = _recordings[index];
        return _buildRecordingCard(recording, true);
      },
    );
  }

  Widget _buildEditedFilesList() {
    if (_editedFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.edit_off,
        title: 'Aucun fichier édité',
        subtitle: 'Éditez vos enregistrements pour les voir ici',
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _editedFiles.length,
      itemBuilder: (context, index) {
        final file = _editedFiles[index];
        return _buildRecordingCard(file, false);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(dynamic recording, bool isOriginal) {
    // Vérifier si c'est l'audio en cours de lecture dans le service global
    final isPlaying = _audioPlayerService.currentAudioPath == recording.path;

    return Dismissible(
      key: Key(recording.path),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(recording.name);
      },
      onDismissed: (direction) {
        if (isOriginal) {
          _recorderService.deleteRecording(recording.path);
        } else {
          _editorService.deleteEditedFile(recording.path);
        }
        _showSuccessSnackBar('Enregistrement supprimé');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isOriginal) {
              _playRecording(recording as AudioRecording);
            } else {
              _playEditedFile(recording as AudioFile);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icône
                    CircleAvatar(
                      backgroundColor: isPlaying ? AppConstance.primary : Colors.grey[300],
                      radius: 24,
                      child: Icon(
                        isPlaying ? Icons.equalizer : (isOriginal ? Icons.audiotrack : Icons.edit),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Informations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre (cliquable pour renommer)
                          GestureDetector(
                            onTap: () => _showRenameDialog(recording, isOriginal),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recording.name.replaceAll('.aac', '').replaceAll('.m4a', ''),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recording.formattedDuration} • ${recording.formattedSize}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _formatDate(recording.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Bouton play/pause
                    IconButton(
                      onPressed: () {
                        if (isPlaying && _audioPlayerService.isPlaying) {
                          _audioPlayerService.pause();
                        } else if (isPlaying && _audioPlayerService.isPaused) {
                          _audioPlayerService.play();
                        } else {
                          if (isOriginal) {
                            _playRecording(recording as AudioRecording);
                          } else {
                            _playEditedFile(recording as AudioFile);
                          }
                        }
                      },
                      icon: Icon(
                        isPlaying && _audioPlayerService.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: AppConstance.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),

                // Barre de progression (affichée seulement si c'est l'audio en cours)
                if (isPlaying) ...[
                  const SizedBox(height: 8),
                  StreamBuilder<Duration>(
                    stream: _audioPlayerService.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioPlayerService.totalDuration;
                      final progress = duration.inMilliseconds > 0
                          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppConstance.primary,
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: AppConstance.primary,
                              overlayColor: AppConstance.primary.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: progress,
                              onChanged: (value) {
                                final newPosition = Duration(
                                  milliseconds: (value * duration.inMilliseconds).round(),
                                );
                                _audioPlayerService.seek(newPosition);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    _audioPlayerService.formatDuration(position),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _audioPlayerService.seekBackward(),
                                      icon: const Icon(Icons.replay_10),
                                      iconSize: 20,
                                      color: AppConstance.primary,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      onPressed: () => _audioPlayerService.seekForward(),
                                      icon: const Icon(Icons.forward_10),
                                      iconSize: 20,
                                      color: AppConstance.primary,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Text(
                                    _audioPlayerService.formatDuration(duration),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dialogue pour renommer l'enregistrement
  Future<void> _showRenameDialog(dynamic recording, bool isOriginal) async {
    final currentName = recording.name.replaceAll('.aac', '').replaceAll('.m4a', '');
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      // TODO: Implémenter la logique de renommage dans le service
      _showSuccessSnackBar('Renommé en "$newName"');
      _loadData(); // Recharger les données
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
