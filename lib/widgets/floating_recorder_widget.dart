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
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.recorderService.isPaused
                        ? Colors.orange.shade600
                        : Colors.red.shade600,
                    widget.recorderService.isPaused
                        ? Colors.orange.shade800
                        : Colors.red.shade800,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
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
                              size: 28,
                            );
                          }
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 16),

                      // Durée
                      Text(
                        widget.recorderService.formatDuration(
                          widget.recorderService.recordingDuration,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),

                      const Spacer(),

                      // Bouton Annuler
                      _buildCompactButton(
                        icon: Icons.delete_outline,
                        onPressed: () => _cancelRecording(context),
                      ),

                      const SizedBox(width: 8),

                      // Bouton Pause/Reprendre
                      _buildCompactButton(
                        icon: widget.recorderService.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        onPressed: () async {
                          if (widget.recorderService.isPaused) {
                            await widget.recorderService.resumeRecording();
                          } else {
                            await widget.recorderService.pauseRecording();
                          }
                        },
                      ),

                      const SizedBox(width: 8),

                      // Bouton Terminer
                      _buildCompactButton(
                        icon: Icons.check_circle,
                        onPressed: () => _stopRecording(context),
                        color: Colors.white,
                        backgroundColor: Colors.green.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    Color? backgroundColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color ?? Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _cancelRecording(BuildContext context) async {
    final success = await widget.recorderService.cancelRecording();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enregistrement annulé'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
