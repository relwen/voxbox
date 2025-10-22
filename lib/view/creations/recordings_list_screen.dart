import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/widgets/widgets.dart';

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<AudioRecording> _recordings = [];
  bool _isLoading = true;
  String? _playingRecording;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
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

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<void> _loadRecordings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recordings = await _recorderService.getRecordings();
      setState(() {
        _recordings = recordings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des enregistrements');
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

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _playingRecording = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
  }

  Future<void> _deleteRecording(AudioRecording recording) async {
    final confirmed = await _showDeleteConfirmation(recording.name);
    if (confirmed) {
      final success = await _recorderService.deleteRecording(recording.path);
      if (success) {
        _showSuccessSnackBar('Enregistrement supprimé');
        _loadRecordings();
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  Future<void> _renameRecording(AudioRecording recording) async {
    final newName = await _showRenameDialog(recording.name);
    if (newName != null && newName.isNotEmpty) {
      final success = await _recorderService.renameRecording(recording.path, newName);
      if (success) {
        _showSuccessSnackBar('Enregistrement renommé');
        _loadRecordings();
      } else {
        _showErrorSnackBar('Erreur lors du renommage');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'enregistrement'),
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

  Future<String?> _showRenameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName.replaceAll('.aac', '').replaceAll('.m4a', ''));
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer l\'enregistrement'),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const MyText(
          text: 'Mes Enregistrements',
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRecordings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Contrôles de lecture
                    if (_playingRecording != null) _buildPlaybackControls(),
                    
                    // Liste des enregistrements
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadRecordings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _recordings.length,
                          itemBuilder: (context, index) {
                            final recording = _recordings[index];
                            return _buildRecordingCard(recording);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun enregistrement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer votre premier enregistrement',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.mic),
            label: const Text('Nouvel enregistrement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de progression
          Slider(
            value: _totalDuration.inMilliseconds > 0
                ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                : 0.0,
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * _totalDuration.inMilliseconds).round(),
              );
              _audioPlayer.seek(position);
            },
            activeColor: AppConstance.primary,
          ),
          
          // Contrôles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(fontSize: 12),
              ),
              IconButton(
                onPressed: _isPlaying ? _stopPlayback : () {
                  final recording = _recordings.firstWhere(
                    (r) => r.path == _playingRecording,
                  );
                  _playRecording(recording);
                },
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                color: AppConstance.primary,
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(AudioRecording recording) {
    final isPlaying = _playingRecording == recording.path;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPlaying ? AppConstance.primary : Colors.grey[300],
          child: Icon(
            isPlaying ? Icons.equalizer : Icons.audiotrack,
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
                _playRecording(recording);
                break;
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
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Lire'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Renommer'),
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
        onTap: () => _playRecording(recording),
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
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
