import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/services/api_response.dart';
import 'package:voxbox/services/unified_cache_service.dart';
import 'package:voxbox/services/backend_adapter.dart';

class MesseService {
  static const String _messesKey = 'local_messes';

  /// Récupérer les messes depuis le serveur
  static Future<ApiResponse<List<Messe>>> getMessessFromServer() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<List<Messe>>(error: 'Token non disponible');
      }
      final response = await http.get(
        Uri.parse(AppConstance.messesURL),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          try {
            // Utiliser l'adaptateur pour convertir les données backend
            List<Messe> messes = BackendAdapter.backendDataListToMesses(data['data']);
            return ApiResponse<List<Messe>>(data: messes);
          } catch (e) {
            print('Erreur lors du parsing des messes: $e');
            return ApiResponse<List<Messe>>(error: 'Erreur de parsing: $e');
          }
        } else {
          return ApiResponse<List<Messe>>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse<List<Messe>>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<List<Messe>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les messes locales
  static Future<List<Messe>> getLocalMessess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messesJson = prefs.getString(_messesKey);
      if (messesJson != null) {
        final List<dynamic> messesList = json.decode(messesJson);
        return messesList.map((json) => Messe.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des messes locales: $e');
      return [];
    }
  }

  /// Sauvegarder les messes localement
  static Future<void> saveLocalMessess(List<Messe> messes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messesJson = json.encode(messes.map((messe) => messe.toJson()).toList());
      await prefs.setString(_messesKey, messesJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde des messes: $e');
    }
  }

  /// Synchroniser les messes
  static Future<ApiResponse<List<Messe>>> syncMessess() async {
    try {
      // Récupérer depuis le serveur
      final serverResponse = await getMessessFromServer();
      if (serverResponse.error != null) {
        return serverResponse;
      }

      // Sauvegarder localement
      await saveLocalMessess(serverResponse.data as List<Messe>);
      
      return serverResponse;
    } catch (e) {
      return ApiResponse<List<Messe>>(error: 'Erreur de synchronisation: $e');
    }
  }

  /// Récupérer les sections d'une messe
  static Future<ApiResponse<List<MesseSection>>> getMesseSections(int messeId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<List<MesseSection>>(error: 'Token non disponible');
      }
      final response = await http.get(
        Uri.parse('${AppConstance.messesURL}/$messeId/sections'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Utiliser l'adaptateur pour convertir les références en sections
          List<MesseSection> sections = BackendAdapter.referencesToMesseSections(data['data']);
          return ApiResponse<List<MesseSection>>(data: sections);
        } else {
          return ApiResponse<List<MesseSection>>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse<List<MesseSection>>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<List<MesseSection>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les chants d'une section
  static Future<ApiResponse<List<ChantDeMesse>>> getSectionChants(int sectionId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<List<ChantDeMesse>>(error: 'Token non disponible');
      }
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/references/$sectionId/partitions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Utiliser l'adaptateur pour convertir les partitions en chants
          List<ChantDeMesse> chants = BackendAdapter.partitionsToChantsDeMesse(data['data']);
          
          // Sauvegarder les chants dans le cache unifié
          await UnifiedCacheService.saveChants(chants);
          
          return ApiResponse<List<ChantDeMesse>>(data: chants);
        } else {
          return ApiResponse<List<ChantDeMesse>>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        return ApiResponse<List<ChantDeMesse>>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<List<ChantDeMesse>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les chants d'une section depuis le cache local
  static Future<List<ChantDeMesse>> getSectionChantsFromCache(int sectionId) async {
    try {
      // Utiliser le service unifié pour récupérer les chants avec leurs fichiers locaux
      return await UnifiedCacheService.getChantsBySection(sectionId);
    } catch (e) {
      print('Erreur lors de la récupération des chants du cache: $e');
      return [];
    }
  }

  /// Télécharger un fichier audio
  static Future<bool> downloadAudio(ChantDeMesse chant) async {
    if (chant.audioPath == null) return false;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return false;
      }
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/${chant.id}/download-audio'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory('${directory.path}/audio');
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }

        final fileName = 'chant_${chant.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File('${audioDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Mettre à jour le chemin local dans les préférences
        await _updateLocalAudioPath(chant.id, file.path);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors du téléchargement audio: $e');
      return false;
    }
  }

  /// Télécharger un fichier PDF
  static Future<bool> downloadPdf(ChantDeMesse chant) async {
    if (chant.pdfPath == null) return false;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return false;
      }
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/chants-de-messe/${chant.id}/download-pdf'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final pdfDir = Directory('${directory.path}/pdfs');
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }

        final fileName = 'chant_${chant.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${pdfDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Mettre à jour le chemin local dans les préférences
        await _updateLocalPdfPath(chant.id, file.path);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors du téléchargement PDF: $e');
      return false;
    }
  }

  /// Mettre à jour le chemin audio local
  static Future<void> _updateLocalAudioPath(int chantId, String localPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('audio_path_$chantId', localPath);
    } catch (e) {
      print('Erreur lors de la mise à jour du chemin audio: $e');
    }
  }

  /// Mettre à jour le chemin PDF local
  static Future<void> _updateLocalPdfPath(int chantId, String localPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pdf_path_$chantId', localPath);
    } catch (e) {
      print('Erreur lors de la mise à jour du chemin PDF: $e');
    }
  }

  /// Récupérer le chemin audio local
  static Future<String?> getLocalAudioPath(int chantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('audio_path_$chantId');
    } catch (e) {
      return null;
    }
  }

  /// Récupérer le chemin PDF local
  static Future<String?> getLocalPdfPath(int chantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('pdf_path_$chantId');
    } catch (e) {
      return null;
    }
  }
}
