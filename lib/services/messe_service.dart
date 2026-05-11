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
import 'package:voxbox/services/network_service.dart';

class MesseService {
  static const String _messesKey = 'local_messes';

  /// Récupérer les messes depuis le serveur
  static Future<ApiResponse<List<Messe>>> getMessessFromServer() async {
    try {
      final isConnected = await NetworkService().isConnected();

      if (!isConnected) {
        final localMesses = await UnifiedCacheService.getMesses();
        if (localMesses.isNotEmpty) {
          return ApiResponse<List<Messe>>(data: localMesses);
        }
        return ApiResponse<List<Messe>>(
            error: 'Pas de connexion internet et aucun cache disponible');
      }

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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          try {
            List<Messe> messes =
                BackendAdapter.backendDataListToMesses(data['data']);
            // Sauvegarder localement via UnifiedCacheService
            await UnifiedCacheService.saveOrUpdateMesses(messes);
            return ApiResponse<List<Messe>>(data: messes);
          } catch (e) {
            print('Erreur lors du parsing des messes: $e');
            return ApiResponse<List<Messe>>(error: 'Erreur de parsing: $e');
          }
        } else {
          return ApiResponse<List<Messe>>(
              error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        final localMesses = await UnifiedCacheService.getMesses();
        if (localMesses.isNotEmpty) {
          return ApiResponse<List<Messe>>(data: localMesses);
        }
        return ApiResponse<List<Messe>>(
            error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      final localMesses = await UnifiedCacheService.getMesses();
      if (localMesses.isNotEmpty) {
        return ApiResponse<List<Messe>>(data: localMesses);
      }
      return ApiResponse<List<Messe>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les messes locales
  static Future<List<Messe>> getLocalMessess() async {
    return await UnifiedCacheService.getMesses();
  }

  /// Sauvegarder les messes localement
  static Future<void> saveLocalMessess(List<Messe> messes) async {
    await UnifiedCacheService.saveOrUpdateMesses(messes);
  }

  /// Synchroniser les messes
  static Future<ApiResponse<List<Messe>>> syncMessess() async {
    try {
      // Récupérer depuis le serveur
      final serverResponse = await getMessessFromServer();
      if (serverResponse.error != null) {
        return serverResponse;
      }

      // Sauvegarder localement via UnifiedCacheService
      await UnifiedCacheService.saveOrUpdateMesses(serverResponse.data as List<Messe>);

      return serverResponse;
    } catch (e) {
      return ApiResponse<List<Messe>>(error: 'Erreur de synchronisation: $e');
    }
  }

  /// Récupérer les sections d'une messe
  /// messeId: ID de la messe (RubriqueSection)
  static Future<ApiResponse<List<MesseSection>>> getMesseSections(
      int messeId) async {
    print('🔄 Récupération des sections pour la messe ID: $messeId');
    try {
      final isConnected = await NetworkService().isConnected();

      if (!isConnected) {
        final localSections = await UnifiedCacheService.getSections();
        final messeSections =
            localSections.where((s) => s.messeId == messeId).toList();
        if (messeSections.isNotEmpty) {
          return ApiResponse<List<MesseSection>>(data: messeSections);
        }
        return ApiResponse<List<MesseSection>>(
            error: 'Pas de connexion et aucun cache pour cette messe');
      }

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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<MesseSection> sections =
              BackendAdapter.referencesToMesseSections(data['data'],
                  messeId: messeId);

          // Mettre à jour le cache via UnifiedCacheService
          await UnifiedCacheService.saveOrUpdateSections(sections);

          return ApiResponse<List<MesseSection>>(data: sections);
        } else {
          return ApiResponse<List<MesseSection>>(
              error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        final localSections = await UnifiedCacheService.getSections();
        final messeSections =
            localSections.where((s) => s.messeId == messeId).toList();
        if (messeSections.isNotEmpty) {
          return ApiResponse<List<MesseSection>>(data: messeSections);
        }
        return ApiResponse<List<MesseSection>>(
            error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      final localSections = await UnifiedCacheService.getSections();
      final messeSections =
          localSections.where((s) => s.messeId == messeId).toList();
      if (messeSections.isNotEmpty) {
        return ApiResponse<List<MesseSection>>(data: messeSections);
      }
      return ApiResponse<List<MesseSection>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les chants d'une section
  /// sectionId: ID de la section (référence générée)
  /// messeId: ID réel de la RubriqueSection (messe) - utilisé pour récupérer les partitions
  /// sectionName: Nom de la section (ex: "Kyrié", "Sanctus") - utilisé pour filtrer
  static Future<ApiResponse<List<ChantDeMesse>>> getSectionChants(int sectionId,
      {int? messeId, String? sectionName}) async {
    try {
      final isConnected = await NetworkService().isConnected();

      if (!isConnected) {
        final cacheChants =
            await getSectionChantsFromCache(sectionId, messeId: messeId);
        if (cacheChants.isNotEmpty) {
          return ApiResponse<List<ChantDeMesse>>(data: cacheChants);
        }
        return ApiResponse<List<ChantDeMesse>>(
            error: 'Pas de connexion et aucun cache pour cette section');
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        return ApiResponse<List<ChantDeMesse>>(error: 'Token non disponible');
      }

      final referenceId = messeId ?? sectionId;

      final response = await http.get(
        Uri.parse(
            '${AppConstance.baseURL}/api/references/$referenceId/partitions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          if (data['data'] != null && data['data'] is List) {
            final partitionsList = data['data'] as List;

            List<dynamic> filteredPartitions = partitionsList;

            if (sectionName != null && sectionName.isNotEmpty) {
              filteredPartitions = partitionsList.where((partition) {
                if (partition['messe_part'] == null) return true;

                dynamic messePart = partition['messe_part'];
                Map<String, dynamic>? messePartMap;

                if (messePart is String) {
                  try {
                    messePartMap =
                        json.decode(messePart) as Map<String, dynamic>?;
                  } catch (e) {
                    return true;
                  }
                } else if (messePart is Map) {
                  messePartMap = messePart as Map<String, dynamic>;
                }

                if (messePartMap != null) {
                  final part = messePartMap['part']?.toString() ?? '';
                  final normalizedPart =
                      part.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
                  final normalizedSectionName = sectionName
                      .toLowerCase()
                      .trim()
                      .replaceAll(RegExp(r'\s+'), ' ');
                  return normalizedPart == normalizedSectionName;
                }

                return true;
              }).toList();
            }

            List<ChantDeMesse> chants =
                BackendAdapter.partitionsToChantsDeMesse(filteredPartitions,
                    sectionId: sectionId);

            for (var i = 0; i < chants.length; i++) {
              if (chants[i].sectionId != sectionId) {
                chants[i] = chants[i].copyWith(sectionId: sectionId);
              }
            }

            // Mettre à jour le cache local via UnifiedCacheService
            await UnifiedCacheService.saveOrUpdateChants(chants);

            return ApiResponse<List<ChantDeMesse>>(data: chants);
          } else {
            return ApiResponse<List<ChantDeMesse>>(data: []);
          }
        } else {
          return ApiResponse<List<ChantDeMesse>>(
              error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        final cacheChants =
            await getSectionChantsFromCache(sectionId, messeId: messeId);
        if (cacheChants.isNotEmpty) {
          return ApiResponse<List<ChantDeMesse>>(data: cacheChants);
        }
        return ApiResponse<List<ChantDeMesse>>(
            error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      final cacheChants =
          await getSectionChantsFromCache(sectionId, messeId: messeId);
      if (cacheChants.isNotEmpty) {
        return ApiResponse<List<ChantDeMesse>>(data: cacheChants);
      }
      return ApiResponse<List<ChantDeMesse>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les chants d'une section depuis le cache local
  /// sectionId: ID de la section (référence générée) - DOIT être utilisé pour filtrer
  /// messeId: ID réel de la RubriqueSection (messe) - utilisé uniquement pour récupérer depuis le serveur
  static Future<List<ChantDeMesse>> getSectionChantsFromCache(int sectionId,
      {int? messeId}) async {
    try {
      // IMPORTANT: Toujours utiliser sectionId pour filtrer, pas messeId
      // Car plusieurs sections (Kyrié, Sanctus, etc.) peuvent avoir le même messeId
      // mais chaque section a son propre sectionId unique
      print(
          '🔍 Récupération cache pour sectionId: $sectionId (messeId: $messeId)');
      final chants = await UnifiedCacheService.getChantsBySection(sectionId);
      print(
          '📦 ${chants.length} chant(s) trouvé(s) dans le cache pour la section $sectionId');
      return chants;
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
        Uri.parse(
            '${AppConstance.baseURL}/api/chants-de-messe/${chant.id}/download-audio'),
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

        final fileName =
            'chant_${chant.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
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
        Uri.parse(
            '${AppConstance.baseURL}/api/chants-de-messe/${chant.id}/download-pdf'),
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

        final fileName =
            'chant_${chant.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
  static Future<void> _updateLocalAudioPath(
      int chantId, String localPath) async {
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

