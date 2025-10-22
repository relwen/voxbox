import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentFile;

  /// Lire un fichier audio
  static Future<void> playAudio(String filePath, {VoidCallback? onComplete}) async {
    try {
      // Arrêter la lecture précédente si elle existe
      if (_isPlaying) {
        await stopAudio();
      }

      // Vérifier si c'est un fichier local ou une URL
      if (filePath.startsWith('http')) {
        // C'est une URL, jouer directement
        await _audioPlayer.play(UrlSource(filePath));
      } else {
        // C'est un fichier local
        final file = File(filePath);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(filePath));
        } else {
          throw Exception('Fichier local introuvable: $filePath');
        }
      }

      _isPlaying = true;
      _currentFile = filePath;

      // Écouter la fin de la lecture
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
        _currentFile = null;
        onComplete?.call();
      });

      // Écouter les erreurs
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped) {
          _isPlaying = false;
          _currentFile = null;
        }
      });

    } catch (e) {
      _isPlaying = false;
      _currentFile = null;
      throw Exception('Erreur lors de la lecture audio: $e');
    }
  }

  /// Pause/Reprendre la lecture
  static Future<void> pauseResumeAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _isPlaying = false;
      } else if (_currentFile != null) {
        await _audioPlayer.resume();
        _isPlaying = true;
      }
    } catch (e) {
      throw Exception('Erreur lors de la pause/reprise: $e');
    }
  }

  /// Arrêter la lecture
  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentFile = null;
    } catch (e) {
      throw Exception('Erreur lors de l\'arrêt: $e');
    }
  }

  /// Obtenir l'état de lecture
  static bool get isPlaying => _isPlaying;
  static String? get currentFile => _currentFile;

  /// Obtenir la position actuelle
  static Future<Duration?> getCurrentPosition() async {
    try {
      return await _audioPlayer.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  /// Obtenir la durée totale
  static Future<Duration?> getDuration() async {
    try {
      return await _audioPlayer.getDuration();
    } catch (e) {
      return null;
    }
  }

  /// Télécharger un fichier audio depuis une URL
  static Future<String?> downloadAudioFromUrl(String url, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final file = File('${audioDir.path}/$fileName');
      
      // Si le fichier existe déjà, le retourner
      if (await file.exists()) {
        return file.path;
      }

      // Télécharger le fichier
      final response = await HttpClient().getUrl(Uri.parse(url));
      final request = await response.close();
      final bytes = await request.expand((chunk) => chunk).toList();
      
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      throw Exception('Erreur lors du téléchargement: $e');
    }
  }

  /// Libérer les ressources
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isPlaying = false;
      _currentFile = null;
    } catch (e) {
      // Ignorer les erreurs lors de la libération
    }
  }
}
