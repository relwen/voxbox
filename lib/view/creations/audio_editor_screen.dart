import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/audio_editor_service.dart';
import 'package:voxbox/widgets/widgets.dart';

class AudioEditorScreen extends StatefulWidget {
  final String audioFilePath;
  final String audioFileName;

  const AudioEditorScreen({
    super.key,
    required this.audioFilePath,
    required this.audioFileName,
  });

  @override
  State<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends State<AudioEditorScreen>
    with TickerProviderStateMixin {
  final AudioEditorService _editorService = AudioEditorService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late AnimationController _waveController;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  
  // Paramètres d'édition
  Duration _cutStartTime = Duration.zero;
  Duration _cutEndTime = Duration.zero;
  double _volume = 1.0;
  bool _normalizeAudio = false;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
    _setupAudioPlayer();
  }

  void _initializeEditor() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _loadAudioInfo();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
          _cutEndTime = duration; // Initialiser la fin de coupe à la durée totale
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<void> _loadAudioInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final duration = await _editorService.getAudioDuration(widget.audioFilePath);
      if (duration != null) {
        setState(() {
          _audioDuration = duration;
          _cutEndTime = duration;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement du fichier audio');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.audioFilePath));
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la lecture');
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _currentPosition = Duration.zero;
    });
  }

  Future<void> _cutAudio() async {
    if (_cutStartTime >= _cutEndTime) {
      _showErrorSnackBar('Le temps de début doit être inférieur au temps de fin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final outputPath = await _editorService.cutAudio(
        inputPath: widget.audioFilePath,
        startTime: _cutStartTime,
        endTime: _cutEndTime,
        outputFileName: '${widget.audioFileName}_cut',
      );

      if (outputPath != null) {
        _showSuccessSnackBar('Audio coupé avec succès');
        // TODO: Rafraîchir la liste des fichiers édités
      } else {
        _showErrorSnackBar('Erreur lors de la coupe audio');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _normalizeAudioFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final outputPath = await _editorService.normalizeAudio(
        inputPath: widget.audioFilePath,
        targetVolume: _volume,
        outputFileName: '${widget.audioFileName}_normalized',
      );

      if (outputPath != null) {
        _showSuccessSnackBar('Audio normalisé avec succès');
      } else {
        _showErrorSnackBar('Erreur lors de la normalisation');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSilence() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final outputPath = await _editorService.addSilence(
        inputPath: widget.audioFilePath,
        silenceDuration: const Duration(seconds: 2),
        outputFileName: '${widget.audioFileName}_with_silence',
      );

      if (outputPath != null) {
        _showSuccessSnackBar('Silence ajouté avec succès');
      } else {
        _showErrorSnackBar('Erreur lors de l\'ajout de silence');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: MyText(
          text: "Éditeur Audio",
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations du fichier
                  _buildFileInfo(),
                  
                  const SizedBox(height: 24),
                  
                  // Contrôles de lecture
                  _buildPlaybackControls(),
                  
                  const SizedBox(height: 24),
                  
                  // Visualisation du waveform
                  _buildWaveformVisualizer(),
                  
                  const SizedBox(height: 24),
                  
                  // Outils d'édition
                  _buildEditingTools(),
                  
                  const SizedBox(height: 24),
                  
                  // Paramètres avancés
                  _buildAdvancedSettings(),
                ],
              ),
            ),
    );
  }

  Widget _buildFileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.audiotrack, color: AppConstance.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.audioFileName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Durée: ${_formatDuration(_audioDuration)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barre de progression
            Slider(
              value: _audioDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds / _audioDuration.inMilliseconds
                  : 0.0,
              onChanged: (value) {
                final position = Duration(
                  milliseconds: (value * _audioDuration.inMilliseconds).round(),
                );
                _audioPlayer.seek(position);
              },
              activeColor: AppConstance.primary,
            ),
            
            // Contrôles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(_formatDuration(_currentPosition)),
                IconButton(
                  onPressed: _isPlaying ? _stopPlayback : _playAudio,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  color: AppConstance.primary,
                  iconSize: 32,
                ),
                Text(_formatDuration(_audioDuration)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformVisualizer() {
    return Card(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return CustomPaint(
              painter: WaveformPainter(
                progress: _waveController.value,
                isPlaying: _isPlaying,
                currentPosition: _currentPosition,
                totalDuration: _audioDuration,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditingTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Outils d\'Édition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Coupe audio
            _buildCutTool(),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cutAudio,
                    icon: const Icon(Icons.content_cut),
                    label: const Text('Couper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstance.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addSilence,
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Silence'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCutTool() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coupe Audio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Temps de début
        Row(
          children: [
            const Text('Début: '),
            Expanded(
              child: Slider(
                value: _cutStartTime.inMilliseconds / _audioDuration.inMilliseconds,
                onChanged: (value) {
                  setState(() {
                    _cutStartTime = Duration(
                      milliseconds: (value * _audioDuration.inMilliseconds).round(),
                    );
                  });
                },
                activeColor: Colors.green,
              ),
            ),
            Text(_formatDuration(_cutStartTime)),
          ],
        ),
        
        // Temps de fin
        Row(
          children: [
            const Text('Fin: '),
            Expanded(
              child: Slider(
                value: _cutEndTime.inMilliseconds / _audioDuration.inMilliseconds,
                onChanged: (value) {
                  setState(() {
                    _cutEndTime = Duration(
                      milliseconds: (value * _audioDuration.inMilliseconds).round(),
                    );
                  });
                },
                activeColor: Colors.red,
              ),
            ),
            Text(_formatDuration(_cutEndTime)),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres Avancés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Volume
            Row(
              children: [
                const Text('Volume: '),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                      });
                    },
                    activeColor: AppConstance.primary,
                  ),
                ),
                Text('${(_volume * 100).round()}%'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Normalisation
            CheckboxListTile(
              title: const Text('Normaliser l\'audio'),
              subtitle: const Text('Ajuster automatiquement le volume'),
              value: _normalizeAudio,
              onChanged: (value) {
                setState(() {
                  _normalizeAudio = value ?? false;
                });
              },
              activeColor: AppConstance.primary,
            ),
            
            const SizedBox(height: 16),
            
            // Bouton de normalisation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _normalizeAudio ? _normalizeAudioFile : null,
                icon: const Icon(Icons.equalizer),
                label: const Text('Normaliser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPlaying ? Colors.red : Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final waveCount = 30;
    final waveWidth = size.width / waveCount;
    final progressRatio = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    for (int i = 0; i < waveCount; i++) {
      final x = i * waveWidth + waveWidth / 2;
      final amplitude = (sin((i * 0.3 + progress * 5) * 3.14159) * 20).abs();
      
      // Colorer différemment la partie déjà lue
      if (i / waveCount <= progressRatio) {
        paint.color = Colors.green;
      } else {
        paint.color = isPlaying ? Colors.red : Colors.blue;
      }
      
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
