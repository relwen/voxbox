import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/models/vocalise_section.dart';
import 'package:voxbox/services/api_response.dart';
import 'package:voxbox/services/backend_adapter.dart';

class VocaliseService {
  static const String _localVocalisesKey = 'local_vocalises';
  static const String _localSectionsKey = 'local_vocalise_sections';
  static const String _lastSyncKey = 'vocalises_last_sync';
  static const String _downloadedAudiosKey = 'downloaded_audios';

  // Récupérer les sections depuis le stockage local
  static Future<List<VocaliseSection>> getLocalSections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sectionsJson = prefs.getString(_localSectionsKey);

    if (sectionsJson != null) {
      List<dynamic> sectionsList = jsonDecode(sectionsJson);
      return sectionsList.map((json) => VocaliseSection.fromJson(json)).toList();
    }
    return [];
  }

  // Sauvegarder les sections localement
  static Future<void> saveLocalSections(List<VocaliseSection> sections) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sectionsJson = jsonEncode(sections.map((section) => section.toJson()).toList());
    await prefs.setString(_localSectionsKey, sectionsJson);
  }

  // Récupérer les vocalises depuis le stockage local
  static Future<List<Vocalise>> getLocalVocalises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? vocalisesJson = prefs.getString(_localVocalisesKey);

    if (vocalisesJson != null) {
      List<dynamic> vocalisesList = jsonDecode(vocalisesJson);
      return vocalisesList.map((json) => Vocalise.fromJson(json)).toList();
    }
    return [];
  }

  // Sauvegarder les vocalises localement
  static Future<void> saveLocalVocalises(List<Vocalise> vocalises) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String vocalisesJson = jsonEncode(vocalises.map((vocalise) => vocalise.toJson()).toList());
    await prefs.setString(_localVocalisesKey, vocalisesJson);
  }

  // Récupérer la dernière synchronisation
  static Future<String> getLastSync() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey) ?? '1970-01-01 00:00:00';
  }

  // Sauvegarder la dernière synchronisation
  static Future<void> saveLastSync(String lastSync) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, lastSync);
  }

  // Récupérer la liste des fichiers audio téléchargés
  static Future<List<String>> getDownloadedAudios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? downloadedJson = prefs.getString(_downloadedAudiosKey);
    
    if (downloadedJson != null) {
      List<dynamic> downloadedList = jsonDecode(downloadedJson);
      return downloadedList.cast<String>();
    }
    return [];
  }

  // Sauvegarder la liste des fichiers audio téléchargés
  static Future<void> saveDownloadedAudios(List<String> downloadedAudios) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String downloadedJson = jsonEncode(downloadedAudios);
    await prefs.setString(_downloadedAudiosKey, downloadedJson);
  }

  // Récupérer les sections depuis le serveur
  static Future<ApiResponse> getSectionsFromServer() async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      print('🔄 Chargement des sections de vocalises depuis le backend...');

      final response = await http.get(
        Uri.parse(AppConstance.vocalisesURL),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Status HTTP: ${response.statusCode}');

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body);
          print('📦 Success: ${responseData['success']}, Data présent: ${responseData['data'] != null}');

          if (responseData['success'] == true && responseData['data'] != null) {
            List<VocaliseSection> sections = [];
            List<dynamic> sectionsData = responseData['data'];

            for (var sectionData in sectionsData) {
              // Compter les vocalises dans cette section
              int vocalisesCount = 0;
              if (sectionData['vocalises'] != null && sectionData['vocalises'] is List) {
                List vocalises = sectionData['vocalises'];
                for (var item in vocalises) {
                  if (item is Map && item['vocalises'] != null && item['vocalises'] is List) {
                    vocalisesCount += (item['vocalises'] as List).length;
                  } else {
                    vocalisesCount++;
                  }
                }
              }

              sections.add(VocaliseSection(
                id: sectionData['id'] ?? 0,
                nom: sectionData['nom'] ?? 'Section sans nom',
                description: sectionData['description'],
                type: sectionData['type'] ?? 'section',
                couleur: sectionData['couleur'] ?? '#9C27B0',
                icone: sectionData['icone'] ?? 'music_note',
                vocalisesCount: vocalisesCount,
                createdAt: DateTime.tryParse(sectionData['created_at']?.toString() ?? '') ?? DateTime.now(),
                updatedAt: DateTime.tryParse(sectionData['updated_at']?.toString() ?? '') ?? DateTime.now(),
              ));
            }

            print('✅ ${sections.length} section(s) de vocalises récupérée(s)');

            // Sauvegarder localement
            await saveLocalSections(sections);

            apiResponse.data = sections;
            apiResponse.error = null;
          } else {
            print('ℹ️ Aucune section disponible');
            apiResponse.data = [];
            apiResponse.error = null;
          }
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        case 403:
          apiResponse.error = 'Accès refusé';
          break;
        default:
          apiResponse.error = 'Erreur serveur (${response.statusCode})';
          break;
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      apiResponse.error = 'Erreur de connexion';
    }
    return apiResponse;
  }

  // Synchroniser toutes les sections
  static Future<ApiResponse> syncAllSections() async {
    return await getSectionsFromServer();
  }

  // Récupérer les vocalises d'une section spécifique
  static Future<ApiResponse> getVocalisesBySection(int sectionId) async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      print('🔄 Chargement des vocalises de la section $sectionId...');

      // Utiliser la route spécifique pour récupérer les vocalises
      final response = await http.get(
        Uri.parse('${AppConstance.vocalisesURL}/$sectionId/vocalises'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status HTTP: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      switch (response.statusCode) {
        case 200:
          try {
            final responseData = jsonDecode(response.body);
            print('📦 Success: ${responseData['success']}, Data présent: ${responseData['data'] != null}');

            if (responseData['success'] == true && responseData['data'] != null) {
              final vocalisesData = responseData['data'];
              print('📋 Type data: ${vocalisesData.runtimeType}');

              List<Vocalise> vocalises = [];

              // La route /vocalises retourne directement les vocalises ou les parties avec vocalises
              if (vocalisesData is List) {
                print('📋 ${vocalisesData.length} élément(s) dans data');

                // Vérifier si c'est un tableau de parties ou directement de vocalises
                for (var item in vocalisesData) {
                  if (item is Map) {
                    // Si l'item a un champ 'vocalises', c'est une partie
                    if (item['vocalises'] != null && item['vocalises'] is List) {
                      print('📦 Partie "${item['name']}" avec ${(item['vocalises'] as List).length} vocalise(s)');
                      for (var vocaliseData in item['vocalises']) {
                        try {
                          vocalises.add(BackendAdapter.backendDataToVocalise(Map<String, dynamic>.from(vocaliseData)));
                        } catch (e) {
                          print('❌ Erreur conversion vocalise: $e');
                        }
                      }
                    }
                    // Sinon c'est directement une vocalise
                    else if (item['titre'] != null || item['title'] != null) {
                      try {
                        vocalises.add(BackendAdapter.backendDataToVocalise(Map<String, dynamic>.from(item)));
                      } catch (e) {
                        print('❌ Erreur conversion vocalise directe: $e');
                      }
                    }
                  }
                }

                print('✅ ${vocalises.length} vocalise(s) convertie(s) au total');
              }

              apiResponse.data = vocalises;
              apiResponse.error = null;
            } else {
              print('⚠️ Réponse sans succès ou data null');
              apiResponse.data = [];
              apiResponse.error = null;
            }
          } catch (e, stackTrace) {
            print('❌ Erreur parsing JSON: $e');
            print('📚 Stack: $stackTrace');
            apiResponse.error = 'Erreur de parsing: $e';
          }
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = 'Erreur serveur';
          break;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      apiResponse.error = 'Erreur de connexion';
    }
    return apiResponse;
  }

  // Récupérer les vocalises depuis le serveur (pour la synchronisation)
  static Future<ApiResponse> getVocalisesFromServer() async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      print('🔄 Synchronisation des vocalises depuis le backend...');

      final response = await http.get(
        Uri.parse(AppConstance.vocalisesURL),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          print('📥 Réponse brute du serveur: ${response.body}');
          try {
            final responseData = jsonDecode(response.body);
            print('📦 Success: ${responseData['success']}, Data présent: ${responseData['data'] != null}');
            print('📋 Type de data: ${responseData['data']?.runtimeType}');
            if (responseData['data'] != null && responseData['data'] is List) {
              print('📊 Nombre de sections: ${(responseData['data'] as List).length}');
            }

            if (responseData['success'] == true) {
              // Vérifier si data existe et n'est pas null
              if (responseData['data'] != null) {
                try {
                  // Utiliser l'adaptateur pour convertir les données backend
                  List<Vocalise> vocalises = BackendAdapter.backendDataListToVocalises(responseData['data']);

                  print('✅ ${vocalises.length} vocalise(s) récupérée(s) avec leurs fichiers organisés par pupitre');

                  // Mettre à jour le stockage local
                  await saveLocalVocalises(vocalises);

                  // Télécharger automatiquement les fichiers audio
                  await _downloadAllAudioFiles(vocalises);

                  apiResponse.data = vocalises;
                  apiResponse.error = null;
                } catch (e, stackTrace) {
                  print('❌ Erreur lors du parsing des vocalises: $e');
                  print('📚 Stack trace: $stackTrace');
                  apiResponse.error = 'Erreur de parsing: $e';
                }
              } else {
                // Aucune vocalise disponible, mais ce n'est pas une erreur
                print('ℹ️ Aucune vocalise disponible');
                apiResponse.data = [];
                apiResponse.error = null;
              }
            } else {
              print('❌ Erreur backend: ${responseData['message']}');
              print('📋 Structure de réponse: ${responseData.keys}');
              apiResponse.error = responseData['message'] ?? 'Erreur serveur';
            }
          } catch (e, stackTrace) {
            print('❌ Erreur lors du décodage JSON: $e');
            print('📚 Stack trace: $stackTrace');
            print('📄 Body: ${response.body}');
            apiResponse.error = 'Erreur de décodage: $e';
          }
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        case 403:
          apiResponse.error = 'Accès refusé';
          break;
        case 404:
          apiResponse.error = 'Endpoint non trouvé';
          break;
        case 500:
          apiResponse.error = 'Erreur serveur interne';
          break;
        default:
          print('❌ Status code inattendu: ${response.statusCode}');
          print('📄 Response body: ${response.body}');
          apiResponse.error = 'Erreur serveur (${response.statusCode})';
          break;
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      apiResponse.error = 'Erreur de connexion';
    }
    return apiResponse;
  }

  // Synchronisation incrémentale
  static Future<ApiResponse> syncVocalises() async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      // L'endpoint /sync n'existe plus, utiliser le même endpoint que getVocalisesFromServer
      final response = await http.get(
        Uri.parse(AppConstance.vocalisesURL),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData['success'] == true) {
            // Vérifier si data existe et n'est pas null
            if (responseData['data'] != null) {
              try {
                // Utiliser l'adaptateur pour convertir les données backend
                List<Vocalise> vocalises = BackendAdapter.backendDataListToVocalises(responseData['data']);

                print('✅ ${vocalises.length} vocalise(s) récupérée(s) avec leurs fichiers organisés par pupitre');

                // Mettre à jour le stockage local
                await saveLocalVocalises(vocalises);

                // Télécharger automatiquement les fichiers audio
                await _downloadAllAudioFiles(vocalises);

                apiResponse.data = vocalises;
                apiResponse.error = null;
              } catch (e) {
                print('❌ Erreur lors du parsing des vocalises: $e');
                apiResponse.error = 'Erreur de parsing: $e';
              }
            } else {
              // Aucune vocalise disponible, mais ce n'est pas une erreur
              print('ℹ️ Aucune vocalise disponible');
              apiResponse.data = [];
              apiResponse.error = null;
            }
          } else {
            print('❌ Erreur backend: ${responseData['message']}');
            print('📋 Structure de réponse: ${responseData.keys}');
            apiResponse.error = responseData['message'] ?? 'Erreur serveur';
          }
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = 'Erreur serveur';
          break;
      }
    } catch (e) {
      apiResponse.error = 'Erreur de connexion';
    }
    return apiResponse;
  }

  // Télécharger un fichier audio
  static Future<bool> downloadAudio(Vocalise vocalise) async {
    try {
      // Vérifier si un fichier audio est disponible (audioPath ou audioFiles)
      bool hasAudio = (vocalise.audioPath != null && vocalise.audioPath!.isNotEmpty) ||
                      (vocalise.audioFiles != null && vocalise.audioFiles!.isNotEmpty);
      
      if (!hasAudio) {
        print('⚠️ Aucun fichier audio disponible pour la vocalise ${vocalise.id}');
        return false;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('${AppConstance.vocalisesURL}/${vocalise.id}/download-audio'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Obtenir le répertoire de documents de l'application
        Directory appDocDir = await getApplicationDocumentsDirectory();
        Directory vocalisesDir = Directory('${appDocDir.path}/vocalises');
        
        // Créer le répertoire s'il n'existe pas
        if (!await vocalisesDir.exists()) {
          await vocalisesDir.create(recursive: true);
        }

        // Créer le fichier local
        String fileName = 'vocalise_${vocalise.id}.mp3';
        File localFile = File('${vocalisesDir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes);

        // Mettre à jour la vocalise avec le chemin local
        List<Vocalise> vocalises = await getLocalVocalises();
        int index = vocalises.indexWhere((v) => v.id == vocalise.id);
        if (index != -1) {
          vocalises[index] = vocalise.copyWith(
            isDownloaded: true,
            localAudioPath: localFile.path,
          );
          await saveLocalVocalises(vocalises);
        }

        // Ajouter à la liste des fichiers téléchargés
        List<String> downloadedAudios = await getDownloadedAudios();
        if (!downloadedAudios.contains(fileName)) {
          downloadedAudios.add(fileName);
          await saveDownloadedAudios(downloadedAudios);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors du téléchargement: $e');
      return false;
    }
  }

  // Créer une nouvelle vocalise
  static Future<ApiResponse> createVocalise({
    required String title,
    String? description,
    required String voicePart,
    required int choraleId,
    String? audioFilePath,
  }) async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      // Préparer les données
      Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'voice_part': voicePart,
        'chorale_id': choraleId,
      };

      // Créer la requête multipart si un fichier audio est fourni
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConstance.vocalisesURL),
      );

      // Ajouter les headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Ajouter les champs
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Ajouter le fichier audio si fourni
      if (audioFilePath != null) {
        var audioFile = await http.MultipartFile.fromPath('audio_file', audioFilePath);
        request.files.add(audioFile);
      }

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      switch (response.statusCode) {
        case 201:
          try {
            var responseData = jsonDecode(response.body);
            if (responseData['success'] == true && responseData['data'] != null) {
              // Utiliser l'adaptateur pour convertir les données backend
              apiResponse.data = BackendAdapter.backendDataToVocalise(responseData['data']);
              apiResponse.error = null;
            } else {
              apiResponse.error = responseData['message'] ?? 'Erreur lors de la création';
            }
          } catch (e) {
            print('❌ Erreur lors du parsing de la réponse: $e');
            apiResponse.error = 'Erreur de parsing: $e';
          }
          break;
        case 422:
          try {
            var responseData = jsonDecode(response.body);
            if (responseData['errors'] != null && responseData['errors'].isNotEmpty) {
              var errors = responseData['errors'];
              apiResponse.error = errors[errors.keys.elementAt(0)][0];
            } else {
              apiResponse.error = responseData['message'] ?? 'Erreur de validation';
            }
          } catch (e) {
            apiResponse.error = 'Erreur de validation';
          }
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          try {
            var responseData = jsonDecode(response.body);
            apiResponse.error = responseData['message'] ?? 'Erreur serveur lors de la création';
          } catch (e) {
            apiResponse.error = 'Erreur serveur lors de la création (${response.statusCode})';
          }
          break;
      }
    } catch (e) {
      apiResponse.error = 'Erreur de connexion lors de la création: $e';
    }
    return apiResponse;
  }

  // Supprimer un fichier audio téléchargé
  static Future<bool> deleteDownloadedAudio(Vocalise vocalise) async {
    try {
      if (vocalise.localAudioPath == null) {
        return false;
      }

      File localFile = File(vocalise.localAudioPath!);
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Mettre à jour la vocalise
      List<Vocalise> vocalises = await getLocalVocalises();
      int index = vocalises.indexWhere((v) => v.id == vocalise.id);
      if (index != -1) {
        vocalises[index] = vocalise.copyWith(
          isDownloaded: false,
          localAudioPath: null,
        );
        await saveLocalVocalises(vocalises);
      }

      // Retirer de la liste des fichiers téléchargés
      List<String> downloadedAudios = await getDownloadedAudios();
      String fileName = 'vocalise_${vocalise.id}.mp3';
      downloadedAudios.remove(fileName);
      await saveDownloadedAudios(downloadedAudios);

      return true;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  // Récupérer les vocalises (local ou serveur selon la connectivité)
  static Future<ApiResponse> getVocalises({bool forceRefresh = false}) async {
    ApiResponse apiResponse = ApiResponse();
    
    try {
      // Vérifier la connectivité
      bool hasInternet = await _checkInternetConnection();
      
      if (hasInternet && forceRefresh) {
        // Forcer la synchronisation depuis le serveur
        return await getVocalisesFromServer();
      } else if (hasInternet) {
        // Synchronisation incrémentale
        return await syncVocalises();
      } else {
        // Mode hors ligne - retourner les données locales
        List<Vocalise> localVocalises = await getLocalVocalises();
        apiResponse.data = localVocalises;
        apiResponse.error = null;
      }
    } catch (e) {
      // En cas d'erreur, retourner les données locales
      List<Vocalise> localVocalises = await getLocalVocalises();
      apiResponse.data = localVocalises;
      apiResponse.error = null;
    }
    
    return apiResponse;
  }

  // Récupérer les vocalises par chorale
  static Future<List<Vocalise>> getVocalisesByChorale(int choraleId) async {
    List<Vocalise> allVocalises = await getLocalVocalises();
    return allVocalises.where((v) => v.choraleId == choraleId).toList();
  }

  // Récupérer les vocalises par partie vocale
  static Future<List<Vocalise>> getVocalisesByVoicePart(String voicePart) async {
    List<Vocalise> allVocalises = await getLocalVocalises();
    return allVocalises.where((v) => v.voicePart == voicePart).toList();
  }

  // Vérifier la connectivité internet
  static Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Nettoyer les fichiers audio téléchargés
  static Future<void> cleanupDownloadedAudios() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      Directory vocalisesDir = Directory('${appDocDir.path}/vocalises');
      
      if (await vocalisesDir.exists()) {
        List<String> downloadedAudios = await getDownloadedAudios();
        List<FileSystemEntity> files = await vocalisesDir.list().toList();
        
        for (FileSystemEntity file in files) {
          if (file is File) {
            String fileName = file.path.split('/').last;
            if (!downloadedAudios.contains(fileName)) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
    }
  }

  // Télécharger automatiquement tous les fichiers audio
  static Future<void> _downloadAllAudioFiles(List<Vocalise> vocalises) async {
    try {
      print('🎵 Téléchargement automatique des fichiers audio...');
      
      for (Vocalise vocalise in vocalises) {
        // Vérifier si un fichier audio est disponible (audioPath ou audioFiles ou fichiers par pupitre)
        bool hasAudio = (vocalise.audioPath != null && vocalise.audioPath!.isNotEmpty) ||
                        (vocalise.audioFiles != null && vocalise.audioFiles!.isNotEmpty) ||
                        (vocalise.sopranoFiles != null && vocalise.sopranoFiles!.isNotEmpty) ||
                        (vocalise.altoFiles != null && vocalise.altoFiles!.isNotEmpty) ||
                        (vocalise.tenorFiles != null && vocalise.tenorFiles!.isNotEmpty) ||
                        (vocalise.basseFiles != null && vocalise.basseFiles!.isNotEmpty) ||
                        (vocalise.tuttiFiles != null && vocalise.tuttiFiles!.isNotEmpty);
        
        if (hasAudio && !vocalise.isDownloaded) {
          print('📥 Téléchargement: ${vocalise.title}');
          await VocaliseService.downloadAudio(vocalise);
        }
      }
      
      print('✅ Téléchargement automatique terminé');
    } catch (e) {
      print('❌ Erreur lors du téléchargement automatique: $e');
    }
  }
}
