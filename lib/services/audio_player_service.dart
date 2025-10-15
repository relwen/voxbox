import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:voxbox/models/vocalise.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Lecteur audio principal
  final audio_players.AudioPlayer _audioPlayer = audio_players.AudioPlayer();
  
  // État du lecteur
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Vocalise? _currentVocalise;
  List<Vocalise> _playlist = [];
  int _currentIndex = 0;

  // Streams pour l'état
  final StreamController<bool> _isPlayingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<Vocalise?> _currentVocaliseController = StreamController<Vocalise?>.broadcast();

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  Vocalise? get currentVocalise => _currentVocalise;
  List<Vocalise> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  // Streams
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<Vocalise?> get currentVocaliseStream => _currentVocaliseController.stream;

  // Initialisation
  void initialize() {
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
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

    // Écouter les changements d'état
    _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case audio_players.PlayerState.playing:
          _isPlaying = true;
          _isPaused = false;
          _isPlayingController.add(true);
          break;
        case audio_players.PlayerState.paused:
          _isPlaying = false;
          _isPaused = true;
          _isPlayingController.add(false);
          break;
        case audio_players.PlayerState.stopped:
          _isPlaying = false;
          _isPaused = false;
          _currentPosition = Duration.zero;
          _isPlayingController.add(false);
          _positionController.add(Duration.zero);
          break;
        case audio_players.PlayerState.completed:
          _isPlaying = false;
          _isPaused = false;
          _isPlayingController.add(false);
          _onTrackCompleted();
          break;
        default:
          break;
      }
    });
  }

  // Jouer une vocalise
  Future<void> playVocalise(Vocalise vocalise) async {
    try {
      _currentVocalise = vocalise;
      _currentVocaliseController.add(vocalise);

      String? audioUrl;
      
      // Vérifier si le fichier est téléchargé localement
      if (vocalise.isDownloaded && vocalise.localAudioPath != null) {
        audioUrl = vocalise.localAudioPath;
        print('🎵 Lecture du fichier local: $audioUrl');
      } else if (vocalise.audioUrl != null) {
        audioUrl = vocalise.audioUrl;
        print('🎵 Lecture du fichier distant: $audioUrl');
      } else {
        throw Exception('Aucun fichier audio disponible pour cette vocalise');
      }

      await _audioPlayer.play(audio_players.DeviceFileSource(audioUrl!));
      
    } catch (e) {
      print('❌ Erreur lors de la lecture: $e');
      throw Exception('Impossible de lire cette vocalise: $e');
    }
  }

  // Jouer une playlist
  Future<void> playPlaylist(List<Vocalise> vocalises, {int startIndex = 0}) async {
    _playlist = vocalises;
    _currentIndex = startIndex;
    
    if (_playlist.isNotEmpty) {
      await playVocalise(_playlist[_currentIndex]);
    }
  }

  // Contrôles de lecture
  Future<void> play() async {
    if (_isPaused) {
      await _audioPlayer.resume();
    } else if (_currentVocalise != null) {
      await playVocalise(_currentVocalise!);
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentVocalise = null;
    _currentVocaliseController.add(null);
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Navigation dans la playlist
  Future<void> nextTrack() async {
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await playVocalise(_playlist[_currentIndex]);
    }
  }

  Future<void> previousTrack() async {
    if (_playlist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      await playVocalise(_playlist[_currentIndex]);
    }
  }

  // Gestion de la fin de piste
  void _onTrackCompleted() {
    // Auto-play suivant si en mode playlist
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      nextTrack();
    }
  }

  // Obtenir le pourcentage de progression
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  // Formater le temps
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  // Nettoyage
  void dispose() {
    _audioPlayer.dispose();
    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _currentVocaliseController.close();
  }
}
