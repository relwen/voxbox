import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:voxbox/functions/appconstants.dart';

enum FileDownloadStatus {
  notDownloaded,
  downloaded,
  outdated,
}

class LocalFileInfo {
  final String localPath;
  final DateTime downloadDate;
  final String? fileHash;
  final int? fileSize;

  LocalFileInfo({
    required this.localPath,
    required this.downloadDate,
    this.fileHash,
    this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'localPath': localPath,
      'downloadDate': downloadDate.toIso8601String(),
      'fileHash': fileHash,
      'fileSize': fileSize,
    };
  }

  factory LocalFileInfo.fromJson(Map<String, dynamic> json) {
    return LocalFileInfo(
      localPath: json['localPath'],
      downloadDate: DateTime.parse(json['downloadDate']),
      fileHash: json['fileHash'],
      fileSize: json['fileSize'],
    );
  }
}

class LocalFileService {
  static const String _filesInfoKey = 'local_files_info';
  static const String _downloadsDir = 'Downloads';

  /// Obtenir le répertoire de téléchargement
  static Future<Directory> _getDownloadsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/$_downloadsDir');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  /// Obtenir les informations des fichiers locaux
  static Future<Map<String, LocalFileInfo>> _getFilesInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesInfoJson = prefs.getString(_filesInfoKey);
      if (filesInfoJson == null) {
        return {};
      }
      final Map<String, dynamic> filesInfoMap = json.decode(filesInfoJson);
      return filesInfoMap.map((key, value) => MapEntry(key, LocalFileInfo.fromJson(value)));
    } catch (e) {
      print('Erreur lors de la récupération des infos de fichiers: $e');
      return {};
    }
  }

  /// Sauvegarder les informations des fichiers locaux
  static Future<void> _saveFilesInfo(Map<String, LocalFileInfo> filesInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesInfoMap = filesInfo.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_filesInfoKey, json.encode(filesInfoMap));
    } catch (e) {
      print('Erreur lors de la sauvegarde des infos de fichiers: $e');
    }
  }

  /// Générer une clé unique pour un fichier à partir de son URL
  static String _getFileKey(String fileUrl) {
    // Utiliser l'URL comme clé, ou extraire un identifiant unique
    return fileUrl;
  }

  /// Calculer le hash d'un fichier
  static Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('Erreur lors du calcul du hash: $e');
      return '';
    }
  }

  /// Obtenir le hash d'un fichier depuis le serveur (via headers si disponible)
  static Future<String?> _getServerFileHash(String fileUrl) async {
    try {
      final response = await http.head(Uri.parse(fileUrl));
      return response.headers['etag'] ?? response.headers['content-md5'];
    } catch (e) {
      return null;
    }
  }

  /// Vérifier le statut d'un fichier
  static Future<FileDownloadStatus> getFileStatus(String fileUrl) async {
    try {
      // Si c'est un chemin local, vérifier directement s'il existe
      if (fileUrl.startsWith('/')) {
        final localFile = File(fileUrl);
        if (await localFile.exists()) {
          return FileDownloadStatus.downloaded;
        } else {
          return FileDownloadStatus.notDownloaded;
        }
      }

      // Sinon, chercher dans les fichiers téléchargés
      final fileKey = _getFileKey(fileUrl);
      final filesInfo = await _getFilesInfo();
      final fileInfo = filesInfo[fileKey];

      if (fileInfo == null) {
        return FileDownloadStatus.notDownloaded;
      }

      // Vérifier si le fichier existe toujours
      final localFile = File(fileInfo.localPath);
      if (!await localFile.exists()) {
        // Le fichier a été supprimé, retirer de la liste
        filesInfo.remove(fileKey);
        await _saveFilesInfo(filesInfo);
        return FileDownloadStatus.notDownloaded;
      }

      // Vérifier si le fichier a été modifié (comparer la taille ou le hash)
      // Pour l'instant, on considère qu'un fichier est outdated après 7 jours
      final daysSinceDownload = DateTime.now().difference(fileInfo.downloadDate).inDays;
      if (daysSinceDownload > 7) {
        return FileDownloadStatus.outdated;
      }

      return FileDownloadStatus.downloaded;
    } catch (e) {
      print('Erreur lors de la vérification du statut: $e');
      return FileDownloadStatus.notDownloaded;
    }
  }

  /// Obtenir le chemin local d'un fichier s'il existe
  static Future<String?> getLocalFilePath(String fileUrl) async {
    try {
      // Si c'est déjà un chemin local, vérifier directement s'il existe
      if (fileUrl.startsWith('/')) {
        final localFile = File(fileUrl);
        if (await localFile.exists()) {
          print('✅ Fichier local trouvé: $fileUrl');
          return fileUrl;
        } else {
          print('⚠️ Fichier local introuvable: $fileUrl');
          return null;
        }
      }

      // Sinon, chercher dans les fichiers téléchargés
      final fileKey = _getFileKey(fileUrl);
      final filesInfo = await _getFilesInfo();
      final fileInfo = filesInfo[fileKey];

      if (fileInfo == null) {
        return null;
      }

      final localFile = File(fileInfo.localPath);
      if (await localFile.exists()) {
        return fileInfo.localPath;
      } else {
        // Le fichier n'existe plus, retirer de la liste
        filesInfo.remove(fileKey);
        await _saveFilesInfo(filesInfo);
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération du chemin local: $e');
      return null;
    }
  }

  /// Télécharger un fichier
  static Future<String?> downloadFile(String fileUrl, {bool forceRedownload = false}) async {
    try {
      print('🔄 [LocalFileService] Début du téléchargement pour: $fileUrl');

      // Si c'est déjà un chemin local, vérifier s'il existe et le retourner
      if (fileUrl.startsWith('/')) {
        final localFile = File(fileUrl);
        if (await localFile.exists()) {
          print('✅ [LocalFileService] Fichier local existe déjà: $fileUrl');
          return fileUrl;
        } else {
          print('❌ [LocalFileService] Fichier local introuvable: $fileUrl');
          return null;
        }
      }

      final fileKey = _getFileKey(fileUrl);

      // Si le fichier existe déjà et qu'on ne force pas le retéléchargement
      if (!forceRedownload) {
        final localPath = await getLocalFilePath(fileUrl);
        if (localPath != null) {
          print('✅ [LocalFileService] Fichier déjà téléchargé: $localPath');
          return localPath;
        }
      }

      // Construire l'URL complète si nécessaire
      String fullUrl = fileUrl;
      if (!fileUrl.startsWith('http')) {
        if (fileUrl.startsWith('/')) {
          fullUrl = '${AppConstance.baseURL}$fileUrl';
        } else {
          fullUrl = '${AppConstance.baseURL}/storage/$fileUrl';
        }
      }

      print('📥 [LocalFileService] URL complète: $fullUrl');
      print('🌐 [LocalFileService] Base URL: ${AppConstance.baseURL}');

      // Ajouter un timeout pour éviter les blocages infinis
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Accept': '*/*',
          'User-Agent': 'VoxyBox-Flutter-App',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ [LocalFileService] Timeout lors du téléchargement de: $fullUrl');
          throw Exception('Timeout lors du téléchargement');
        },
      );

      print('📊 [LocalFileService] Status HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final downloadsDir = await _getDownloadsDirectory();
        final fileName = fileUrl.split('/').last;
        final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
        final localFile = File('${downloadsDir.path}/$safeFileName');

        print('💾 [LocalFileService] Sauvegarde vers: ${localFile.path}');

        // Écrire le fichier
        await localFile.writeAsBytes(response.bodyBytes);

        // Vérifier que le fichier a bien été écrit
        final fileExists = await localFile.exists();
        final fileSize = fileExists ? await localFile.length() : 0;

        print('📁 [LocalFileService] Fichier créé: $fileExists, Taille: $fileSize bytes');

        if (!fileExists || fileSize == 0) {
          print('❌ [LocalFileService] Échec de l\'écriture du fichier');
          return null;
        }

        // Calculer le hash
        final fileHash = await _calculateFileHash(localFile);

        // Sauvegarder les informations
        final filesInfo = await _getFilesInfo();
        filesInfo[fileKey] = LocalFileInfo(
          localPath: localFile.path,
          downloadDate: DateTime.now(),
          fileHash: fileHash,
          fileSize: fileSize,
        );
        await _saveFilesInfo(filesInfo);

        print('✅ [LocalFileService] Fichier téléchargé avec succès vers: ${localFile.path}');
        return localFile.path;
      } else {
        print('❌ [LocalFileService] Erreur HTTP ${response.statusCode} pour: $fullUrl');
        print('📄 [LocalFileService] Réponse: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ [LocalFileService] Erreur lors du téléchargement de $fileUrl: $e');
      print('🔍 [LocalFileService] StackTrace: $stackTrace');
      return null;
    }
  }

  /// Supprimer un fichier local
  static Future<bool> deleteLocalFile(String fileUrl) async {
    try {
      final fileKey = _getFileKey(fileUrl);
      final filesInfo = await _getFilesInfo();
      final fileInfo = filesInfo[fileKey];

      if (fileInfo != null) {
        final localFile = File(fileInfo.localPath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
        filesInfo.remove(fileKey);
        await _saveFilesInfo(filesInfo);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression du fichier: $e');
      return false;
    }
  }

  /// Obtenir la taille totale des fichiers téléchargés
  static Future<int> getTotalDownloadedSize() async {
    try {
      final filesInfo = await _getFilesInfo();
      int totalSize = 0;
      for (final fileInfo in filesInfo.values) {
        if (fileInfo.fileSize != null) {
          totalSize += fileInfo.fileSize!;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Nettoyer les fichiers obsolètes (plus de 30 jours)
  static Future<void> cleanOldFiles() async {
    try {
      final filesInfo = await _getFilesInfo();
      final now = DateTime.now();
      final filesToRemove = <String>[];

      for (final entry in filesInfo.entries) {
        final daysSinceDownload = now.difference(entry.value.downloadDate).inDays;
        if (daysSinceDownload > 30) {
          final localFile = File(entry.value.localPath);
          if (await localFile.exists()) {
            await localFile.delete();
          }
          filesToRemove.add(entry.key);
        }
      }

      for (final key in filesToRemove) {
        filesInfo.remove(key);
      }

      await _saveFilesInfo(filesInfo);
      print('🧹 ${filesToRemove.length} fichier(s) obsolète(s) supprimé(s)');
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
    }
  }
}

