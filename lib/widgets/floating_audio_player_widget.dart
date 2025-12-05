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
    if (screenWidth < 360) return 60.0;
    return 65.0;
  }

  double _getExpandedPlayerHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Limiter à 35% de la hauteur d'écran maximum
    final maxHeight = (screenHeight * 0.35).clamp(150.0, 250.0);
    
    if (screenWidth < 360) return maxHeight.clamp(150.0, 170.0);
    if (screenWidth < 400) return maxHeight.clamp(160.0, 180.0);
    return maxHeight.clamp(170.0, 200.0);
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
    final heightAnimation = Tween<double>(begin: miniHeight, end: expandedHeight).animate(
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
              maxHeight: mediaQuery.size.height * 0.5, // Max 50% de la hauteur d'écran
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
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayerHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth < 400;

        // Tailles adaptatives avec contraintes min/max
        final iconSize = (screenWidth / 10).clamp(35.0, 50.0);
        final iconInnerSize = (screenWidth / 15).clamp(18.0, 28.0);
        final buttonSize = (screenWidth / 28).clamp(16.0, 24.0);
        final primaryButtonSize = (screenWidth / 21).clamp(20.0, 28.0);
        final horizontalPadding = (screenWidth / 31).clamp(6.0, 16.0);
        final spacing = (screenWidth / 30).clamp(4.0, 12.0);
        final buttonSpacing = (screenWidth / 80).clamp(1.0, 6.0);
        final headerHeight = isSmallScreen ? 60.0 : 65.0;
        final fontSize = (screenWidth / 21).clamp(10.0, 14.0);

        return GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isSmallScreen ? 4 : 6,
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.audiotrack,
                      color: Colors.white,
                      size: iconInnerSize,
                    ),
                  ),
                ),

                SizedBox(width: spacing.clamp(4.0, 10.0)),

                // Titre et progression
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
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
                    ],
                  ),
                ),



                // Boutons de contrôle avec contraintes
                Flexible(
                  child: Row(
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
                      if (screenWidth >= 380) ...[
                        SizedBox(width: buttonSpacing),
                        _buildControlButton(
                          context: context,
                          icon: Icons.close,
                          onPressed: () => widget.playerService.stop(),
                          size: buttonSize,
                        ),
                      ],
                    ],
                  ),
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
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth < 400;

        final padding = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);
        final horizontalPadding = isSmallScreen ? 10.0 : 14.0;
        final fontSize = isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 13.0);
        final spacing = isSmallScreen ? 4.0 : (isMediumScreen ? 5.0 : 6.0);
        final bottomSpacing = isSmallScreen ? 4.0 : (isMediumScreen ? 6.0 : 8.0);
        final thumbRadius = isSmallScreen ? 4.0 : 5.0;
        final trackHeight = isSmallScreen ? 2.5 : 3.0;
        final iconSize = isSmallScreen ? 24.0 : (isMediumScreen ? 26.0 : 28.0);

        // Calculer la hauteur maximale disponible
        final availableHeight = constraints.maxHeight;
        final maxContentHeight = (screenHeight * 0.3).clamp(100.0, 200.0);

        return Flexible(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: maxContentHeight,
                minHeight: 60.0,
              ),
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barre de progression interactive
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
                        trackHeight: trackHeight,
                      ),
                      child: Slider(
                        value: widget.playerService.progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final position = Duration(
                            milliseconds: (value *
                                    widget.playerService.totalDuration.inMilliseconds)
                                .round(),
                          );
                          widget.playerService.seek(position);
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // Temps détaillé
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Text(
                            widget.playerService
                                .formatDuration(widget.playerService.currentPosition),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: spacing),
                        Flexible(
                          flex: 1,
                          child: Text(
                            widget.playerService
                                .formatDuration(widget.playerService.totalDuration),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: bottomSpacing),

                  // Bouton pour réduire
                  IconButton(
                    onPressed: _toggleExpanded,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    iconSize: iconSize,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: iconSize,
                      minHeight: iconSize,
                      maxWidth: iconSize + 10,
                      maxHeight: iconSize + 10,
                    ),
                  ),
                ],
              ),
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
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;

    final buttonSize = isPrimary
        ? (isSmallScreen ? 36.0 : (isMediumScreen ? 38.0 : 40.0))
        : (isSmallScreen ? 28.0 : (isMediumScreen ? 30.0 : 32.0));
    final padding = isPrimary
        ? (isSmallScreen ? 5.0 : (isMediumScreen ? 5.5 : 6.0))
        : (isSmallScreen ? 2.0 : (isMediumScreen ? 2.5 : 3.0));

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
