import 'dart:async';
import 'dart:math';

class AudioVisualizerService {
  static final AudioVisualizerService _instance = AudioVisualizerService._internal();
  factory AudioVisualizerService() => _instance;
  AudioVisualizerService._internal();

  final StreamController<List<double>> _waveformController = StreamController<List<double>>.broadcast();
  Timer? _visualizationTimer;
  bool _isVisualizing = false;

  Stream<List<double>> get waveformStream => _waveformController.stream;

  /// Démarre la visualisation audio
  void startVisualization() {
    if (_isVisualizing) return;
    
    _isVisualizing = true;
    _visualizationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _generateWaveformData();
    });
  }

  /// Arrête la visualisation audio
  void stopVisualization() {
    _isVisualizing = false;
    _visualizationTimer?.cancel();
    _visualizationTimer = null;
  }

  /// Génère des données de waveform simulées
  void _generateWaveformData() {
    if (!_isVisualizing) return;

    final random = Random();
    final waveformData = <double>[];
    
    // Générer 20 points de données pour le waveform
    for (int i = 0; i < 20; i++) {
      // Simuler des variations d'amplitude plus réalistes
      final baseAmplitude = 0.3 + (random.nextDouble() * 0.7);
      final variation = sin(i * 0.5 + DateTime.now().millisecondsSinceEpoch * 0.01) * 0.3;
      final amplitude = (baseAmplitude + variation).clamp(0.0, 1.0);
      
      waveformData.add(amplitude);
    }
    
    _waveformController.add(waveformData);
  }

  /// Génère des données de waveform basées sur l'intensité audio
  void updateWithAudioLevel(double audioLevel) {
    if (!_isVisualizing) return;

    final waveformData = <double>[];
    final random = Random();
    
    // Utiliser le niveau audio réel pour influencer le waveform
    final baseLevel = audioLevel.clamp(0.0, 1.0);
    
    for (int i = 0; i < 20; i++) {
      // Créer une variation autour du niveau audio réel
      final variation = sin(i * 0.3 + DateTime.now().millisecondsSinceEpoch * 0.02) * 0.2;
      final amplitude = (baseLevel + variation + random.nextDouble() * 0.1).clamp(0.0, 1.0);
      
      waveformData.add(amplitude);
    }
    
    _waveformController.add(waveformData);
  }

  /// Libère les ressources
  void dispose() {
    stopVisualization();
    _waveformController.close();
  }
}
