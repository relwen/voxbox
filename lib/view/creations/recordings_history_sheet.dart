import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/services/audio_editor_service.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<AudioRecording> _recordings = [];
  List<AudioFile> _editedFiles = [];
  bool _isLoading = true;
  String? _playingRecording;
  bool _isPlaying = false;
  int _selectedTab = 0; // 0: Enregistrements, 1: Édités

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
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
      if (_playingRecording == recording.path && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(recording.path));
        setState(() {
          _playingRecording = recording.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la lecture');
    }
  }

  Future<void> _playEditedFile(AudioFile file) async {
    try {
      if (_playingRecording == file.path && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(file.path));
        setState(() {
          _playingRecording = file.path;
        });
      }
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
    _audioPlayer.dispose();
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
    final isPlaying = _playingRecording == recording.path;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPlaying ? AppConstance.primary : Colors.grey[300],
          child: Icon(
            isPlaying ? Icons.equalizer : (isOriginal ? Icons.audiotrack : Icons.edit),
            color: Colors.white,
          ),
        ),
        title: Text(
          recording.name.replaceAll('.aac', '').replaceAll('.m4a', ''),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${recording.formattedDuration} • ${recording.formattedSize}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              _formatDate(recording.createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'play':
                if (isOriginal) {
                  _playRecording(recording as AudioRecording);
                } else {
                  _playEditedFile(recording as AudioFile);
                }
                break;
              case 'edit':
                if (isOriginal) {
                  _editRecording(recording as AudioRecording);
                }
                break;
              case 'delete':
                if (isOriginal) {
                  _deleteRecording(recording as AudioRecording);
                } else {
                  _deleteEditedFile(recording as AudioFile);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Lire'),
                ],
              ),
            ),
            if (isOriginal)
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Éditer'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (isOriginal) {
            _playRecording(recording as AudioRecording);
          } else {
            _playEditedFile(recording as AudioFile);
          }
        },
      ),
    );
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
