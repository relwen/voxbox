import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/models/chant_section.dart';
import 'package:voxbox/services/api_response.dart';
import 'package:voxbox/services/unified_cache_service.dart';
import 'package:voxbox/services/network_service.dart';

class ChantService {
  static const String _chantsKey = 'local_chants';
  static const String _sectionsKey = 'local_chant_sections';

  /// Récupérer toutes les sections de chants depuis le serveur
  static Future<ApiResponse<List<ChantSection>>> getSectionsFromServer() async {
    try {
      final isConnected = await NetworkService().isConnected();
      
      if (!isConnected) {
        print('📡 ChantService - Mode Hors-ligne détecté, chargement du cache...');
        final localSections = await UnifiedCacheService.getChantSections();
        if (localSections.isNotEmpty) {
          return ApiResponse<List<ChantSection>>(data: localSections);
        }
        return ApiResponse<List<ChantSection>>(error: 'Pas de connexion internet et aucun cache disponible');
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<List<ChantSection>>(error: 'Token non disponible');
      }
      
      final response = await http.get(
        Uri.parse(AppConstance.chantsDeMesseURL),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> sectionsData = data['data'] ?? [];
          List<ChantSection> sections = sectionsData
              .map((sectionData) => ChantSection.fromJson(sectionData))
              .toList();
          
          // Sauvegarder localement via UnifiedCacheService
          await UnifiedCacheService.saveOrUpdateChantSections(sections);
          
          return ApiResponse<List<ChantSection>>(data: sections);
        } else {
          return ApiResponse<List<ChantSection>>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        // En cas d'erreur serveur, tenter le cache
        final localSections = await UnifiedCacheService.getChantSections();
        if (localSections.isNotEmpty) {
          return ApiResponse<List<ChantSection>>(data: localSections);
        }
        return ApiResponse<List<ChantSection>>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur ChantService: $e');
      final localSections = await UnifiedCacheService.getChantSections();
      if (localSections.isNotEmpty) {
        return ApiResponse<List<ChantSection>>(data: localSections);
      }
      return ApiResponse<List<ChantSection>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les chants d'une section depuis le serveur
  static Future<ApiResponse<List<ChantDeMesse>>> getSectionChants(int sectionId) async {
    try {
      final isConnected = await NetworkService().isConnected();
      
      if (!isConnected) {
        final localSectionChants = await UnifiedCacheService.getChantsBySection(sectionId);
        if (localSectionChants.isNotEmpty) {
          return ApiResponse<List<ChantDeMesse>>(data: localSectionChants);
        }
        return ApiResponse<List<ChantDeMesse>>(error: 'Pas de connexion et aucun cache pour cette section');
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<List<ChantDeMesse>>(error: 'Token non disponible');
      }
      
      final response = await http.get(
        Uri.parse('${AppConstance.chantsDeMesseURL}/$sectionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> chantsData = data['data'] ?? [];
          List<ChantDeMesse> chants = chantsData
              .map((chantData) => ChantDeMesse.fromJson(chantData))
              .toList();
          
          // Mettre à jour le cache local via UnifiedCacheService
          await UnifiedCacheService.saveOrUpdateChants(chants);

          return ApiResponse<List<ChantDeMesse>>(data: chants);
        } else {
          return ApiResponse<List<ChantDeMesse>>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        final localSectionChants = await UnifiedCacheService.getChantsBySection(sectionId);
        if (localSectionChants.isNotEmpty) {
          return ApiResponse<List<ChantDeMesse>>(data: localSectionChants);
        }
        return ApiResponse<List<ChantDeMesse>>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      final localSectionChants = await UnifiedCacheService.getChantsBySection(sectionId);
      if (localSectionChants.isNotEmpty) {
        return ApiResponse<List<ChantDeMesse>>(data: localSectionChants);
      }
      return ApiResponse<List<ChantDeMesse>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les sections locales
  static Future<List<ChantSection>> getLocalSections() async {
    return await UnifiedCacheService.getChantSections();
  }

  /// Sauvegarder les sections localement
  static Future<void> saveLocalSections(List<ChantSection> sections) async {
    await UnifiedCacheService.saveOrUpdateChantSections(sections);
  }

  /// Récupérer les chants locaux
  static Future<List<ChantDeMesse>> getLocalChants() async {
    return await UnifiedCacheService.getChants();
  }

  /// Récupérer un chant local avec fichiers en attente
  static Future<ChantDeMesse?> getLocalChant(int chantId) async {
    return await UnifiedCacheService.getChant(chantId);
  }

  /// Sauvegarder les chants localement
  static Future<void> saveLocalChants(List<ChantDeMesse> chants) async {
    await UnifiedCacheService.saveOrUpdateChants(chants);
  }


  /// Créer une nouvelle section de chants
  static Future<ApiResponse<ChantSection>> createSection(String nom, String? description) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<ChantSection>(error: 'Token non disponible');
      }
      
      final response = await http.post(
        Uri.parse(AppConstance.chantsDeMesseURL),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nom': nom,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse<ChantSection>(data: ChantSection.fromJson(data['data']));
        } else {
          return ApiResponse<ChantSection>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse<ChantSection>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<ChantSection>(error: 'Erreur de connexion: $e');
    }
  }

  /// Mettre à jour une section de chants
  static Future<ApiResponse<ChantSection>> updateSection(int id, String nom, String? description) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<ChantSection>(error: 'Token non disponible');
      }
      
      final response = await http.put(
        Uri.parse('${AppConstance.chantsDeMesseURL}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nom': nom,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse<ChantSection>(data: ChantSection.fromJson(data['data']));
        } else {
          return ApiResponse<ChantSection>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse<ChantSection>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<ChantSection>(error: 'Erreur de connexion: $e');
    }
  }

  /// Supprimer une section de chants
  static Future<ApiResponse> deleteSection(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse(error: 'Token non disponible');
      }
      
      final response = await http.delete(
        Uri.parse('${AppConstance.chantsDeMesseURL}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse(data: data['message']);
      } else {
        return ApiResponse(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Erreur de connexion: $e');
    }
  }

  /// Synchroniser toutes les sections
  static Future<ApiResponse<List<ChantSection>>> syncAllSections() async {
    try {
      // Récupérer depuis le serveur
      final serverResponse = await getSectionsFromServer();
      if (serverResponse.error != null) {
        return serverResponse;
      }

      // Sauvegarder localement
      await saveLocalSections(serverResponse.data as List<ChantSection>);
      
      return serverResponse;
    } catch (e) {
      return ApiResponse<List<ChantSection>>(error: 'Erreur de synchronisation: $e');
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
          // Note: La synchronisation se fait via getSectionChants
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
          // Note: La synchronisation se fait via getSectionChants
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
          // Note: La synchronisation se fait via getSectionChants
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
          // Note: La synchronisation se fait via getSectionChants
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

  /// Upload d'un fichier avec métadonnées de pupitre
  static Future<ApiResponse> uploadFile(int chantId, {
    required String pupitre,
    required String fileType,
    File? audioFile,
    File? imageFile,
    File? pdfFile,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse(error: 'Token non disponible');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstance.baseURL}/api/chants/$chantId/upload-file'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['pupitre'] = pupitre;
      request.fields['file_type'] = fileType;

      if (audioFile != null) {
        request.files.add(await http.MultipartFile.fromPath('audio_file', audioFile.path));
      }
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));
      }
      if (pdfFile != null) {
        request.files.add(await http.MultipartFile.fromPath('pdf_file', pdfFile.path));
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return ApiResponse(data: data['data']);
        } else {
          return ApiResponse(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse(error: data['message'] ?? 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'upload du fichier: $e');
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
          // Note: La synchronisation se fait via getSectionChants
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
