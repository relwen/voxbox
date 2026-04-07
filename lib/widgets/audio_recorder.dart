import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/services/audio_recorder_service.dart';

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
  final AudioRecorderService _recorderService = AudioRecorderService();
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<RecordingState>? _stateSubscription;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasPermission = false;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _hasPermission = await _recorderService.hasPermissions();
    if (!_hasPermission) {
      _hasPermission = await _recorderService.requestPermissions();
    }

    _durationSubscription = _recorderService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _recordingDuration = duration;
        });
      }
    });

    _stateSubscription = _recorderService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isRecording = state == RecordingState.recording || state == RecordingState.paused;
          _isPaused = state == RecordingState.paused;
        });
      }
    });

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final success = await _recorderService.startRecording();
      if (!success) {
        throw Exception('Impossible de démarrer l\'enregistrement');
      }
    } catch (e) {
      debugPrint('Erreur lors du démarrage de l\'enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _recorderService.pauseRecording();
  }

  Future<void> _resumeRecording() async {
    await _recorderService.resumeRecording();
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorderService.stopRecording();
      if (path != null && widget.onRecordingComplete != null) {
        widget.onRecordingComplete!(File(path));
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt: $e');
    }
  }

  Future<void> _cancelRecording() async {
    await _recorderService.cancelRecording();
    if (mounted) {
      setState(() {
        _recordingDuration = Duration.zero;
      });
    }
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
        if (_isRecording || _recordingDuration > Duration.zero)
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme,
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Contrôles d'enregistrement
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton Annuler
            if (_isRecording)
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 32,
                  color: Colors.grey,
                ),
                tooltip: 'Annuler',
              ),

            // Bouton Record/Stop
            GestureDetector(
              onTap: _isRecording && !_isPaused ? _stopRecording : _startRecording,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording && !_isPaused ? Colors.red : theme,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording && !_isPaused ? Colors.red : theme).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording && !_isPaused ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),

            // Bouton Play/Pause
            if (_isRecording)
              IconButton(
                onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                icon: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 32,
                  color: theme,
                ),
                tooltip: _isPaused ? 'Reprendre' : 'Pause',
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            _isRecording 
                ? (_isPaused ? 'Enregistrement en pause' : 'Enregistrement en cours...')
                : 'Appuyez sur le micro pour enregistrer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Statut des permissions
        if (!_hasPermission)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Permission microphone requise pour l\'enregistrement',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}