import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/services/api_response.dart';

class MesseService {
  static const String _localMessessKey = 'local_messes';
  static const String _pendingMessessKey = 'pending_messes';

  // Récupérer les messes depuis le stockage local
  static Future<List<Messe>> getLocalMessess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? messesJson = prefs.getString(_localMessessKey);
    
    if (messesJson != null) {
      List<dynamic> messesList = jsonDecode(messesJson);
      return messesList.map((json) => Messe.fromJson(json)).toList();
    }
    return [];
  }

  // Sauvegarder les messes localement
  static Future<void> saveLocalMessess(List<Messe> messes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String messesJson = jsonEncode(messes.map((messe) => messe.toJson()).toList());
    await prefs.setString(_localMessessKey, messesJson);
  }

  // Récupérer les messes en attente de synchronisation
  static Future<List<Map<String, dynamic>>> getPendingMessess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? pendingJson = prefs.getString(_pendingMessessKey);
    
    if (pendingJson != null) {
      List<dynamic> pendingList = jsonDecode(pendingJson);
      return pendingList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Sauvegarder une messe en attente de synchronisation
  static Future<void> savePendingMesse(Map<String, dynamic> messeData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> pendingMessess = await getPendingMessess();
    pendingMessess.add(messeData);
    
    String pendingJson = jsonEncode(pendingMessess);
    await prefs.setString(_pendingMessessKey, pendingJson);
  }

  // Créer une messe (stockage local + mise en attente de synchronisation)
  static Future<ApiResponse> createMesse({
    required String title,
    required String description,
    required String date,
    required String voicePart,
    required List<Map<String, dynamic>> sections,
  }) async {
    ApiResponse apiResponse = ApiResponse();
    
    try {
      // Créer l'objet Messe
      Messe newMesse = Messe(
        id: DateTime.now().millisecondsSinceEpoch, // ID temporaire
        title: title,
        description: description,
        date: date,
        voicePart: voicePart,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        sections: sections.map((sectionData) => MesseSection(
          id: DateTime.now().millisecondsSinceEpoch + sections.indexOf(sectionData),
          name: sectionData['name'],
          writtenPartition: sectionData['written_partition'],
          musicalPartition: sectionData['musical_partition'],
          audioFile: sectionData['audio_file'],
          voicePart: voicePart,
          messeId: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        )).toList(),
      );

      // Sauvegarder localement
      List<Messe> localMessess = await getLocalMessess();
      localMessess.add(newMesse);
      await saveLocalMessess(localMessess);

      // Mettre en attente de synchronisation
      await savePendingMesse({
        'action': 'create',
        'data': newMesse.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      apiResponse.data = newMesse;
      apiResponse.error = null;
      
    } catch (e) {
      apiResponse.error = 'Erreur lors de la sauvegarde locale: $e';
    }
    
    return apiResponse;
  }

  // Synchroniser les messes en attente avec le serveur
  static Future<void> syncMessess() async {
    try {
      List<Map<String, dynamic>> pendingMessess = await getPendingMessess();
      
      if (pendingMessess.isEmpty) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) return;

      for (Map<String, dynamic> pendingMesse in pendingMessess) {
        if (pendingMesse['action'] == 'create') {
          await _syncCreateMesse(pendingMesse['data'], token);
        }
      }

      // Vider la liste des messes en attente après synchronisation réussie
      await prefs.remove(_pendingMessessKey);
      
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }

  // Synchroniser la création d'une messe
  static Future<void> _syncCreateMesse(Map<String, dynamic> messeData, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstance.baseURL}/api/messes'),
      );

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = messeData['title'];
      request.fields['description'] = messeData['description'];
      request.fields['date'] = messeData['date'];
      request.fields['voice_part'] = messeData['voice_part'];
      request.fields['sections'] = jsonEncode(messeData['sections']);

      final response = await request.send();
      
      if (response.statusCode == 201) {
        print('Messe synchronisée avec succès');
      } else {
        print('Erreur lors de la synchronisation: ${response.statusCode}');
      }
      
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }

  // Récupérer les messes depuis le serveur (pour la synchronisation)
  static Future<ApiResponse> getMessessFromServer() async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }
      
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/messes'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          List<dynamic> serverMessess = jsonDecode(response.body)['data'];
          List<Messe> messes = serverMessess.map((p) => Messe.fromJson(p)).toList();
          
          // Mettre à jour le stockage local
          await saveLocalMessess(messes);
          
          apiResponse.data = messes;
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

  // Méthodes existantes pour compatibilité
  static Future<ApiResponse> getMessess() async {
    // Retourner les messes locales
    List<Messe> localMessess = await getLocalMessess();
    ApiResponse apiResponse = ApiResponse();
    apiResponse.data = localMessess;
    apiResponse.error = null;
    return apiResponse;
  }

  static Future<ApiResponse> getMesseById(int id) async {
    List<Messe> localMessess = await getLocalMessess();
    Messe? messe = localMessess.firstWhere((m) => m.id == id);
    
    ApiResponse apiResponse = ApiResponse();
    if (messe != null) {
      apiResponse.data = messe;
      apiResponse.error = null;
    } else {
      apiResponse.error = 'Messe non trouvée';
    }
    return apiResponse;
  }

  static Future<ApiResponse> updateMesse({
    required int id,
    String? title,
    String? description,
    String? date,
    String? voicePart,
    String? writtenPartition,
    File? musicalPartition,
    File? audioFile,
  }) async {
    // Implémentation locale pour l'instant
    ApiResponse apiResponse = ApiResponse();
    apiResponse.error = 'Fonctionnalité non implémentée en mode hors ligne';
    return apiResponse;
  }

  static Future<ApiResponse> deleteMesse(int id) async {
    // Implémentation locale pour l'instant
    ApiResponse apiResponse = ApiResponse();
    apiResponse.error = 'Fonctionnalité non implémentée en mode hors ligne';
    return apiResponse;
  }
} 