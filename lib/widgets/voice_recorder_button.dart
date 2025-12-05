import 'package:flutter/material.dart';
import 'package:voxbox/services/global_recorder_service.dart';

/// Bouton d'enregistrement vocal style WhatsApp
/// - Maintenir appuyé: enregistrer
/// - Glisser vers le haut: verrouiller l'enregistrement
/// - Relâcher: envoyer
/// - Glisser vers la gauche: annuler
class VoiceRecorderButton extends StatefulWidget {
  final VoidCallback? onRecordingComplete;

  const VoiceRecorderButton({
    super.key,
    this.onRecordingComplete,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final GlobalRecorderService _recorderService = GlobalRecorderService();

  bool _isPressed = false;
  bool _isLocked = false;
  bool _isCancelled = false;
  Offset _dragOffset = Offset.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  static const double _lockThreshold = -100; // Glisser 100px vers le haut pour verrouiller
  static const double _cancelThreshold = -100; // Glisser 100px vers la gauche pour annuler

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() async {
    final success = await _recorderService.startRecording();
    if (success) {
      setState(() {
        _isPressed = true;
        _dragOffset = Offset.zero;
        _isCancelled = false;
      });
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopRecording() async {
    if (_isCancelled) {
      await _recorderService.cancelRecording();
    } else {
      final path = await _recorderService.stopRecording();
      if (path != null && widget.onRecordingComplete != null) {
        widget.onRecordingComplete!();
      }
    }

    setState(() {
      _isPressed = false;
      _isLocked = false;
      _isCancelled = false;
      _dragOffset = Offset.zero;
    });
    _pulseController.stop();
  }

  void _handleDragUpdate(LongPressMoveUpdateDetails details) {
    if (!_isLocked) {
      setState(() {
        _dragOffset = details.localOffsetFromOrigin;

        // Vérifier si l'utilisateur glisse vers la gauche pour annuler
        if (_dragOffset.dx < _cancelThreshold) {
          _isCancelled = true;
        } else {
          _isCancelled = false;
        }
      });
    }
  }

  void _handleDragEnd(LongPressEndDetails details) {
    if (!_isLocked) {
      // Vérifier si l'utilisateur a glissé vers le haut pour verrouiller
      if (_dragOffset.dy < _lockThreshold) {
        setState(() {
          _isLocked = true;
          _dragOffset = Offset.zero;
        });
      } else {
        // Sinon, arrêter l'enregistrement
        _stopRecording();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      // Si verrouillé, ne pas afficher le bouton (le widget flottant prend le relais)
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Indicateur de glissement
        if (_isPressed) ...[
          // Flèche vers le haut (verrouiller)
          Positioned(
            bottom: 100 + (_dragOffset.dy.abs() * 0.5).clamp(0, 50),
            child: AnimatedOpacity(
              opacity: _dragOffset.dy < -20 ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 100),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: _dragOffset.dy < _lockThreshold
                        ? Colors.green
                        : Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Glisser pour\nverrouiller',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _dragOffset.dy < _lockThreshold
                          ? Colors.green
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Flèche vers la gauche (annuler)
          Positioned(
            left: 20 + (_dragOffset.dx.abs() * 0.5).clamp(0, 50),
            child: AnimatedOpacity(
              opacity: _dragOffset.dx < -20 ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 100),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: _isCancelled ? Colors.red : Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Glisser pour\nannuler',
                    style: TextStyle(
                      color: _isCancelled ? Colors.red : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Bouton principal
        Transform.translate(
          offset: _isPressed && !_isLocked ? _dragOffset * 0.3 : Offset.zero,
          child: GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressMoveUpdate: _handleDragUpdate,
            onLongPressEnd: _handleDragEnd,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isPressed ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isCancelled
                            ? [Colors.red.shade700, Colors.red.shade900]
                            : _isPressed
                                ? [Colors.red.shade600, Colors.red.shade800]
                                : [Colors.red.shade500, Colors.red.shade700],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isPressed
                              ? Colors.red.withValues(alpha: 0.5)
                              : Colors.red.withValues(alpha: 0.3),
                          blurRadius: _isPressed ? 20 : 10,
                          spreadRadius: _isPressed ? 5 : 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle pulsant en arrière-plan
                        if (_isPressed)
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                        // Icône
                        Icon(
                          _isCancelled
                              ? Icons.close
                              : _isPressed
                                  ? Icons.mic
                                  : Icons.mic_none,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Texte d'instruction
        if (!_isPressed)
          Positioned(
            bottom: -30,
            child: Text(
              'Maintenir pour enregistrer',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
