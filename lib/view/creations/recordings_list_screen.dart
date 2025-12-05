import 'package:flutter/material.dart';
import 'package:voxbox/services/global_recorder_service.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/services/global_audio_player_service.dart';
import 'package:voxbox/view/creations/folders_screen.dart';
import 'package:voxbox/functions/appconstants.dart';

/// Page Créations - Affichage et lecture des enregistrements
class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();

  List<AudioRecording> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
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

  Future<void> _loadRecordings() async {
    setState(() {
      _isLoading = true;
    });

    final recordings = await _recorderService.getRecordings();

    if (mounted) {
      setState(() {
        _recordings = recordings;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _playRecording(AudioRecording recording) async {
    try {
      await _audioPlayerService.playAudio(recording.path, title: recording.name);
    } catch (e) {
      _showSnackBar('Erreur de lecture: $e', isError: true);
    }
  }

  Future<void> _deleteRecording(AudioRecording recording) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Supprimer l\'enregistrement',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${recording.name}" ?',
          style: const TextStyle(color: Colors.white70),
        ),
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
    );

    if (confirm == true) {
      // Arrêter la lecture si c'est le fichier en cours
      if (_audioPlayerService.currentAudioPath == recording.path) {
        await _audioPlayerService.stop();
      }

      final success = await _recorderService.deleteRecording(recording.path);
      if (success) {
        await _loadRecordings();
        _showSnackBar('Enregistrement supprimé', isError: false);
      } else {
        _showSnackBar('Erreur lors de la suppression', isError: true);
      }
    }
  }

  Future<void> _renameRecording(AudioRecording recording) async {
    final controller = TextEditingController(text: recording.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Renommer l\'enregistrement',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nouveau nom',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
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

    if (newName != null && newName.isNotEmpty && newName != recording.name) {
      final success = await _recorderService.renameRecording(
        recording.path,
        newName,
      );
      if (success) {
        await _loadRecordings();
        _showSnackBar('Enregistrement renommé', isError: false);
      } else {
        _showSnackBar('Erreur lors du renommage', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstance.primary,
                AppConstance.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
            ),
            title: const Text(
              'Créations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_open, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FoldersScreen()),
                  );
                },
                tooltip: 'Mes dossiers',
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white30,
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Aucun enregistrement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vos enregistrements apparaîtront ici',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final recording = _recordings[index];
                      final isCurrentlyPlaying = _audioPlayerService.currentAudioPath == recording.path;

                      return _buildRecordingCard(recording, isCurrentlyPlaying);
                    },
                  ),
      ),
    );
  }

  Widget _buildRecordingCard(AudioRecording recording, bool isCurrentlyPlaying) {
    return Dismissible(
      key: Key(recording.path),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Supprimer l\'enregistrement',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Voulez-vous vraiment supprimer "${recording.name}" ?',
              style: const TextStyle(color: Colors.white70),
            ),
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
        );
      },
      onDismissed: (direction) async {
        // Arrêter la lecture si c'est le fichier en cours
        if (_audioPlayerService.currentAudioPath == recording.path) {
          await _audioPlayerService.stop();
        }

        final success = await _recorderService.deleteRecording(recording.path);
        if (success) {
          await _loadRecordings();
          _showSnackBar('Enregistrement supprimé', isError: false);
        } else {
          _showSnackBar('Erreur lors de la suppression', isError: true);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(isCurrentlyPlaying ? 0.15 : 0.08),
              Colors.white.withOpacity(isCurrentlyPlaying ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrentlyPlaying
                ? AppConstance.primary.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isCurrentlyPlaying ? 2 : 1,
          ),
          boxShadow: isCurrentlyPlaying
              ? [
                  BoxShadow(
                    color: AppConstance.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Bouton Play/Pause
                  GestureDetector(
                    onTap: () async {
                      if (isCurrentlyPlaying && _audioPlayerService.isPlaying) {
                        await _audioPlayerService.pause();
                      } else {
                        await _playRecording(recording);
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCurrentlyPlaying && _audioPlayerService.isPlaying
                              ? [AppConstance.primary, AppConstance.primary.withOpacity(0.8)]
                              : [Colors.grey.shade700, Colors.grey.shade900],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isCurrentlyPlaying && _audioPlayerService.isPlaying
                                ? AppConstance.primary.withOpacity(0.4)
                                : Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isCurrentlyPlaying && _audioPlayerService.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Infos de l'enregistrement
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre cliquable pour renommer
                        GestureDetector(
                          onTap: () => _renameRecording(recording),
                          child: Text(
                            recording.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<Duration>(
                          stream: _audioPlayerService.positionStream,
                          builder: (context, snapshot) {
                            final currentPosition = isCurrentlyPlaying
                                ? (_audioPlayerService.currentPosition)
                                : recording.duration;
                            return Text(
                              _formatDuration(currentPosition),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(recording.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu d'options
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _renameRecording(recording);
                          break;
                        case 'delete':
                          _deleteRecording(recording);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Text('Renommer', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Supprimer', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Barre de progression interactive avec contrôles
            if (isCurrentlyPlaying)
              StreamBuilder<Duration>(
                stream: _audioPlayerService.positionStream,
                builder: (context, snapshot) {
                  final position = _audioPlayerService.currentPosition;
                  final duration = _audioPlayerService.totalDuration;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        // Slider interactif
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppConstance.primary,
                            inactiveTrackColor: Colors.white.withOpacity(0.1),
                            thumbColor: AppConstance.primary,
                            overlayColor: AppConstance.primary.withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPosition = Duration(
                                milliseconds: (value * duration.inMilliseconds).round(),
                              );
                              _audioPlayerService.seek(newPosition);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Contrôles de temps
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                // Bouton -10s
                                IconButton(
                                  icon: const Icon(Icons.replay_10),
                                  color: Colors.white.withOpacity(0.8),
                                  iconSize: 24,
                                  onPressed: () => _audioPlayerService.seekBackward(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 16),
                                // Bouton +10s
                                IconButton(
                                  icon: const Icon(Icons.forward_10),
                                  color: Colors.white.withOpacity(0.8),
                                  iconSize: 24,
                                  onPressed: () => _audioPlayerService.seekForward(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            Flexible(
                              child: Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
