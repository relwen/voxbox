import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/services/api_response.dart';
import 'package:voxbox/services/unified_cache_service.dart';

class ChantService {
  static const String _chantsKey = 'local_chants';

  /// Récupérer un chant spécifique depuis le serveur
  static Future<ApiResponse<ChantDeMesse>> getChantFromServer(int chantId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<ChantDeMesse>(error: 'Token non disponible');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/$chantId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ChantDeMesse chant = ChantDeMesse.fromJson(data['data']);
          return ApiResponse<ChantDeMesse>(data: chant);
        } else {
          return ApiResponse<ChantDeMesse>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse<ChantDeMesse>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<ChantDeMesse>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les chants locaux
  static Future<List<ChantDeMesse>> getLocalChants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chantsJson = prefs.getString(_chantsKey);
      if (chantsJson != null) {
        final List<dynamic> chantsList = json.decode(chantsJson);
        return chantsList.map((json) => ChantDeMesse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des chants locaux: $e');
      return [];
    }
  }

  /// Récupérer un chant local avec fichiers en attente
  static Future<ChantDeMesse?> getLocalChant(int chantId) async {
    try {
      // Utiliser le service unifié pour récupérer le chant avec ses fichiers locaux
      return await UnifiedCacheService.getChant(chantId);
    } catch (e) {
      print('Erreur lors de la récupération du chant local: $e');
      return null;
    }
  }

  /// Sauvegarder les chants localement
  static Future<void> saveLocalChants(List<ChantDeMesse> chants) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chantsJson = json.encode(chants.map((chant) => chant.toJson()).toList());
      await prefs.setString(_chantsKey, chantsJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde des chants: $e');
    }
  }

  /// Synchroniser un chant spécifique
  static Future<ApiResponse<ChantDeMesse>> syncChant(int chantId) async {
    try {
      // Récupérer depuis le serveur
      final serverResponse = await getChantFromServer(chantId);
      if (serverResponse.error != null) {
        return serverResponse;
      }

      // Mettre à jour localement
      List<ChantDeMesse> localChants = await getLocalChants();
      localChants.removeWhere((chant) => chant.id == chantId);
      localChants.add(serverResponse.data as ChantDeMesse);
      await saveLocalChants(localChants);
      
      return serverResponse;
    } catch (e) {
      return ApiResponse<ChantDeMesse>(error: 'Erreur de synchronisation: $e');
    }
  }

