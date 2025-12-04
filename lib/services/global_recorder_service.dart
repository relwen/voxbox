import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voxbox/services/audio_recorder_service.dart';

/// Service global pour gérer l'enregistrement audio en arrière-plan
class GlobalRecorderService extends ChangeNotifier {
  static final GlobalRecorderService _instance = GlobalRecorderService._internal();
  factory GlobalRecorderService() => _instance;
  GlobalRecorderService._internal();

  final AudioRecorderService _recorderService = AudioRecorderService();

  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;

  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<RecordingState>? _stateSubscription;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  RecordingState get recordingState {
    if (_isRecording && !_isPaused) return RecordingState.recording;
    if (_isRecording && _isPaused) return RecordingState.paused;
    return RecordingState.stopped;
  }

  void initialize() {
    _durationSubscription = _recorderService.durationStream.listen((duration) {
      _recordingDuration = duration;
      notifyListeners();
    });

    _stateSubscription = _recorderService.stateStream.listen((state) {
      switch (state) {
        case RecordingState.recording:
          _isRecording = true;
          _isPaused = false;
          break;
        case RecordingState.paused:
          _isRecording = true;
          _isPaused = true;
          break;
        case RecordingState.stopped:
          _isRecording = false;
          _isPaused = false;
          _recordingDuration = Duration.zero;
          break;
      }
      notifyListeners();
    });
  }

  /// Démarre un nouvel enregistrement
  Future<bool> startRecording() async {
    try {
      final success = await _recorderService.startRecording();
      if (success) {
        _isRecording = true;
        _isPaused = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Erreur lors du démarrage: $e');
      return false;
    }
  }

  /// Met en pause l'enregistrement
  Future<bool> pauseRecording() async {
    final success = await _recorderService.pauseRecording();
    if (success) {
      _isPaused = true;
      notifyListeners();
    }
    return success;
  }

  /// Reprend l'enregistrement
  Future<bool> resumeRecording() async {
    final success = await _recorderService.resumeRecording();
    if (success) {
      _isPaused = false;
      notifyListeners();
    }
    return success;
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    final path = await _recorderService.stopRecording();
    if (path != null) {
      _currentRecordingPath = path;
      _isRecording = false;
      _isPaused = false;
      notifyListeners();
    }
    return path;
  }

  /// Annule l'enregistrement en cours
  Future<bool> cancelRecording() async {
    final success = await _recorderService.cancelRecording();
    if (success) {
      _isRecording = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;
      notifyListeners();
    }
    return success;
  }

  /// Obtient la liste des enregistrements
  Future<List<AudioRecording>> getRecordings() async {
    return await _recorderService.getRecordings();
  }

  /// Supprime un enregistrement
  Future<bool> deleteRecording(String filePath) async {
    return await _recorderService.deleteRecording(filePath);
  }

  /// Renomme un enregistrement
  Future<bool> renameRecording(String oldPath, String newName) async {
    return await _recorderService.renameRecording(oldPath, newName);
  }

  /// Formate la durée au format MM:SS
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
