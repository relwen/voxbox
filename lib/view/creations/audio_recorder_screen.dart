import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/widgets/widgets.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen>
    with TickerProviderStateMixin {
  final AudioRecorderService _recorderService = AudioRecorderService();
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  Duration _recordingDuration = Duration.zero;
  RecordingState _currentState = RecordingState.stopped;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<RecordingState>? _stateSubscription;
  
  bool _showWaveform = false;
  List<double> _waveformData = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSubscriptions();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await _recorderService.hasPermissions();
    if (!hasPermissions) {
      _showErrorSnackBar('Permissions requises pour l\'enregistrement audio');
    }
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
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupSubscriptions() {
    _durationSubscription = _recorderService.durationStream.listen((duration) {
      setState(() {
        _recordingDuration = duration;
      });
    });
    
    _stateSubscription = _recorderService.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
      
      if (state == RecordingState.recording) {
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        _showWaveform = true;
      } else {
        _pulseController.stop();
        _waveController.stop();
        if (state == RecordingState.stopped) {
          _showWaveform = false;
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
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      final success = await _recorderService.startRecording();
      if (!success) {
        _showErrorSnackBar('Impossible de démarrer l\'enregistrement. Vérifiez les permissions.');
      }
    } catch (e) {
      print('Erreur dans _startRecording: $e');
      final errorMessage = e.toString();
      
      // Si la permission est refusée de manière permanente, proposer d'ouvrir les paramètres
      if (errorMessage.contains('permanente') || errorMessage.contains('paramètres')) {
        _showPermissionErrorDialog();
      } else {
        _showErrorSnackBar('Erreur: $errorMessage');
      }
    }
  }
  
  void _showPermissionErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission microphone requise'),
          content: const Text(
            'L\'accès au microphone est nécessaire pour enregistrer de l\'audio. '
            'Veuillez activer la permission dans les paramètres de l\'application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Ouvrir les paramètres de l'application
                await openAppSettings();
              },
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pauseRecording() async {
    final success = await _recorderService.pauseRecording();
    if (!success) {
      _showErrorSnackBar('Impossible de mettre en pause');
    }
  }

  Future<void> _resumeRecording() async {
    final success = await _recorderService.resumeRecording();
    if (!success) {
      _showErrorSnackBar('Impossible de reprendre l\'enregistrement');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorderService.stopRecording();
    if (path != null) {
      _showSuccessSnackBar('Enregistrement sauvegardé');
      // Optionnel: naviguer vers la liste des enregistrements
    } else {
      _showErrorSnackBar('Erreur lors de la sauvegarde');
    }
  }

  Future<void> _cancelRecording() async {
    final success = await _recorderService.cancelRecording();
    if (success) {
      _showSuccessSnackBar('Enregistrement annulé');
    } else {
      _showErrorSnackBar('Erreur lors de l\'annulation');
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const MyText(
          text: 'Enregistreur Audio',
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () {
              // TODO: Naviguer vers la liste des enregistrements
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone de visualisation du waveform
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: _buildWaveformVisualizer(),
            ),
          ),
          
          // Affichage de la durée
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
              ],
            ),
          ),
          
          // Contrôles d'enregistrement
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              child: _buildRecordingControls(),
            ),
          ),
          
          // Contrôles supplémentaires
          Container(
            padding: const EdgeInsets.all(20),
            child: _buildAdditionalControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformVisualizer() {
    if (!_showWaveform) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                color: Colors.grey,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Appuyez sur le bouton pour commencer',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedBuilder(
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
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Annuler
        if (_currentState != RecordingState.stopped)
          _buildControlButton(
            icon: Icons.close,
            color: Colors.red,
            onPressed: _cancelRecording,
            size: 60,
          ),
        
        // Bouton principal (Enregistrer/Pause/Arrêter)
        _buildMainControlButton(),
        
        // Bouton Liste
        _buildControlButton(
          icon: Icons.list,
          color: Colors.blue,
          onPressed: () {
            // TODO: Naviguer vers la liste
          },
          size: 60,
        ),
      ],
    );
  }

  Widget _buildMainControlButton() {
    switch (_currentState) {
      case RecordingState.stopped:
        return _buildControlButton(
          icon: Icons.mic,
          color: Colors.red,
          onPressed: _startRecording,
          size: 80,
          isMain: true,
        );
      case RecordingState.recording:
        return _buildControlButton(
          icon: Icons.pause,
          color: Colors.orange,
          onPressed: _pauseRecording,
          size: 80,
          isMain: true,
        );
      case RecordingState.paused:
        return Row(
          children: [
            _buildControlButton(
              icon: Icons.play_arrow,
              color: Colors.green,
              onPressed: _resumeRecording,
              size: 60,
            ),
            const SizedBox(width: 20),
            _buildControlButton(
              icon: Icons.stop,
              color: Colors.red,
              onPressed: _stopRecording,
              size: 60,
            ),
          ],
        );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: isMain ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Transform.scale(
            scale: isMain ? _pulseAnimation.value : 1.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdditionalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAdditionalButton(
          icon: Icons.settings,
          label: 'Paramètres',
          onPressed: () {
            // TODO: Ouvrir les paramètres
          },
        ),
        _buildAdditionalButton(
          icon: Icons.folder,
          label: 'Dossier',
          onPressed: () {
            // TODO: Ouvrir le dossier des enregistrements
          },
        ),
        _buildAdditionalButton(
          icon: Icons.share,
          label: 'Partager',
          onPressed: () {
            // TODO: Partager l'enregistrement
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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

class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isRecording;

  WaveformPainter({required this.progress, required this.isRecording});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRecording ? Colors.red : Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final waveCount = 20;
    final waveWidth = size.width / waveCount;

    for (int i = 0; i < waveCount; i++) {
      final x = i * waveWidth + waveWidth / 2;
      final amplitude = (sin((i * 0.5 + progress * 10) * 3.14159) * 30).abs();
      
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
