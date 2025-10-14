import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/services/api_response.dart';

class VocaliseService {
  static const String _localVocalisesKey = 'local_vocalises';
  static const String _lastSyncKey = 'vocalises_last_sync';
  static const String _downloadedAudiosKey = 'downloaded_audios';

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
      
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/vocalises'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          List<dynamic> serverVocalises = jsonDecode(response.body)['data'];
          List<Vocalise> vocalises = serverVocalises.map((v) => Vocalise.fromJson(v)).toList();
          
          // Mettre à jour le stockage local
          await saveLocalVocalises(vocalises);
          
          apiResponse.data = vocalises;
          apiResponse.error = null;
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

      String lastSync = await getLastSync();
      
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/vocalises/sync?last_sync=$lastSync'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          Map<String, dynamic> responseData = jsonDecode(response.body);
          List<dynamic> newVocalises = responseData['data'];
          String newLastSync = responseData['last_sync'];
          
          if (newVocalises.isNotEmpty) {
            List<Vocalise> vocalises = newVocalises.map((v) => Vocalise.fromJson(v)).toList();
            
            // Fusionner avec les vocalises existantes
            List<Vocalise> existingVocalises = await getLocalVocalises();
            Map<int, Vocalise> vocaliseMap = {
              for (var v in existingVocalises) v.id: v
            };
            
            // Mettre à jour ou ajouter les nouvelles vocalises
            for (var vocalise in vocalises) {
              vocaliseMap[vocalise.id] = vocalise;
            }
            
            await saveLocalVocalises(vocaliseMap.values.toList());
          }
          
          await saveLastSync(newLastSync);
          
          apiResponse.data = await getLocalVocalises();
          apiResponse.error = null;
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
      if (vocalise.audioUrl == null || vocalise.audioUrl!.isEmpty) {
        return false;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/vocalises/${vocalise.id}/download-audio'),
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
}
