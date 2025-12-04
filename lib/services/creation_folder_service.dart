import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:voxbox/models/creation_folder.dart';
import 'package:voxbox/models/creation_item.dart';

class CreationFolderService {
  static const String _foldersKey = 'creation_folders';
  static const String _baseFolderName = 'creations';
  
  static final CreationFolderService _instance = CreationFolderService._internal();
  factory CreationFolderService() => _instance;
  CreationFolderService._internal();

  final Uuid _uuid = const Uuid();

  /// Récupérer tous les dossiers
  Future<List<CreationFolder>> getFolders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? foldersJson = prefs.getString(_foldersKey);
      
      if (foldersJson != null) {
        List<dynamic> foldersList = jsonDecode(foldersJson);
        return foldersList.map((json) => CreationFolder.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des dossiers: $e');
      return [];
    }
  }

  /// Sauvegarder tous les dossiers
  Future<void> saveFolders(List<CreationFolder> folders) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String foldersJson = jsonEncode(folders.map((folder) => folder.toJson()).toList());
      await prefs.setString(_foldersKey, foldersJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde des dossiers: $e');
    }
  }

  /// Créer un nouveau dossier
  Future<CreationFolder> createFolder({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final folder = CreationFolder(
        id: _uuid.v4(),
        name: name,
        description: description,
        color: color ?? '#2196F3',
        icon: icon ?? 'folder',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final folders = await getFolders();
      folders.add(folder);
      await saveFolders(folders);

      // Créer le dossier physique
      await _createPhysicalFolder(folder.id);

      return folder;
    } catch (e) {
      print('Erreur lors de la création du dossier: $e');
      rethrow;
    }
  }

  /// Supprimer un dossier
  Future<bool> deleteFolder(String folderId) async {
    try {
      final folders = await getFolders();
      folders.removeWhere((folder) => folder.id == folderId);
      await saveFolders(folders);

      // Supprimer le dossier physique
      await _deletePhysicalFolder(folderId);

      return true;
    } catch (e) {
      print('Erreur lors de la suppression du dossier: $e');
      return false;
    }
  }

  /// Renommer un dossier
  Future<bool> renameFolder(String folderId, String newName) async {
    try {
      final folders = await getFolders();
      final folderIndex = folders.indexWhere((folder) => folder.id == folderId);
      
      if (folderIndex != -1) {
        folders[folderIndex] = folders[folderIndex].copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
        await saveFolders(folders);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors du renommage du dossier: $e');
      return false;
    }
  }

  /// Ajouter un élément à un dossier
  Future<bool> addItemToFolder(String folderId, CreationItem item) async {
    try {
      final folders = await getFolders();
      final folderIndex = folders.indexWhere((folder) => folder.id == folderId);
      
      if (folderIndex != -1) {
        final updatedItems = List<CreationItem>.from(folders[folderIndex].items);
        updatedItems.add(item);
        
        folders[folderIndex] = folders[folderIndex].copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await saveFolders(folders);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de l\'ajout d\'un élément: $e');
      return false;
    }
  }

  /// Supprimer un élément d'un dossier
  Future<bool> removeItemFromFolder(String folderId, String itemId) async {
    try {
      final folders = await getFolders();
      final folderIndex = folders.indexWhere((folder) => folder.id == folderId);
      
      if (folderIndex != -1) {
        final updatedItems = folders[folderIndex].items
            .where((item) => item.id != itemId)
            .toList();
        
        folders[folderIndex] = folders[folderIndex].copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await saveFolders(folders);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression d\'un élément: $e');
      return false;
    }
  }

  /// Créer un élément audio
  Future<CreationItem> createAudioItem({
    required String name,
    required String filePath,
    String? description,
    int? duration,
    int? fileSize,
  }) async {
    return CreationItem(
      id: _uuid.v4(),
      name: name,
      description: description,
      type: CreationType.audio,
      filePath: filePath,
      duration: duration,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Créer un élément image
  Future<CreationItem> createImageItem({
    required String name,
    required String filePath,
    String? description,
    String? thumbnailPath,
    int? fileSize,
  }) async {
    return CreationItem(
      id: _uuid.v4(),
      name: name,
      description: description,
      type: CreationType.image,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Créer un élément texte
  Future<CreationItem> createTextItem({
    required String name,
    required String content,
    String? description,
  }) async {
    return CreationItem(
      id: _uuid.v4(),
      name: name,
      description: description,
      type: CreationType.text,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Obtenir le chemin du dossier physique
  Future<String> getFolderPath(String folderId) async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, _baseFolderName, folderId);
  }

  /// Créer le dossier physique
  Future<void> _createPhysicalFolder(String folderId) async {
    try {
      final folderPath = await getFolderPath(folderId);
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
    } catch (e) {
      print('Erreur lors de la création du dossier physique: $e');
    }
  }

  /// Supprimer le dossier physique
  Future<void> _deletePhysicalFolder(String folderId) async {
    try {
      final folderPath = await getFolderPath(folderId);
      final folder = Directory(folderPath);
      if (await folder.exists()) {
        await folder.delete(recursive: true);
      }
    } catch (e) {
      print('Erreur lors de la suppression du dossier physique: $e');
    }
  }

  /// Obtenir les statistiques globales
  Future<Map<String, int>> getGlobalStats() async {
    try {
      final folders = await getFolders();
      int totalFolders = folders.length;
      int totalItems = 0;
      int totalAudio = 0;
      int totalImages = 0;
      int totalTexts = 0;

      for (final folder in folders) {
        totalItems += folder.totalItems;
        totalAudio += folder.audioCount;
        totalImages += folder.imageCount;
        totalTexts += folder.textCount;
      }

      return {
        'folders': totalFolders,
        'items': totalItems,
        'audio': totalAudio,
        'images': totalImages,
        'texts': totalTexts,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {
        'folders': 0,
        'items': 0,
        'audio': 0,
        'images': 0,
        'texts': 0,
      };
    }
  }
}
