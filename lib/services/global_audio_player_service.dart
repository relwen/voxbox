import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Service global pour la lecture audio persistante à travers toute l'application
class GlobalAudioPlayerService {
  static final GlobalAudioPlayerService _instance = GlobalAudioPlayerService._internal();
  factory GlobalAudioPlayerService() => _instance;
  GlobalAudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // État du lecteur
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _currentAudioPath;
  String? _currentAudioTitle;

  // Streams pour notifier les changements
  final StreamController<bool> _isPlayingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<AudioInfo?> _audioInfoController = StreamController<AudioInfo?>.broadcast();

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get currentAudioPath => _currentAudioPath;
  String? get currentAudioTitle => _currentAudioTitle;
  bool get hasAudio => _currentAudioPath != null;

  // Streams
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<AudioInfo?> get audioInfoStream => _audioInfoController.stream;

  void initialize() {
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Écouter les changements d'état
    _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _isPlaying = true;
          _isPaused = false;
          _isPlayingController.add(true);
          break;
        case PlayerState.paused:
          _isPlaying = false;
          _isPaused = true;
          _isPlayingController.add(false);
          break;
        case PlayerState.stopped:
          _isPlaying = false;
          _isPaused = false;
          _currentPosition = Duration.zero;
          _isPlayingController.add(false);
          _positionController.add(Duration.zero);
          break;
        case PlayerState.completed:
          _isPlaying = false;
          _isPaused = false;
          _isPlayingController.add(false);
          break;
        default:
          break;
      }
    });

    // Écouter les changements de position
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    // Écouter les changements de durée
    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      _durationController.add(duration);
    });
  }

  /// Jouer un fichier audio
  Future<void> playAudio(String path, {String? title}) async {
    try {
      _currentAudioPath = path;
      _currentAudioTitle = title ?? _extractFileName(path);

      await _audioPlayer.play(DeviceFileSource(path));

      _audioInfoController.add(AudioInfo(
        path: path,
        title: _currentAudioTitle!,
      ));
    } catch (e) {
      print('Erreur lors de la lecture: $e');
      rethrow;
    }
  }

  /// Play/Resume
  Future<void> play() async {
    if (_isPaused) {
      await _audioPlayer.resume();
    }
  }

  /// Pause
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Stop et réinitialiser
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentAudioPath = null;
    _currentAudioTitle = null;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _audioInfoController.add(null);
  }

  /// Seek vers une position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Avancer de X secondes
  Future<void> seekForward({int seconds = 10}) async {
    final newPosition = _currentPosition + Duration(seconds: seconds);
    if (newPosition < _totalDuration) {
      await seek(newPosition);
    } else {
      await seek(_totalDuration);
    }
  }

  /// Reculer de X secondes
  Future<void> seekBackward({int seconds = 10}) async {
    final newPosition = _currentPosition - Duration(seconds: seconds);
    if (newPosition > Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  /// Obtenir le pourcentage de progression
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Formater la durée
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Extraire le nom du fichier depuis le chemin
  String _extractFileName(String path) {
    return path.split('/').last.replaceAll('.aac', '').replaceAll('.m4a', '').replaceAll('.mp3', '');
  }

  /// Nettoyage
  void dispose() {
    _audioPlayer.dispose();
    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _audioInfoController.close();
  }
}

/// Classe pour stocker les informations audio
class AudioInfo {
  final String path;
  final String title;

  AudioInfo({
    required this.path,
    required this.title,
  });
}