  /// Ajouter des fichiers audio à un chant
  static Future<ApiResponse> addAudioFiles(int chantId, List<File> audioFiles) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse(error: 'Token non disponible');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/$chantId/audio-files'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Ajouter les fichiers audio
      for (int i = 0; i < audioFiles.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'audio_files[]',
            audioFiles[i].path,
          ),
        );
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          // Synchroniser le chant mis à jour
          await syncChant(chantId);
          return ApiResponse(data: data['message']);
        } else {
          return ApiResponse(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Erreur de connexion: $e');
    }
  }

  /// Ajouter des fichiers PDF à un chant
  static Future<ApiResponse> addPdfFiles(int chantId, List<File> pdfFiles) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse(error: 'Token non disponible');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/$chantId/pdf-files'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Ajouter les fichiers PDF
      for (int i = 0; i < pdfFiles.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pdf_files[]',
            pdfFiles[i].path,
          ),
        );
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          // Synchroniser le chant mis à jour
          await syncChant(chantId);
          return ApiResponse(data: data['message']);
        } else {
          return ApiResponse(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Erreur de connexion: $e');
    }
  }

  /// Ajouter des fichiers image à un chant
  static Future<ApiResponse> addImageFiles(int chantId, List<File> imageFiles) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse(error: 'Token non disponible');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/$chantId/image-files'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Ajouter les fichiers image
      for (int i = 0; i < imageFiles.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image_files[]',
            imageFiles[i].path,
          ),
        );
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          // Synchroniser le chant mis à jour
          await syncChant(chantId);
          return ApiResponse(data: data['message']);
        } else {
          return ApiResponse(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Erreur de connexion: $e');
    }
  }

  /// Ajouter des fichiers pour un pupitre spécifique
  static Future<ApiResponse> addPupitreFiles(int chantId, String pupitre, List<File> files) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse(error: 'Token non disponible');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/$chantId/pupitre-files'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Ajouter le pupitre
      request.fields['pupitre'] = pupitre.toLowerCase();

      // Ajouter les fichiers
      for (int i = 0; i < files.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files[]',
            files[i].path,
          ),
        );
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          // Synchroniser le chant mis à jour
          await syncChant(chantId);
          return ApiResponse(data: data['message']);
        } else {
          return ApiResponse(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Erreur de connexion: $e');
    }
  }

  /// Mettre à jour les informations d'un chant
  static Future<ApiResponse> updateChantInfo(int chantId, {
    String? titre,
    String? description,
    int? ordre,
    bool? active,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse(error: 'Token non disponible');
      }

      Map<String, dynamic> body = {};
      if (titre != null) body['titre'] = titre;
      if (description != null) body['description'] = description;
      if (ordre != null) body['ordre'] = ordre;
      if (active != null) body['active'] = active;

      final response = await http.put(
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/$chantId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Synchroniser le chant mis à jour
          await syncChant(chantId);
          return ApiResponse(data: data['message']);
        } else {
          return ApiResponse(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Erreur de connexion: $e');
    }
  }

  /// Télécharger un fichier
  static Future<bool> downloadFile(String fileUrl, String fileName) async {
    try {
      // Construire l'URL complète si c'est un chemin relatif
      String fullUrl = fileUrl;
      if (!fileUrl.startsWith('http')) {
        // Si c'est un chemin relatif, construire l'URL complète
        if (fileUrl.startsWith('/')) {
          fullUrl = '${AppConstance.baseURL}$fileUrl';
        } else {
          fullUrl = '${AppConstance.baseURL}/storage/$fileUrl';
        }
      }
      
      print('Téléchargement de: $fullUrl');
      
      final response = await http.get(
        Uri.parse(fullUrl),
        // Ne pas ajouter d'authentification pour les fichiers publics
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        print('Fichier téléchargé vers: ${file.path}');
        return true;
      } else {
        print('Erreur HTTP: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erreur lors du téléchargement: $e');
      return false;
    }
  }

  /// Ajouter des fichiers en attente localement
  static Future<void> addPendingFiles(int chantId, String type, List<String> filePaths, String? pupitre) async {
    try {
      // Utiliser le service unifié pour ajouter les fichiers en attente
      for (String filePath in filePaths) {
        await UnifiedCacheService.addPendingFile(
          chantId: chantId,
          filePath: filePath,
          fileType: type,
          pupitre: pupitre,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'ajout des fichiers en attente: $e');
    }
  }

  /// Récupérer les fichiers en attente
  static Future<List<Map<String, dynamic>>> getPendingFiles(int chantId) async {
    try {
      // Utiliser le service unifié pour récupérer les fichiers en attente
      return await UnifiedCacheService.getPendingFiles(chantId);
    } catch (e) {
      print('Erreur lors de la récupération des fichiers en attente: $e');
      return [];
    }
  }

  /// Marquer les fichiers comme synchronisés
  static Future<void> markFilesAsSynced(int chantId, List<String> filePaths) async {
    try {
      // Utiliser le service unifié pour marquer les fichiers comme synchronisés
      await UnifiedCacheService.markFilesAsSynced(chantId, filePaths);
    } catch (e) {
      print('Erreur lors du marquage des fichiers comme synchronisés: $e');
    }
  }

  /// Supprimer les fichiers synchronisés
  static Future<void> removeSyncedFiles(int chantId) async {
    try {
      // Utiliser le service unifié pour supprimer les fichiers synchronisés
      await UnifiedCacheService.removeSyncedFiles(chantId);
    } catch (e) {
      print('Erreur lors de la suppression des fichiers synchronisés: $e');
    }
  }


  /// Vérifier s'il y a des fichiers en attente de synchronisation
  static Future<bool> hasPendingFiles(int chantId) async {
    try {
      // Utiliser le service unifié pour vérifier les fichiers en attente
      return await UnifiedCacheService.hasPendingFiles(chantId);
    } catch (e) {
      return false;
    }
  }
}
