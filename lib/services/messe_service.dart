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
  /// messeId: ID de la messe (RubriqueSection)
  static Future<ApiResponse<List<MesseSection>>> getMesseSections(int messeId) async {
    print('🔄 Récupération des sections pour la messe ID: $messeId');
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
          // Passer messeId pour que les sections aient le bon ID de RubriqueSection
          List<MesseSection> sections = BackendAdapter.referencesToMesseSections(data['data'], messeId: messeId);
          print('✅ ${sections.length} section(s) trouvée(s) pour la messe $messeId');
          for (var section in sections) {
            print('   - ${section.nom} (ID: ${section.id}, messeId: ${section.messeId})');
          }
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
  /// sectionId: ID de la section (référence générée)
  /// messeId: ID réel de la RubriqueSection (messe) - utilisé pour récupérer les partitions
  /// sectionName: Nom de la section (ex: "Kyrié", "Sanctus") - utilisé pour filtrer par messe_part
  static Future<ApiResponse<List<ChantDeMesse>>> getSectionChants(int sectionId, {int? messeId, String? sectionName}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return ApiResponse<List<ChantDeMesse>>(error: 'Token non disponible');
      }
      
      // Utiliser messeId si fourni, sinon utiliser sectionId (pour compatibilité)
      // Le backend attend l'ID réel de la RubriqueSection (messeId)
      final referenceId = messeId ?? sectionId;
      
      print('🔄 Récupération des partitions pour sectionId: $sectionId, messeId: $messeId, referenceId utilisé: $referenceId');
      
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/references/$referenceId/partitions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Réponse brute du serveur pour partitions: ${response.body}');
        
        if (data['success'] == true) {
          // Vérifier si data existe et n'est pas null
          if (data['data'] != null && data['data'] is List) {
            final partitionsList = data['data'] as List;
            print('📦 ${partitionsList.length} partition(s) reçue(s) du serveur');
            
            // Filtrer les partitions par messe_part pour éviter le mélange entre différentes messes
            // Si plusieurs messes ont des sections avec le même rubrique_section_id,
            // on filtre par le nom de la partie (messe_part['part']) qui doit correspondre au nom de la section
            List<dynamic> filteredPartitions = partitionsList;
            
            if (sectionName != null && sectionName.isNotEmpty) {
              // Filtrer les partitions dont le messe_part['part'] correspond au nom de la section
              filteredPartitions = partitionsList.where((partition) {
                if (partition['messe_part'] == null) {
                  // Si pas de messe_part, on garde la partition (pour compatibilité)
                  return true;
                }
                
                // Parser messe_part (peut être une string JSON ou un objet)
                dynamic messePart = partition['messe_part'];
                Map<String, dynamic>? messePartMap;
                
                if (messePart is String) {
                  try {
                    messePartMap = json.decode(messePart) as Map<String, dynamic>?;
                  } catch (e) {
                    print('⚠️ Erreur parsing messe_part: $e');
                    return true; // Garder la partition si erreur de parsing
                  }
                } else if (messePart is Map) {
                  messePartMap = messePart as Map<String, dynamic>;
                }
                
                if (messePartMap != null) {
                  final part = messePartMap['part']?.toString() ?? '';
                  // Comparer le nom de la partie avec le nom de la section (insensible à la casse)
                  // Normaliser les noms (enlever accents, espaces multiples, etc.)
                  final normalizedPart = part.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
                  final normalizedSectionName = sectionName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
                  final matches = normalizedPart == normalizedSectionName;
                  if (!matches) {
                    print('🔍 Partition ${partition['id']} ("${partition['title']}") filtrée: messe_part["part"]="$part" != sectionName="$sectionName"');
                  } else {
                    print('✅ Partition ${partition['id']} ("${partition['title']}") correspond à la section "$sectionName"');
                  }
                  return matches;
                }
                
                return true; // Garder si pas de messe_part valide
              }).toList();
              
              print('📊 ${partitionsList.length} partition(s) reçue(s) -> ${filteredPartitions.length} après filtrage par section "$sectionName"');
            } else {
              print('📊 ${partitionsList.length} partition(s) reçue(s) (pas de filtrage par sectionName)');
            }
            
          // Utiliser l'adaptateur pour convertir les partitions en chants
            // IMPORTANT: Passer sectionId pour que les chants soient correctement associés à leur section
            // Le sectionId est l'ID de la référence générée, pas le messeId (rubrique_section_id)
            List<ChantDeMesse> chants = BackendAdapter.partitionsToChantsDeMesse(filteredPartitions, sectionId: sectionId);
            print('✅ ${chants.length} chant(s) converti(s) depuis les partitions pour la section $sectionId ($sectionName)');
            
            // Vérifier que tous les chants ont le bon sectionId
            for (var i = 0; i < chants.length; i++) {
              if (chants[i].sectionId != sectionId) {
                print('⚠️ Correction sectionId pour chant ${chants[i].id}: ${chants[i].sectionId} -> $sectionId');
                chants[i] = chants[i].copyWith(sectionId: sectionId);
              }
            }
          
            // Sauvegarder les chants dans le cache unifié (en mettant à jour les existants)
            // Utiliser updateChant pour chaque chant pour éviter d'écraser les autres sections
            for (var chant in chants) {
              await UnifiedCacheService.updateChant(chant);
            }
          
          return ApiResponse<List<ChantDeMesse>>(data: chants);
          } else {
            print('⚠️ Aucune partition dans la réponse (data est null ou vide)');
            return ApiResponse<List<ChantDeMesse>>(data: []);
          }
        } else {
          return ApiResponse<List<ChantDeMesse>>(error: data['message'] ?? 'Erreur serveur');
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        return ApiResponse<List<ChantDeMesse>>(error: 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<List<ChantDeMesse>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les chants d'une section depuis le cache local
  /// sectionId: ID de la section (référence générée) - DOIT être utilisé pour filtrer
  /// messeId: ID réel de la RubriqueSection (messe) - utilisé uniquement pour récupérer depuis le serveur
  static Future<List<ChantDeMesse>> getSectionChantsFromCache(int sectionId, {int? messeId}) async {
    try {
      // IMPORTANT: Toujours utiliser sectionId pour filtrer, pas messeId
      // Car plusieurs sections (Kyrié, Sanctus, etc.) peuvent avoir le même messeId
      // mais chaque section a son propre sectionId unique
      print('🔍 Récupération cache pour sectionId: $sectionId (messeId: $messeId)');
      final chants = await UnifiedCacheService.getChantsBySection(sectionId);
      print('📦 ${chants.length} chant(s) trouvé(s) dans le cache pour la section $sectionId');
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
