import 'package:flutter/material.dart';
import 'package:voxbox/services/global_recorder_service.dart';

/// Widget flottant qui s'affiche en haut de l'écran pendant l'enregistrement
class FloatingRecorderWidget extends StatefulWidget {
  final GlobalRecorderService recorderService;

  const FloatingRecorderWidget({
    super.key,
    required this.recorderService,
  });

  @override
  State<FloatingRecorderWidget> createState() => _FloatingRecorderWidgetState();
}

class _FloatingRecorderWidgetState extends State<FloatingRecorderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.recorderService,
      builder: (context, child) {
        if (!widget.recorderService.isRecording) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.recorderService.isPaused
                        ? Colors.orange.shade700
                        : Colors.red.shade700,
                    widget.recorderService.isPaused
                        ? Colors.orange.shade900
                        : Colors.red.shade900,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showRecordingControls(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Indicateur d'enregistrement animé
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            if (widget.recorderService.isPaused) {
                              return const Icon(
                                Icons.pause_circle_filled,
                                color: Colors.white,
                                size: 24,
                              );
                            }
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Texte et durée
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.recorderService.isPaused
                                    ? 'Enregistrement en pause'
                                    : 'Enregistrement en cours...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.recorderService.formatDuration(
                                  widget.recorderService.recordingDuration,
                                ),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Boutons de contrôle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bouton Pause/Reprendre
                            IconButton(
                              icon: Icon(
                                widget.recorderService.isPaused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () async {
                                if (widget.recorderService.isPaused) {
                                  await widget.recorderService.resumeRecording();
                                } else {
                                  await widget.recorderService.pauseRecording();
                                }
                              },
                            ),

                            // Bouton Stop
                            IconButton(
                              icon: const Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () => _stopRecording(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRecordingControls(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Contrôles d\'enregistrement',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.recorderService.formatDuration(
                widget.recorderService.recordingDuration,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Annuler
                _buildDialogButton(
                  icon: Icons.delete_outline,
                  label: 'Annuler',
                  color: Colors.red,
                  onPressed: () async {
                    await widget.recorderService.cancelRecording();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),

                // Pause/Reprendre
                _buildDialogButton(
                  icon: widget.recorderService.isPaused
                      ? Icons.play_arrow
                      : Icons.pause,
                  label: widget.recorderService.isPaused ? 'Reprendre' : 'Pause',
                  color: Colors.orange,
                  onPressed: () async {
                    if (widget.recorderService.isPaused) {
                      await widget.recorderService.resumeRecording();
                    } else {
                      await widget.recorderService.pauseRecording();
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                ),

                // Terminer
                _buildDialogButton(
                  icon: Icons.check_circle,
                  label: 'Terminer',
                  color: Colors.green,
                  onPressed: () {
                    Navigator.pop(context);
                    _stopRecording(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton({
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _stopRecording(BuildContext context) async {
    final path = await widget.recorderService.stopRecording();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enregistrement sauvegardé dans Créations'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Naviguer vers Créations
            },
          ),
        ),
      );
    }
  }
}
