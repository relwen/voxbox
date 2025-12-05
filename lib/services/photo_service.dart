import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class PhotoItem {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final int? fileSize;

  PhotoItem({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.fileSize,
  });

  String get formattedFileSize {
    if (fileSize == null) {
      final file = File(path);
      if (file.existsSync()) {
        final size = file.lengthSync();
        if (size < 1024) {
          return '${size} B';
        } else if (size < 1024 * 1024) {
          return '${(size / 1024).toStringAsFixed(1)} KB';
        } else {
          return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
      return '';
    }
    if (fileSize! < 1024) {
      return '${fileSize} B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class PhotoService {
  static const String _photosKey = 'creation_photos';
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Prendre une photo avec la caméra
  Future<PhotoItem?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        // Copier la photo vers le dossier de l'application
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory(path.join(appDir.path, 'creations', 'photos'));
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }

        final fileName = 'photo_${_uuid.v4()}${path.extension(photo.path)}';
        final savedPath = path.join(photosDir.path, fileName);
        final savedFile = File(savedPath);
        await File(photo.path).copy(savedPath);

        final photoItem = PhotoItem(
          id: _uuid.v4(),
          name: 'Photo ${DateTime.now().toString().substring(0, 10)}',
          path: savedPath,
          createdAt: DateTime.now(),
          fileSize: savedFile.lengthSync(),
        );

        await _savePhoto(photoItem);
        return photoItem;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  /// Sélectionner une photo depuis la galerie
  Future<PhotoItem?> pickPhotoFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Copier l'image vers le dossier de l'application
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory(path.join(appDir.path, 'creations', 'photos'));
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }

        final fileName = 'photo_${_uuid.v4()}${path.extension(image.path)}';
        final savedPath = path.join(photosDir.path, fileName);
        final savedFile = File(savedPath);
        await File(image.path).copy(savedPath);

        final photoItem = PhotoItem(
          id: _uuid.v4(),
          name: path.basenameWithoutExtension(image.name),
          path: savedPath,
          createdAt: DateTime.now(),
          fileSize: savedFile.lengthSync(),
        );

        await _savePhoto(photoItem);
        return photoItem;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la sélection de photo: $e');
      return null;
    }
  }

  /// Récupérer toutes les photos
  Future<List<PhotoItem>> getPhotos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path.join(appDir.path, 'creations', 'photos'));
      
      if (!await photosDir.exists()) {
        return [];
      }

      final files = photosDir.listSync()
          .whereType<File>()
          .where((file) {
            final ext = path.extension(file.path).toLowerCase();
            return ext == '.jpg' || ext == '.jpeg' || ext == '.png';
          })
          .toList();

      // Trier par date de modification (plus récent en premier)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files.map((file) {
        return PhotoItem(
          id: path.basenameWithoutExtension(file.path),
          name: path.basenameWithoutExtension(file.path).replaceAll('photo_', 'Photo '),
          path: file.path,
          createdAt: file.lastModifiedSync(),
          fileSize: file.lengthSync(),
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des photos: $e');
      return [];
    }
  }

  /// Supprimer une photo
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression de la photo: $e');
      return false;
    }
  }

  /// Renommer une photo
  Future<bool> renamePhoto(String photoPath, String newName) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        final directory = file.parent;
        final extension = path.extension(photoPath);
        final newPath = path.join(directory.path, '$newName$extension');
        await file.rename(newPath);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors du renommage de la photo: $e');
      return false;
    }
  }

  /// Sauvegarder une photo dans la liste
  Future<void> _savePhoto(PhotoItem photo) async {
    // Cette méthode peut être étendue pour sauvegarder des métadonnées
    // Pour l'instant, on se contente de la sauvegarder dans le système de fichiers
  }
}

