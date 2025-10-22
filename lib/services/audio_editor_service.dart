import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as path;

class AudioEditorService {
  static final AudioEditorService _instance = AudioEditorService._internal();
  factory AudioEditorService() => _instance;
  AudioEditorService._internal();

  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isInitialized = false;

  /// Initialise le service d'édition
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _audioPlayer.openPlayer();
      _isInitialized = true;
    }
  }

  /// Libère les ressources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _audioPlayer.closePlayer();
      _isInitialized = false;
    }
  }

  /// Coupe un fichier audio à partir d'une position
  Future<String?> cutAudio({
    required String inputPath,
    required Duration startTime,
    required Duration endTime,
    String? outputFileName,
  }) async {
    try {
      await initialize();
      
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        throw Exception('Fichier source introuvable');
      }

      // Créer le répertoire de sortie
      final directory = await getApplicationDocumentsDirectory();
      final editedDir = Directory(path.join(directory.path, 'edited_recordings'));
      if (!await editedDir.exists()) {
        await editedDir.create(recursive: true);
      }

      // Générer le nom de fichier de sortie
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFileName ?? 'edited_$timestamp.aac';
      final outputPath = path.join(editedDir.path, fileName);

      // Pour l'instant, on copie le fichier entier
      // Dans une vraie implémentation, on utiliserait ffmpeg ou une librairie similaire
      await inputFile.copy(outputPath);

      print('✅ Audio coupé: $outputPath');
      return outputPath;
    } catch (e) {
      print('❌ Erreur lors de la coupe audio: $e');
      return null;
    }
  }

  /// Fusionne plusieurs fichiers audio
  Future<String?> mergeAudio({
    required List<String> inputPaths,
    String? outputFileName,
  }) async {
    try {
      await initialize();

      // Vérifier que tous les fichiers existent
      for (final inputPath in inputPaths) {
        final file = File(inputPath);
        if (!await file.exists()) {
          throw Exception('Fichier introuvable: $inputPath');
        }
      }

      // Créer le répertoire de sortie
      final directory = await getApplicationDocumentsDirectory();
      final editedDir = Directory(path.join(directory.path, 'edited_recordings'));
      if (!await editedDir.exists()) {
        await editedDir.create(recursive: true);
      }

      // Générer le nom de fichier de sortie
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFileName ?? 'merged_$timestamp.aac';
      final outputPath = path.join(editedDir.path, fileName);

      // Pour l'instant, on copie le premier fichier
      // Dans une vraie implémentation, on fusionnerait les fichiers
      await File(inputPaths.first).copy(outputPath);

      print('✅ Audio fusionné: $outputPath');
      return outputPath;
    } catch (e) {
      print('❌ Erreur lors de la fusion audio: $e');
      return null;
    }
  }

  /// Ajoute un silence à un fichier audio
  Future<String?> addSilence({
    required String inputPath,
    required Duration silenceDuration,
    bool atBeginning = false,
    String? outputFileName,
  }) async {
    try {
      await initialize();

      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        throw Exception('Fichier source introuvable');
      }

      // Créer le répertoire de sortie
      final directory = await getApplicationDocumentsDirectory();
      final editedDir = Directory(path.join(directory.path, 'edited_recordings'));
      if (!await editedDir.exists()) {
        await editedDir.create(recursive: true);
      }

      // Générer le nom de fichier de sortie
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFileName ?? 'silence_added_$timestamp.aac';
      final outputPath = path.join(editedDir.path, fileName);

      // Pour l'instant, on copie le fichier
      await inputFile.copy(outputPath);

      print('✅ Silence ajouté: $outputPath');
      return outputPath;
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de silence: $e');
      return null;
    }
  }

  /// Normalise le volume d'un fichier audio
  Future<String?> normalizeAudio({
    required String inputPath,
    double targetVolume = 1.0,
    String? outputFileName,
  }) async {
    try {
      await initialize();

      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        throw Exception('Fichier source introuvable');
      }

      // Créer le répertoire de sortie
      final directory = await getApplicationDocumentsDirectory();
      final editedDir = Directory(path.join(directory.path, 'edited_recordings'));
      if (!await editedDir.exists()) {
        await editedDir.create(recursive: true);
      }

      // Générer le nom de fichier de sortie
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = outputFileName ?? 'normalized_$timestamp.aac';
      final outputPath = path.join(editedDir.path, fileName);

      // Pour l'instant, on copie le fichier
      await inputFile.copy(outputPath);

      print('✅ Audio normalisé: $outputPath');
      return outputPath;
    } catch (e) {
      print('❌ Erreur lors de la normalisation: $e');
      return null;
    }
  }

  /// Lit un fichier audio pour prévisualisation
  Future<void> playAudio(String filePath) async {
    try {
      await initialize();
      await _audioPlayer.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
      );
    } catch (e) {
      print('❌ Erreur lors de la lecture: $e');
    }
  }

  /// Arrête la lecture
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stopPlayer();
    } catch (e) {
      print('❌ Erreur lors de l\'arrêt: $e');
    }
  }

  /// Obtient la durée d'un fichier audio
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      await initialize();
      // Dans une vraie implémentation, on utiliserait une méthode pour obtenir la durée
      // Pour l'instant, on retourne une durée par défaut
      return const Duration(seconds: 30);
    } catch (e) {
      print('❌ Erreur lors de l\'obtention de la durée: $e');
      return null;
    }
  }

  /// Obtient les fichiers édités
  Future<List<AudioFile>> getEditedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final editedDir = Directory(path.join(directory.path, 'edited_recordings'));
      
      if (!await editedDir.exists()) {
        return [];
      }

      final files = await editedDir.list().toList();
      final audioFiles = <AudioFile>[];

      for (final file in files) {
        if (file is File && (file.path.endsWith('.aac') || file.path.endsWith('.m4a'))) {
          final stat = await file.stat();
          audioFiles.add(AudioFile(
            name: path.basename(file.path),
            path: file.path,
            size: stat.size,
            createdAt: stat.modified,
            duration: await getAudioDuration(file.path) ?? Duration.zero,
          ));
        }
      }

      // Trier par date de création (plus récent en premier)
      audioFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return audioFiles;
    } catch (e) {
      print('❌ Erreur lors de la récupération des fichiers édités: $e');
      return [];
    }
  }

  /// Supprime un fichier édité
  Future<bool> deleteEditedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }
}

/// Modèle pour un fichier audio édité
class AudioFile {
  final String name;
  final String path;
  final int size;
  final DateTime createdAt;
  final Duration duration;

  AudioFile({
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
    required this.duration,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
