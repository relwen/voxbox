import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voxbox/services/global_audio_player_service.dart';
import 'package:voxbox/functions/appconstants.dart';

/// Widget mini-player flottant qui reste visible partout dans l'application
class FloatingAudioPlayerWidget extends StatefulWidget {
  final GlobalAudioPlayerService playerService;

  const FloatingAudioPlayerWidget({
    super.key,
    required this.playerService,
  });

  @override
  State<FloatingAudioPlayerWidget> createState() =>
      _FloatingAudioPlayerWidgetState();
}

class _FloatingAudioPlayerWidgetState extends State<FloatingAudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<AudioInfo?> _audioInfoSubscription;

  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _setupListeners();
  }

  double _getMiniPlayerHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Hauteur basée sur la largeur de l'écran (ratio de ~18%)
    return (screenWidth * 0.18).clamp(55.0, 75.0);
  }

  double _getExpandedPlayerHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Hauteur basée sur la largeur de l'écran avec un minimum et maximum
    // Utiliser 50% de la largeur comme base, mais limiter par la hauteur d'écran
    final baseHeight = (screenWidth * 0.5).clamp(150.0, 250.0);
    final maxHeight = (screenHeight * 0.35);
    return baseHeight.clamp(150.0, maxHeight);
  }

  void _setupListeners() {
    _isPlayingSubscription = widget.playerService.isPlayingStream.listen((_) {
      if (mounted) setState(() {});
    });

    _positionSubscription = widget.playerService.positionStream.listen((_) {
      if (mounted) setState(() {});
    });

    _durationSubscription = widget.playerService.durationStream.listen((_) {
      if (mounted) setState(() {});
    });

    _audioInfoSubscription = widget.playerService.audioInfoStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _isPlayingSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _audioInfoSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // N'afficher le widget que si un audio est chargé
    if (!widget.playerService.hasAudio) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;
    final miniHeight = _getMiniPlayerHeight(context) + safeAreaBottom;
    final expandedHeight = _getExpandedPlayerHeight(context) + safeAreaBottom;

    // Créer l'animation avec les valeurs adaptatives
    final heightAnimation =
        Tween<double>(begin: miniHeight, end: expandedHeight).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: heightAnimation,
        builder: (context, child) {
          return Container(
            constraints: BoxConstraints(
              maxHeight:
                  mediaQuery.size.height * 0.5, // Max 50% de la hauteur d'écran
            ),
            height: heightAnimation.value,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstance.primary,
                  AppConstance.priGradient,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: true, // Respecter la zone sécurisée en bas
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête du mini-player (toujours visible)
                    _buildMiniPlayerHeader(context),

                    // Contrôles étendus (visible quand expanded)
                    if (_isExpanded) _buildExpandedControls(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayerHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        // Toutes les tailles basées sur la largeur de l'écran avec des ratios
        final iconSize = (screenWidth * 0.12).clamp(35.0, 55.0);
        final iconInnerSize = (screenWidth * 0.065).clamp(18.0, 30.0);
        final buttonSize = (screenWidth * 0.036).clamp(16.0, 26.0);
        final primaryButtonSize = (screenWidth * 0.048).clamp(20.0, 30.0);
        final horizontalPadding = (screenWidth * 0.032).clamp(6.0, 18.0);
        final spacing = (screenWidth * 0.033).clamp(4.0, 14.0);
        final buttonSpacing = (screenWidth * 0.0125).clamp(1.0, 8.0);
        final verticalPadding = (screenWidth * 0.015).clamp(4.0, 8.0);
        final fontSize = (screenWidth * 0.030);

        return GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                // Icône audio
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                          (screenWidth * 0.021).clamp(6.0, 10.0)),
                    ),
                    child: Icon(
                      Icons.audiotrack,
                      color: Colors.white,
                      size: iconInnerSize,
                    ),
                  ),
                ),

                SizedBox(width: spacing),

                // Titre et progression
                Expanded(
                  child: Text(
                    '${widget.playerService.formatDuration(widget.playerService.currentPosition)}/${widget.playerService.formatDuration(widget.playerService.totalDuration)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: fontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlButton(
                      context: context,
                      icon: Icons.replay_10,
                      onPressed: () => widget.playerService.seekBackward(),
                      size: buttonSize,
                    ),
                    SizedBox(width: buttonSpacing),
                    _buildControlButton(
                      context: context,
                      icon: widget.playerService.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      onPressed: () {
                        if (widget.playerService.isPlaying) {
                          widget.playerService.pause();
                        } else {
                          widget.playerService.play();
                        }
                      },
                      size: primaryButtonSize,
                      isPrimary: true,
                    ),
                    SizedBox(width: buttonSpacing),
                    _buildControlButton(
                      context: context,
                      icon: Icons.forward_10,
                      onPressed: () => widget.playerService.seekForward(),
                      size: buttonSize,
                    ),
                    SizedBox(width: buttonSpacing),
                    _buildControlButton(
                      context: context,
                      icon: Icons.close,
                      onPressed: () => widget.playerService.stop(),
                      size: buttonSize,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedControls(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Toutes les tailles basées sur la largeur de l'écran
        final padding = (screenWidth * 0.037).clamp(10.0, 18.0);
        final horizontalPadding = (screenWidth * 0.037).clamp(10.0, 18.0);
        final fontSize = (screenWidth * 0.037).clamp(11.0, 16.0);
        final spacing = (screenWidth * 0.015).clamp(4.0, 8.0);
        final bottomSpacing = (screenWidth * 0.02).clamp(4.0, 12.0);
        final thumbRadius = (screenWidth * 0.013).clamp(4.0, 7.0);
        final trackHeight = (screenWidth * 0.008).clamp(2.5, 4.0);
        final iconSize = (screenWidth * 0.075).clamp(24.0, 32.0);

        return Expanded(
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barre de progression interactive
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: (screenWidth * 0.01).clamp(2.0, 6.0)),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: thumbRadius),
                      trackHeight: trackHeight,
                    ),
                    child: Slider(
                      value: widget.playerService.progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final position = Duration(
                          milliseconds: (value *
                                  widget.playerService.totalDuration
                                      .inMilliseconds)
                              .round(),
                        );
                        widget.playerService.seek(position);
                      },
                    ),
                  ),
                ),

                // Bouton pour réduire
                IconButton(
                  onPressed: _toggleExpanded,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white),
                  iconSize: iconSize,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    double size = 24,
    bool isPrimary = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Tailles basées sur la largeur de l'écran
    final buttonSize = isPrimary
        ? (screenWidth * 0.106).clamp(36.0, 45.0)
        : (screenWidth * 0.083).clamp(28.0, 38.0);
    final padding = isPrimary
        ? (screenWidth * 0.015).clamp(5.0, 7.0)
        : (screenWidth * 0.008).clamp(2.0, 4.0);

    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: isPrimary ? AppConstance.primary : Colors.white,
        iconSize: size,
        padding: EdgeInsets.all(padding),
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
          maxWidth: buttonSize,
          maxHeight: buttonSize,
        ),
      ),
    );
  }
}
