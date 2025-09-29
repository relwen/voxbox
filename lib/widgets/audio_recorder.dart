import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voxbox/functions/styles.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File audioFile)? onRecordingComplete;
  final String? initialAudioPath;

  const VoiceRecorderWidget({
    Key? key,
    this.onRecordingComplete,
    this.initialAudioPath,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasPermission = false;
  String? _recordingPath;
  List<String> _recordingSegments = [];
  int _currentSegmentIndex = -1;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    if (widget.initialAudioPath != null) {
      _recordingPath = widget.initialAudioPath;
    }
  }

  Future<void> _checkPermission() async {
    final permission = await Permission.microphone.request();
    setState(() {
      _hasPermission = permission.isGranted;
    });
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkPermission();
      return;
    }

    try {
      // Version simplifiée - simulation d'enregistrement
      String fileName = 'audio_segment_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingPath = fileName;
        _currentSegmentIndex = _recordingSegments.length;
        _recordingSegments.add(fileName);
      });

      // Démarrer le timer pour la durée
      _startTimer();
      
      // Simuler un enregistrement de 3 secondes pour le test
      Future.delayed(Duration(seconds: 3), () {
        if (_isRecording) {
          _stopRecording();
        }
      });
      
    } catch (e) {
      print('Erreur lors du démarrage de l\'enregistrement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du démarrage de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pauseRecording() async {
    if (!_isRecording) return;

    try {
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      print('Erreur lors de la pause: $e');
    }
  }

  Future<void> _resumeRecording() async {
    if (!_isPaused) return;

    try {
      setState(() {
        _isPaused = false;
      });
    } catch (e) {
      print('Erreur lors de la reprise: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingDuration = Duration.zero;
      });

      if (_recordingPath != null && widget.onRecordingComplete != null) {
        // Créer un fichier temporaire pour la simulation
        final tempFile = File('/tmp/${_recordingPath}');
        await tempFile.writeAsString('Simulation audio file');
        widget.onRecordingComplete!(tempFile);
      }
    } catch (e) {
      print('Erreur lors de l\'arrêt: $e');
    }
  }

  Future<void> _replaceCurrentSegment() async {
    if (_currentSegmentIndex < 0 || _currentSegmentIndex >= _recordingSegments.length) return;

    // Arrêter l'enregistrement actuel
    if (_isRecording) {
      await _stopRecording();
    }

    // Supprimer le segment actuel
    setState(() {
      _recordingSegments.removeAt(_currentSegmentIndex);
      _isRecording = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;
    });

    // Démarrer un nouvel enregistrement
    await _startRecording();
  }

  Future<void> _deleteCurrentSegment() async {
    if (_currentSegmentIndex < 0 || _currentSegmentIndex >= _recordingSegments.length) return;

    // Arrêter l'enregistrement actuel
    if (_isRecording) {
      await _stopRecording();
    }

    setState(() {
      _recordingSegments.removeAt(_currentSegmentIndex);
      _isRecording = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;
      _currentSegmentIndex = -1;
    });
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isRecording && !_isPaused) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
        _startTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Affichage de la durée
        if (_isRecording || _recordingSegments.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme,
              ),
            ),
          ),

        // Liste des segments
        if (_recordingSegments.isNotEmpty)
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recordingSegments.length,
              itemBuilder: (context, index) {
                bool isCurrentSegment = index == _currentSegmentIndex;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentSegment ? theme : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentSegment ? theme : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Segment ${index + 1}',
                        style: TextStyle(
                          color: isCurrentSegment ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (isCurrentSegment && _isRecording)
                        Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 16,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

        SizedBox(height: 16),

        // Contrôles d'enregistrement
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton Play/Pause
            if (_isRecording)
              IconButton(
                onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                icon: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  size: 32,
                  color: theme,
                ),
              ),

            // Bouton Record/Stop
            IconButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 32,
                color: _isRecording ? Colors.red : theme,
              ),
            ),

            // Bouton Replace (remplacer le segment actuel)
            if (_currentSegmentIndex >= 0)
              IconButton(
                onPressed: _replaceCurrentSegment,
                icon: Icon(
                  Icons.refresh,
                  size: 32,
                  color: Colors.orange,
                ),
                tooltip: 'Remplacer ce segment',
              ),

            // Bouton Delete (supprimer le segment actuel)
            if (_currentSegmentIndex >= 0)
              IconButton(
                onPressed: _deleteCurrentSegment,
                icon: Icon(
                  Icons.delete,
                  size: 32,
                  color: Colors.red,
                ),
                tooltip: 'Supprimer ce segment',
              ),
          ],
        ),

        SizedBox(height: 16),

        // Instructions
        Container(
          padding: EdgeInsets.all(16),
          child: Text(
            _isRecording 
                ? 'Enregistrement en cours... (Version de démonstration)'
                : 'Appuyez sur le bouton micro pour commencer l\'enregistrement (Démo)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),

        // Statut des permissions
        if (!_hasPermission)
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'Permission microphone requise pour l\'enregistrement',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}