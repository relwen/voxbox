import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/services/global_recorder_service.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/view/creations/recordings_history_sheet.dart';
import 'package:voxbox/view/creations/folders_screen.dart';

class CreationsScreen extends StatefulWidget {
  const CreationsScreen({super.key});

  @override
  State<CreationsScreen> createState() => _CreationsScreenState();
}

class _CreationsScreenState extends State<CreationsScreen>
    with TickerProviderStateMixin {
  final GlobalRecorderService _globalRecorderService = GlobalRecorderService();
  final AudioRecorderService _recorderService = AudioRecorderService();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  Duration _recordingDuration = Duration.zero;
  RecordingState _currentState = RecordingState.stopped;
  StreamSubscription<List<double>>? _waveformSubscription;

  bool _showWaveform = false;
  List<double> _waveformData = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSubscriptions();
    _checkPermissions();
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
    // Écouter les changements de l'enregistreur global
    _globalRecorderService.addListener(_onRecorderStateChanged);

    _waveformSubscription = _recorderService.waveformStream.listen((waveformData) {
      if (mounted) {
        setState(() {
          _waveformData = waveformData;
        });
      }
    });
  }

  void _onRecorderStateChanged() {
    if (mounted) {
      setState(() {
        _recordingDuration = _globalRecorderService.recordingDuration;
        _currentState = _globalRecorderService.recordingState;
      });

      if (_currentState == RecordingState.recording) {
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        _showWaveform = true;
      } else {
        _pulseController.stop();
        _waveController.stop();
        if (_currentState == RecordingState.stopped) {
          _showWaveform = false;
          _waveformData.clear();
        }
      }
    }
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await _recorderService.hasPermissions();
    if (!hasPermissions) {
      _showErrorSnackBar('Permissions requises pour l\'enregistrement audio');
    }
  }


  @override
  void dispose() {
    _globalRecorderService.removeListener(_onRecorderStateChanged);
    _waveformSubscription?.cancel();
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
      final success = await _globalRecorderService.startRecording();
      if (!success) {
        _showErrorSnackBar('Impossible de démarrer l\'enregistrement. Vérifiez les permissions.');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }
  }

  Future<void> _pauseRecording() async {
    final success = await _globalRecorderService.pauseRecording();
    if (!success) {
      _showErrorSnackBar('Impossible de mettre en pause');
    }
  }

  Future<void> _resumeRecording() async {
    final success = await _globalRecorderService.resumeRecording();
    if (!success) {
      _showErrorSnackBar('Impossible de reprendre l\'enregistrement');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _globalRecorderService.stopRecording();
    if (path != null) {
      _showSuccessSnackBar('Enregistrement sauvegardé');
      // Rafraîchir l'historique
      setState(() {});
    } else {
      _showErrorSnackBar('Erreur lors de la sauvegarde');
    }
  }

  Future<void> _cancelRecording() async {
    final success = await _globalRecorderService.cancelRecording();
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
      appBar: AppBar(
        title: const MyText(
          text: "Studio de Création",
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        elevation: 0,
        actions: [
          // Bouton dossiers
          IconButton(
            icon: const Icon(Icons.folder, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FoldersScreen()),
              );
            },
            tooltip: 'Mes dossiers',
          ),
          // Indicateur de nouveaux enregistrements
          FutureBuilder<List<AudioRecording>>(
            future: _globalRecorderService.getRecordings(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white),
                      tooltip: '${snapshot.data!.length} enregistrement(s)',
                      onPressed: () {
                        // Scroll vers le bas pour montrer l'historique
                        // TODO: Implémenter le scroll automatique
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${snapshot.data!.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Interface principale d'enregistrement
          Expanded(
            flex: 3, // 75% de l'espace
            child: _buildMainRecordingInterface(),
          ),
          
          // Historique en bas (toujours visible)
          Expanded(
            flex: 1, // 25% de l'espace
            child: _buildHistorySheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRecordingInterface() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.black,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Column(
        children: [
          // Zone de visualisation du waveform
          Expanded(
            flex: 3,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStateColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _getStateColor().withOpacity(0.5)),
                  ),
                  child: Text(
                    _getStateText(),
                    style: TextStyle(
                      color: _getStateColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[800]!,
              Colors.grey[900]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Prêt à enregistrer',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Appuyez sur le bouton pour commencer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: RealWaveformPainter(
            waveformData: _waveformData,
            isRecording: _currentState == RecordingState.recording,
            isPaused: _currentState == RecordingState.paused,
          ),
          size: Size.infinite,
        ),
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
        
        // Bouton Édition
        _buildControlButton(
          icon: Icons.edit,
          color: Colors.blue,
          onPressed: () {
            // TODO: Ouvrir l'éditeur audio
            _showErrorSnackBar('Éditeur audio en cours de développement');
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
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAdditionalButton(
            icon: Icons.edit,
            label: 'Éditer',
            onPressed: () {
              if (_globalRecorderService.currentRecordingPath != null) {
                // TODO: Ouvrir l'éditeur avec le fichier en cours
                _showErrorSnackBar('Éditeur audio en cours de développement');
              } else {
                _showErrorSnackBar('Aucun enregistrement en cours');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                if (hasNotification)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle de drag plus visible
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Contenu de l'historique avec scroll
          Expanded(
            child: RecordingsHistorySheet(
              scrollController: ScrollController(),
              onClose: () {
                // Pas besoin de fermer, l'historique reste toujours visible
              },
            ),
          ),
        ],
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

class RealWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final bool isRecording;
  final bool isPaused;

  RealWaveformPainter({
    required this.waveformData,
    required this.isRecording,
    required this.isPaused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final centerY = size.height / 2;
    final waveCount = waveformData.length;
    final waveWidth = size.width / waveCount;
    
    // Couleurs selon l'état
    Color primaryColor;
    Color secondaryColor;
    
    if (isRecording) {
      primaryColor = Colors.red;
      secondaryColor = Colors.red.withOpacity(0.3);
    } else if (isPaused) {
      primaryColor = Colors.orange;
      secondaryColor = Colors.orange.withOpacity(0.3);
    } else {
      primaryColor = Colors.blue;
      secondaryColor = Colors.blue.withOpacity(0.3);
    }

    // Dessiner le waveform
    for (int i = 0; i < waveCount; i++) {
      final x = i * waveWidth + waveWidth / 2;
      final amplitude = waveformData[i] * (size.height * 0.4); // 40% de la hauteur
      
      // Barre principale
      final mainPaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        mainPaint,
      );
      
      // Effet de glow
      final glowPaint = Paint()
        ..color = secondaryColor
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        glowPaint,
      );
    }
    
    // Ligne centrale
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}