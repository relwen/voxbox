import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/api_response.dart';

class FileUploadService {
  // Types de fichiers supportés
  static const Map<String, List<String>> supportedFileTypes = {
    'audio': ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
    'pdf': ['pdf'],
    'image': ['jpg', 'jpeg', 'png', 'gif', 'webp'],
  };

  // Tailles maximales (en MB)
  static const Map<String, int> maxFileSizes = {
    'audio': 10,
    'pdf': 20,
    'image': 5,
  };

  /// Sélectionner un fichier audio
  static Future<File?> selectAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        File file = File(result.files.first.path!);
        
        // Vérifier la taille du fichier
        if (await _validateFileSize(file, 'audio')) {
          print('Fichier audio sélectionné: ${file.path}');
          return file;
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la sélection du fichier audio: $e');
      return null;
    }
  }

  /// Sélectionner un fichier PDF
  static Future<File?> selectPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        File file = File(result.files.first.path!);
        
        // Vérifier la taille du fichier
        if (await _validateFileSize(file, 'pdf')) {
          print('Fichier PDF sélectionné: ${file.path}');
          return file;
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la sélection du fichier PDF: $e');
      return null;
    }
  }

  /// Sélectionner une image
  static Future<File?> selectImageFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        File file = File(image.path);
        
        // Vérifier la taille du fichier
        if (await _validateFileSize(file, 'image')) {
          return file;
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }

  /// Sélectionner plusieurs fichiers audio
  static Future<List<File>> selectMultipleAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> validFiles = [];
        
        for (PlatformFile platformFile in result.files) {
          if (platformFile.path != null) {
            File file = File(platformFile.path!);
            if (await _validateFileSize(file, 'audio')) {
              validFiles.add(file);
            }
          }
        }
        
        print('${validFiles.length} fichiers audio sélectionnés');
        return validFiles;
      }
      return [];
    } catch (e) {
      print('Erreur lors de la sélection des fichiers audio: $e');
      return [];
    }
  }

  /// Sélectionner plusieurs fichiers PDF
  static Future<List<File>> selectMultiplePdfFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> validFiles = [];
        
        for (PlatformFile platformFile in result.files) {
          if (platformFile.path != null) {
            File file = File(platformFile.path!);
            if (await _validateFileSize(file, 'pdf')) {
              validFiles.add(file);
            }
          }
        }
        
        print('${validFiles.length} fichiers PDF sélectionnés');
        return validFiles;
      }
      return [];
    } catch (e) {
      print('Erreur lors de la sélection des fichiers PDF: $e');
      return [];
    }
  }

  /// Sélectionner plusieurs images
  static Future<List<File>> selectMultipleImageFiles() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      List<File> validFiles = [];
      
      for (XFile image in images) {
        File file = File(image.path);
        if (await _validateFileSize(file, 'image')) {
          validFiles.add(file);
        }
      }
      
      return validFiles;
    } catch (e) {
      print('Erreur lors de la sélection des images: $e');
      return [];
    }
  }

  /// Uploader un fichier vers le serveur
  static Future<ApiResponse> uploadFile({
    required File file,
    required String endpoint,
    required String fieldName,
    Map<String, String>? additionalFields,
    String? description,
  }) async {
    ApiResponse apiResponse = ApiResponse();

    try {
      print('🔄 Upload du fichier: ${file.path}');
      print('🌐 Endpoint: $endpoint');
      
      // Récupérer le token d'authentification
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        apiResponse.error = 'Token d\'authentification non disponible';
        return apiResponse;
      }

      // Créer la requête multipart
      var request = http.MultipartRequest('POST', Uri.parse('${AppConstance.baseURL}$endpoint'));
      
      // Ajouter les headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Ajouter le fichier
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

      // Ajouter les champs supplémentaires
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Ajouter la description si fournie
      if (description != null) {
        request.fields['description'] = description;
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            apiResponse.data = responseData['data'];
            print('✅ Upload réussi!');
          } else {
            apiResponse.error = responseData['message'] ?? 'Erreur lors de l\'upload';
          }
          break;
        case 413:
          apiResponse.error = 'Fichier trop volumineux';
          break;
        case 422:
          final errors = jsonDecode(response.body)['errors'];
          apiResponse.error = errors[errors.keys.elementAt(0)][0];
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = "Erreur serveur (${response.statusCode})";
      }
    } catch (e) {
      apiResponse.error = "Erreur de connexion: $e";
      print('💥 Exception lors de l\'upload: $e');
    }

    return apiResponse;
  }

  /// Uploader plusieurs fichiers
  static Future<ApiResponse> uploadMultipleFiles({
    required List<File> files,
    required String endpoint,
    required String fieldName,
    Map<String, String>? additionalFields,
  }) async {
    ApiResponse apiResponse = ApiResponse();

    try {
      print('🔄 Upload de ${files.length} fichiers');
      print('🌐 Endpoint: $endpoint');
      
      // Récupérer le token d'authentification
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        apiResponse.error = 'Token d\'authentification non disponible';
        return apiResponse;
      }

      // Créer la requête multipart
      var request = http.MultipartRequest('POST', Uri.parse('${AppConstance.baseURL}$endpoint'));
      
      // Ajouter les headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Ajouter tous les fichiers
      for (File file in files) {
        request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      }

      // Ajouter les champs supplémentaires
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            apiResponse.data = responseData['data'];
            print('✅ Upload de ${files.length} fichiers réussi!');
          } else {
            apiResponse.error = responseData['message'] ?? 'Erreur lors de l\'upload';
          }
          break;
        case 413:
          apiResponse.error = 'Fichiers trop volumineux';
          break;
        case 422:
          final errors = jsonDecode(response.body)['errors'];
          apiResponse.error = errors[errors.keys.elementAt(0)][0];
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = "Erreur serveur (${response.statusCode})";
      }
    } catch (e) {
      apiResponse.error = "Erreur de connexion: $e";
      print('💥 Exception lors de l\'upload multiple: $e');
    }

    return apiResponse;
  }

  /// Valider la taille d'un fichier
  static Future<bool> _validateFileSize(File file, String fileType) async {
    try {
      int fileSizeInBytes = await file.length();
      int maxSizeInBytes = maxFileSizes[fileType]! * 1024 * 1024; // Convertir MB en bytes
      
      if (fileSizeInBytes > maxSizeInBytes) {
        print('❌ Fichier trop volumineux: ${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB (max: ${maxFileSizes[fileType]}MB)');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la validation de la taille: $e');
      return false;
    }
  }

  /// Obtenir l'extension d'un fichier
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  /// Vérifier si un fichier est d'un type supporté
  static bool isFileTypeSupported(String filePath, String fileType) {
    String extension = getFileExtension(filePath);
    return supportedFileTypes[fileType]?.contains(extension) ?? false;
  }

  /// Formater la taille d'un fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Obtenir le nom du fichier sans le chemin
  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }
}
