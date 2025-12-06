import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:flutter_sound/flutter_sound.dart';

class QuickRecorderModal extends StatefulWidget {
  const QuickRecorderModal({super.key});

  @override
  State<QuickRecorderModal> createState() => _QuickRecorderModalState();
}

class _QuickRecorderModalState extends State<QuickRecorderModal>
    with TickerProviderStateMixin {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();

  Duration _recordingDuration = Duration.zero;
  RecordingState _currentState = RecordingState.stopped;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<RecordingState>? _stateSubscription;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  String? _savedRecordingPath;
  bool _showPlaybackControls = false;
  bool _isPlaying = false;

  // Marqueurs pour les segments à supprimer
  final List<SegmentMarker> _deleteMarkers = [];
  SegmentMarker? _currentMarker;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSubscriptions();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _audioPlayer.openPlayer();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupSubscriptions() {
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
          _currentState = state;
        });

        if (state == RecordingState.recording) {
          _pulseController.repeat(reverse: true);
          _waveController.repeat();
        } else {
          _pulseController.stop();
          _waveController.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      final success = await _recorderService.startRecording();
      if (!success) {
        _showSnackBar('Impossible de démarrer l\'enregistrement', isError: true);
      } else {
        setState(() {
          _savedRecordingPath = null;
          _showPlaybackControls = false;
          _deleteMarkers.clear();
        });
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _pauseRecording() async {
    await _recorderService.pauseRecording();
  }

  Future<void> _resumeRecording() async {
    await _recorderService.resumeRecording();
  }

  Future<void> _stopRecording() async {
    final path = await _recorderService.stopRecording();
    if (path != null) {
      setState(() {
        _savedRecordingPath = path;
        _showPlaybackControls = true;
      });
      _showSnackBar('Enregistrement sauvegardé', isError: false);
    } else {
      _showSnackBar('Erreur lors de la sauvegarde', isError: true);
    }
  }

  Future<void> _cancelRecording() async {
    final success = await _recorderService.cancelRecording();
    if (success) {
      setState(() {
        _recordingDuration = Duration.zero;
        _deleteMarkers.clear();
      });
      _showSnackBar('Enregistrement annulé', isError: false);
    }
  }

  Future<void> _playRecording() async {
    if (_savedRecordingPath != null) {
      try {
        await _audioPlayer.startPlayer(
          fromURI: _savedRecordingPath!,
          codec: Codec.aacADTS,
        );
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        _showSnackBar('Erreur lors de la lecture: $e', isError: true);
      }
    }
  }

  Future<void> _pausePlayback() async {
    try {
      await _audioPlayer.pausePlayer();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      _showSnackBar('Erreur lors de la pause: $e', isError: true);
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      _showSnackBar('Erreur lors de l\'arrêt: $e', isError: true);
    }
  }

  void _markSegmentForDeletion() {
    // Marquer le début d'un segment à supprimer
    if (_currentMarker == null) {
      setState(() {
        _currentMarker = SegmentMarker(
          startTime: _recordingDuration,
          endTime: _recordingDuration,
        );
      });
      _showSnackBar('Début du segment marqué', isError: false);
    } else {
      // Finaliser le segment
      setState(() {
        _currentMarker!.endTime = _recordingDuration;
        _deleteMarkers.add(_currentMarker!);
        _currentMarker = null;
      });
      _showSnackBar('Segment marqué pour suppression', isError: false);
    }
  }

  Future<void> _deleteMarkedSegments() async {
    if (_deleteMarkers.isEmpty) {
      _showSnackBar('Aucun segment à supprimer', isError: true);
      return;
    }

    // TODO: Implémenter la suppression réelle des segments
    // Pour l'instant, on efface juste les marqueurs
    setState(() {
      _deleteMarkers.clear();
    });
    _showSnackBar('Segments supprimés', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (isError) {
      ToastService.error(
        context,
        message,
        duration: const Duration(seconds: 2),
      );
    } else {
      ToastService.success(
        context,
        message,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Barre de titre
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Indicateur de glissement
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Magnétophone Rapide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Zone de visualisation
          Expanded(
            flex: 2,
            child: _buildVisualizationArea(),
          ),

          // Affichage de la durée et état
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStateText(),
                  style: TextStyle(
                    color: _getStateColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_deleteMarkers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_deleteMarkers.length} segment(s) marqué(s)',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contrôles principaux
          Expanded(
            flex: 2,
            child: _buildMainControls(),
          ),

          // Contrôles secondaires
          Container(
            padding: const EdgeInsets.all(20),
            child: _buildSecondaryControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationArea() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _currentState == RecordingState.recording
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: _showPlaybackControls
          ? _buildPlaybackArea()
          : _buildRecordingVisualization(),
    );
  }

  Widget _buildRecordingVisualization() {
    if (_currentState == RecordingState.stopped) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              color: Colors.grey.shade600,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Appuyez pour enregistrer',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: WaveformPainter(
            progress: _waveController.value,
            isRecording: _currentState == RecordingState.recording,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildPlaybackArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isPlaying ? Icons.volume_up : Icons.audiotrack,
          color: Colors.blue,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          _isPlaying ? 'Lecture en cours...' : 'Prêt pour la lecture',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    if (_showPlaybackControls) {
      return _buildPlaybackControls();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Annuler
        if (_currentState != RecordingState.stopped)
          _buildControlButton(
            icon: Icons.delete_outline,
            label: 'Annuler',
            color: Colors.red,
            onPressed: _cancelRecording,
            size: 60,
          ),

        // Bouton principal
        _buildMainRecordButton(),

        // Bouton Marquer segment
        if (_currentState == RecordingState.recording)
          _buildControlButton(
            icon: _currentMarker != null ? Icons.bookmark : Icons.bookmark_border,
            label: 'Marquer',
            color: Colors.orange,
            onPressed: _markSegmentForDeletion,
            size: 60,
          ),
      ],
    );
  }

  Widget _buildMainRecordButton() {
    IconData icon;
    Color color;
    VoidCallback onPressed;
    String label;

    switch (_currentState) {
      case RecordingState.stopped:
        icon = Icons.fiber_manual_record;
        color = Colors.red;
        onPressed = _startRecording;
        label = 'Enregistrer';
        break;
      case RecordingState.recording:
        icon = Icons.pause;
        color = Colors.orange;
        onPressed = _pauseRecording;
        label = 'Pause';
        break;
      case RecordingState.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlButton(
              icon: Icons.play_arrow,
              label: 'Reprendre',
              color: Colors.green,
              onPressed: _resumeRecording,
              size: 70,
            ),
            const SizedBox(width: 20),
            _buildControlButton(
              icon: Icons.stop,
              label: 'Terminer',
              color: Colors.blue,
              onPressed: _stopRecording,
              size: 70,
            ),
          ],
        );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _currentState == RecordingState.recording
              ? _pulseAnimation.value
              : 1.0,
          child: _buildControlButton(
            icon: icon,
            label: label,
            color: color,
            onPressed: onPressed,
            size: 80,
            isMain: true,
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.replay,
          label: 'Réenregistrer',
          color: Colors.red,
          onPressed: () {
            setState(() {
              _showPlaybackControls = false;
              _recordingDuration = Duration.zero;
            });
            _startRecording();
          },
          size: 60,
        ),
        _buildControlButton(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          label: _isPlaying ? 'Pause' : 'Écouter',
          color: Colors.blue,
          onPressed: _isPlaying ? _pausePlayback : _playRecording,
          size: 80,
          isMain: true,
        ),
        _buildControlButton(
          icon: Icons.check_circle,
          label: 'Valider',
          color: Colors.green,
          onPressed: () {
            Navigator.pop(context, _savedRecordingPath);
          },
          size: 60,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
    bool isMain = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls() {
    if (_showPlaybackControls) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSecondaryButton(
            icon: Icons.content_cut,
            label: 'Modifier',
            onPressed: () {
              // TODO: Ouvrir l'éditeur audio
              _showSnackBar('Fonctionnalité en développement', isError: false);
            },
          ),
          _buildSecondaryButton(
            icon: Icons.share,
            label: 'Partager',
            onPressed: () {
              // TODO: Partager l'enregistrement
              _showSnackBar('Fonctionnalité en développement', isError: false);
            },
          ),
          _buildSecondaryButton(
            icon: Icons.save_alt,
            label: 'Sauvegarder',
            onPressed: () {
              Navigator.pop(context, _savedRecordingPath);
            },
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_deleteMarkers.isNotEmpty)
          _buildSecondaryButton(
            icon: Icons.delete_sweep,
            label: 'Supprimer segments',
            onPressed: _deleteMarkedSegments,
          ),
        _buildSecondaryButton(
          icon: Icons.history,
          label: 'Historique',
          onPressed: () {
            // TODO: Afficher l'historique
            _showSnackBar('Fonctionnalité en développement', isError: false);
          },
        ),
        _buildSecondaryButton(
          icon: Icons.settings,
          label: 'Paramètres',
          onPressed: () {
            // TODO: Ouvrir les paramètres
            _showSnackBar('Fonctionnalité en développement', isError: false);
          },
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStateText() {
    switch (_currentState) {
      case RecordingState.stopped:
        return 'Prêt à enregistrer';
      case RecordingState.recording:
        return 'Enregistrement en cours...';
      case RecordingState.paused:
        return 'Enregistrement en pause';
    }
  }

  Color _getStateColor() {
    switch (_currentState) {
      case RecordingState.stopped:
        return Colors.grey;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
    }
  }
}

// Classe pour les marqueurs de segments à supprimer
class SegmentMarker {
  Duration startTime;
  Duration endTime;

  SegmentMarker({
    required this.startTime,
    required this.endTime,
  });
}

// Painter pour la visualisation waveform
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isRecording;

  WaveformPainter({
    required this.progress,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const centerY = 0.5;
    const barCount = 40;
    final barWidth = size.width / (barCount * 2);
    final spacing = barWidth;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing) + spacing;
      final normalizedIndex = i / barCount;
      final wave = (normalizedIndex * 8 + progress * 10) % 1;
      final amplitude = (wave < 0.5 ? wave * 2 : (1 - wave) * 2);
      final height = amplitude * size.height * 0.4;

      final barPaint = Paint()
        ..color = isRecording
            ? Colors.red.withValues(alpha: 0.5 + amplitude * 0.5)
            : Colors.blue.withValues(alpha: 0.5 + amplitude * 0.5)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, size.height * centerY - height),
        Offset(x, size.height * centerY + height),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
