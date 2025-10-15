import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voxbox/services/audio_player_service.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/functions/appconstants.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Vocalise? vocalise;
  final List<Vocalise>? playlist;
  final bool showPlaylistControls;

  const AudioPlayerWidget({
    Key? key,
    this.vocalise,
    this.playlist,
    this.showPlaylistControls = false,
  }) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayerService _audioService = AudioPlayerService();
  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<Vocalise?> _currentVocaliseSubscription;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _setupListeners();
  }

  void _setupListeners() {
    _isPlayingSubscription = _audioService.isPlayingStream.listen((isPlaying) {
      if (mounted) setState(() {});
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      if (mounted) setState(() {});
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (mounted) setState(() {});
    });

    _currentVocaliseSubscription = _audioService.currentVocaliseStream.listen((vocalise) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _isPlayingSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _currentVocaliseSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Informations de la vocalise
          if (_audioService.currentVocalise != null) ...[
            _buildVocaliseInfo(),
            SizedBox(height: 16),
          ],

          // Barre de progression
          _buildProgressBar(),

          SizedBox(height: 16),

          // Contrôles de lecture
          _buildPlaybackControls(),

          // Contrôles de playlist (si activés)
          if (widget.showPlaylistControls && _audioService.playlist.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildPlaylistControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildVocaliseInfo() {
    final vocalise = _audioService.currentVocalise!;
    return Column(
      children: [
        Text(
          vocalise.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstance.primary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstance.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                vocalise.voicePart,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstance.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (vocalise.choraleName != null) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstance.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vocalise.choraleName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstance.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // Barre de progression
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppConstance.primary,
            inactiveTrackColor: AppConstance.primary.withOpacity(0.3),
            thumbColor: AppConstance.primary,
            overlayColor: AppConstance.primary.withOpacity(0.2),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: _audioService.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * _audioService.totalDuration.inMilliseconds).round(),
              );
              _audioService.seek(position);
            },
          ),
        ),
        
        // Temps
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _audioService.formatDuration(_audioService.currentPosition),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _audioService.formatDuration(_audioService.totalDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton précédent (si playlist)
        if (widget.showPlaylistControls && _audioService.playlist.isNotEmpty)
          IconButton(
            onPressed: _audioService.currentIndex > 0 ? _audioService.previousTrack : null,
            icon: Icon(Icons.skip_previous, size: 32),
            color: AppConstance.primary,
          ),

        SizedBox(width: 16),

        // Bouton play/pause
        Container(
          decoration: BoxDecoration(
            color: AppConstance.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _handlePlayPause,
            icon: Icon(
              _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            iconSize: 32,
          ),
        ),

        SizedBox(width: 16),

        // Bouton stop
        IconButton(
          onPressed: _audioService.stop,
          icon: Icon(Icons.stop, size: 28),
          color: AppConstance.primary,
        ),

        SizedBox(width: 16),

        // Bouton suivant (si playlist)
        if (widget.showPlaylistControls && _audioService.playlist.isNotEmpty)
          IconButton(
            onPressed: _audioService.currentIndex < _audioService.playlist.length - 1 
                ? _audioService.nextTrack 
                : null,
            icon: Icon(Icons.skip_next, size: 32),
            color: AppConstance.primary,
          ),
      ],
    );
  }

  Widget _buildPlaylistControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_audioService.currentIndex + 1} / ${_audioService.playlist.length}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstance.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Mode Playlist',
            style: TextStyle(
              fontSize: 12,
              color: AppConstance.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _handlePlayPause() async {
    try {
      if (_audioService.isPlaying) {
        await _audioService.pause();
      } else {
        if (widget.vocalise != null) {
          // Vérifier que la vocalise a un fichier audio
          if (!_hasAudioFile(widget.vocalise!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Aucun fichier audio disponible pour cette vocalise'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          await _audioService.playVocalise(widget.vocalise!);
        } else if (widget.playlist != null && widget.playlist!.isNotEmpty) {
          // Filtrer les vocalises qui ont des fichiers audio
          final vocalisesWithAudio = widget.playlist!.where((v) => _hasAudioFile(v)).toList();
          if (vocalisesWithAudio.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Aucune vocalise avec fichier audio dans cette playlist'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          await _audioService.playPlaylist(vocalisesWithAudio);
        } else {
          await _audioService.play();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de lecture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Vérifier si une vocalise a un fichier audio
  bool _hasAudioFile(Vocalise vocalise) {
    return (vocalise.audioPath != null && vocalise.audioUrl != null) ||
           (vocalise.isDownloaded && vocalise.localAudioPath != null);
  }
}
