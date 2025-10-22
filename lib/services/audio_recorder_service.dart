import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as path;
import 'package:voxbox/services/audio_visualizer_service.dart';

class AudioRecorderService {
  static final AudioRecorderService _instance = AudioRecorderService._internal();
  factory AudioRecorderService() => _instance;
  AudioRecorderService._internal();

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final AudioVisualizerService _visualizerService = AudioVisualizerService();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  StreamController<RecordingState> _stateController = StreamController<RecordingState>.broadcast();

  // Getters
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<List<double>> get waveformStream => _visualizerService.waveformStream;

  /// Demande les permissions nécessaires
  Future<bool> requestPermissions() async {
    try {
      // Demander la permission microphone (obligatoire)
      final microphoneStatus = await Permission.microphone.request();
      
      print('Permissions - Microphone: $microphoneStatus');
      
      // Pour l'enregistrement audio, seule la permission microphone est nécessaire
      // Le stockage interne de l'application ne nécessite pas de permission
      return microphoneStatus.isGranted;
    } catch (e) {
      print('Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  /// Vérifie si les permissions sont accordées
  Future<bool> hasPermissions() async {
    try {
      final microphonePermission = await Permission.microphone.isGranted;
      
      print('Permissions actuelles - Microphone: $microphonePermission');
      
      // Pour l'enregistrement audio, seule la permission microphone est nécessaire
      // Le stockage interne de l'application ne nécessite pas de permission
      return microphonePermission;
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  /// Initialise l'enregistreur
  Future<void> _initializeRecorder() async {
    await _audioRecorder.openRecorder();
  }

  /// Démarre l'enregistrement
  Future<bool> startRecording({String? fileName}) async {
    try {
      print('🎙️ Démarrage de l\'enregistrement...');
      
      if (_isRecording) {
        print('❌ Enregistrement déjà en cours');
        return false;
      }

      // Vérifier les permissions
      print('🔐 Vérification des permissions...');
      if (!await hasPermissions()) {
        print('⚠️ Permissions non accordées, demande en cours...');
        if (!await requestPermissions()) {
          print('❌ Permission microphone refusée par l\'utilisateur');
          throw Exception('Permission microphone requise. Veuillez autoriser l\'accès au microphone dans les paramètres de l\'application.');
        }
      }
      print('✅ Permissions accordées');

      // Initialiser l'enregistreur
      print('🔧 Initialisation de l\'enregistreur...');
      await _initializeRecorder();
      print('✅ Enregistreur initialisé');

      // Créer le répertoire d'enregistrement
      print('📁 Création du répertoire d\'enregistrement...');
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(path.join(directory.path, 'recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
        print('✅ Répertoire créé: ${recordingsDir.path}');
      } else {
        print('✅ Répertoire existe: ${recordingsDir.path}');
      }

      // Générer le nom de fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'recording_$timestamp.aac';
      _currentRecordingPath = path.join(recordingsDir.path, finalFileName);
      print('📄 Fichier d\'enregistrement: $_currentRecordingPath');

      // Démarrer l'enregistrement
      print('🎵 Démarrage de l\'enregistrement audio...');
      await _audioRecorder.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

          _isRecording = true;
          _isPaused = false;
          _recordingDuration = Duration.zero;
          _startDurationTimer();
          _visualizerService.startVisualization();
          _stateController.add(RecordingState.recording);

          print('✅ Enregistrement démarré avec succès');
          return true;
    } catch (e) {
      print('❌ Erreur lors du démarrage de l\'enregistrement: $e');
      return false;
    }
  }

  /// Met en pause l'enregistrement
  Future<bool> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) return false;

          await _audioRecorder.pauseRecorder();
          _isPaused = true;
          _recordingTimer?.cancel();
          _visualizerService.stopVisualization();
          _stateController.add(RecordingState.paused);

          return true;
    } catch (e) {
      print('Erreur lors de la pause: $e');
      return false;
    }
  }

  /// Reprend l'enregistrement
  Future<bool> resumeRecording() async {
    try {
      if (!_isRecording || !_isPaused) return false;

          await _audioRecorder.resumeRecorder();
          _isPaused = false;
          _startDurationTimer();
          _visualizerService.startVisualization();
          _stateController.add(RecordingState.recording);

          return true;
    } catch (e) {
      print('Erreur lors de la reprise: $e');
      return false;
    }
  }

  /// Arrête l'enregistrement
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

          await _audioRecorder.stopRecorder();
          _isRecording = false;
          _isPaused = false;
          _recordingTimer?.cancel();
          _visualizerService.stopVisualization();
          _stateController.add(RecordingState.stopped);

          return _currentRecordingPath;
    } catch (e) {
      print('Erreur lors de l\'arrêt: $e');
      return null;
    }
  }

  /// Annule l'enregistrement en cours
  Future<bool> cancelRecording() async {
    try {
      if (!_isRecording) return false;

      await _audioRecorder.stopRecorder();
      _isRecording = false;
      _isPaused = false;
      _recordingTimer?.cancel();
      
      // Supprimer le fichier s'il existe
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
          _currentRecordingPath = null;
          _recordingDuration = Duration.zero;
          _visualizerService.stopVisualization();
          _stateController.add(RecordingState.stopped);

          return true;
    } catch (e) {
      print('Erreur lors de l\'annulation: $e');
      return false;
    }
  }

  /// Remplace une partie de l'enregistrement (écrase à partir d'une position)
  Future<bool> replaceFromPosition(Duration position) async {
    try {
      if (!_isRecording || _currentRecordingPath == null) return false;

      // Arrêter l'enregistrement actuel
      await stopRecording();

      // Redémarrer l'enregistrement avec un nouveau fichier
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(path.join(directory.path, 'recordings'));
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = 'recording_$timestamp.aac';
      _currentRecordingPath = path.join(recordingsDir.path, newFileName);

      await _audioRecorder.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      _isPaused = false;
      _recordingDuration = position;
      _startDurationTimer();
      _stateController.add(RecordingState.recording);

      return true;
    } catch (e) {
      print('Erreur lors du remplacement: $e');
      return false;
    }
  }

  /// Démarre le timer de durée
  void _startDurationTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isRecording && !_isPaused) {
        _recordingDuration = Duration(
          milliseconds: _recordingDuration.inMilliseconds + 100,
        );
        _durationController.add(_recordingDuration);
      }
    });
  }

  /// Obtient la liste des enregistrements
  Future<List<AudioRecording>> getRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(path.join(directory.path, 'recordings'));
      
      if (!await recordingsDir.exists()) {
        return [];
      }

      final files = await recordingsDir.list().toList();
      final recordings = <AudioRecording>[];

      for (final file in files) {
        if (file is File && (file.path.endsWith('.aac') || file.path.endsWith('.m4a'))) {
          final stat = await file.stat();
          recordings.add(AudioRecording(
            name: path.basename(file.path),
            path: file.path,
            duration: Duration.zero, // TODO: Calculer la durée réelle
            size: stat.size,
            createdAt: stat.modified,
          ));
        }
      }

      // Trier par date de création (plus récent en premier)
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return recordings;
    } catch (e) {
      print('Erreur lors de la récupération des enregistrements: $e');
      return [];
    }
  }

  /// Supprime un enregistrement
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Renomme un enregistrement
  Future<bool> renameRecording(String oldPath, String newName) async {
    try {
      final oldFile = File(oldPath);
      if (!await oldFile.exists()) return false;

          final directory = path.dirname(oldPath);
          final extension = path.extension(oldPath);
          final newPath = path.join(directory, '$newName$extension');

          await oldFile.rename(newPath);
          return true;
    } catch (e) {
      print('Erreur lors du renommage: $e');
      return false;
    }
  }

  /// Libère les ressources
  void dispose() {
    _recordingTimer?.cancel();
    _durationController.close();
    _stateController.close();
    _visualizerService.dispose();
    _audioRecorder.closeRecorder();
  }
}

/// État de l'enregistrement
enum RecordingState {
  stopped,
  recording,
  paused,
}

/// Modèle pour un enregistrement audio
class AudioRecording {
  final String name;
  final String path;
  final Duration duration;
  final int size;
  final DateTime createdAt;

  AudioRecording({
    required this.name,
    required this.path,
    required this.duration,
    required this.size,
    required this.createdAt,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
