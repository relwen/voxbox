import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:voxbox/services/global_recorder_service.dart';
import 'package:voxbox/services/toast_service.dart';

/// Écran d'enregistrement rapide
class QuickRecordScreen extends StatefulWidget {
  const QuickRecordScreen({super.key});

  @override
  State<QuickRecordScreen> createState() => _QuickRecordScreenState();
}

class _QuickRecordScreenState extends State<QuickRecordScreen>
    with SingleTickerProviderStateMixin {
  final GlobalRecorderService _recorderService = GlobalRecorderService();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isRecording = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializePlayer();
    _setupListener();
    _startRecording();
  }

  Future<void> _initializePlayer() async {
    await _audioPlayer.openPlayer();
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _setupListener() {
    _recorderService.addListener(_onRecordingStateChanged);
  }

  void _onRecordingStateChanged() {
    if (mounted) {
      setState(() {
        _isRecording = _recorderService.isRecording;
        _isPaused = _recorderService.isPaused;
        _duration = _recorderService.recordingDuration;
      });
    }
  }

  Future<void> _startRecording() async {
    final success = await _recorderService.startRecording();
    if (!success && mounted) {
      Navigator.pop(context);
      ToastService.error(
        context,
        'Impossible de démarrer l\'enregistrement',
      );
    }
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      // Arrêter la lecture si elle est en cours
      if (_isPlaying) {
        await _stopPlayback();
      }
      await _recorderService.resumeRecording();
    } else {
      await _recorderService.pauseRecording();
    }
  }

  Future<void> _playPreview() async {
    if (!_isPlayerInitialized || !_isPaused) return;

    final path = _recorderService.currentRecordingPath;
    if (path == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.startPlayer(
          fromURI: path,
          codec: Codec.aacADTS,
          whenFinished: () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
              });
            }
          },
        );
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService.error(
          context,
          'Erreur de lecture: $e',
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    if (_isPlaying) {
      await _audioPlayer.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorderService.stopRecording();
    if (path != null && mounted) {
      Navigator.pop(context);
      ToastService.success(
        context,
        'Enregistrement sauvegardé dans Créations',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _cancelRecording() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Annuler l\'enregistrement',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Voulez-vous vraiment annuler cet enregistrement ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _recorderService.cancelRecording();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _recorderService.removeListener(_onRecordingStateChanged);
    _pulseController.dispose();
    _audioPlayer.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isRecording)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _cancelRecording,
                tooltip: 'Annuler l\'enregistrement',
              ),
          ],
          title: const Text(
            'Enregistrement',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.grey[900]!,
                Colors.black,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Indicateur d'enregistrement animé
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercles pulsants
                        if (_isRecording && !_isPaused) ...[
                          Transform.scale(
                            scale: _pulseAnimation.value * 1.5,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _pulseAnimation.value * 1.2,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Cercle principal
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isPaused
                                  ? [Colors.orange.shade600, Colors.orange.shade800]
                                  : [Colors.red.shade600, Colors.red.shade800],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isPaused ? Colors.orange : Colors.red)
                                    .withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPaused ? Icons.pause : Icons.mic,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Durée
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Statut
                Text(
                  _isPaused ? 'En pause' : 'Enregistrement en cours...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // Bouton d'écoute (uniquement en pause)
                if (_isPaused)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _playPreview,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.stop : Icons.headphones,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isPlaying ? 'Arrêter l\'écoute' : 'Écouter',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),

                // Boutons de contrôle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Bouton Pause/Reprendre
                    _buildControlButton(
                      icon: _isPaused ? Icons.play_arrow : Icons.pause,
                      label: _isPaused ? 'Reprendre' : 'Pause',
                      color: Colors.orange,
                      onPressed: _togglePause,
                    ),

                    // Bouton Terminer
                    _buildControlButton(
                      icon: Icons.check_circle,
                      label: 'Terminer',
                      color: Colors.green,
                      onPressed: _stopRecording,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
