import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/chorale.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/services/api_response.dart';

class ChoraleService {
  static String get _baseUrl => AppConstance.baseURL;
  static const String _pupitresKeyPrefix = 'cached_pupitres_';

  /// Récupère toutes les chorales depuis le serveur
  /// L'API des chorales est accessible sans authentification
  static Future<ApiResponse<List<Chorale>>> getChorales() async {
    try {
      // Récupérer le token d'authentification (optionnel)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Ajouter le token d'authentification si disponible (optionnel)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('🔐 Token d\'authentification ajouté aux headers');
      } else {
        print('🌐 Accès public aux chorales (sans authentification)');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chorales'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📡 Réponse API chorales: ${response.body}');
        
        if (data['success'] == true && data['data'] != null) {
          List<Chorale> chorales = (data['data'] as List)
              .map((json) {
                print('🔄 Conversion chorale: $json');
                return Chorale.fromJson(json);
              })
              .toList();
          
          print('✅ Chorales converties: ${chorales.length} chorales');
          for (var chorale in chorales) {
            print('   - ${chorale.nom} (${chorale.ville})');
          }
          
          return ApiResponse<List<Chorale>>(data: chorales);
        } else {
          print('❌ Erreur dans la réponse API: ${data['message']}');
          return ApiResponse<List<Chorale>>(error: data['message'] ?? 'Erreur lors du chargement des chorales');
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode} - ${response.body}');
        return ApiResponse<List<Chorale>>(error: 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<List<Chorale>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Recherche des chorales par nom
  /// L'API de recherche est accessible sans authentification
  static Future<ApiResponse<List<Chorale>>> searchChorales(String query) async {
    try {
      // Récupérer le token d'authentification (optionnel)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Ajouter le token d'authentification si disponible (optionnel)
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('🔐 Token d\'authentification ajouté pour la recherche');
      } else {
        print('🌐 Recherche publique des chorales (sans authentification)');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chorales/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          List<Chorale> chorales = (data['data'] as List)
              .map((json) => Chorale.fromJson(json))
              .toList();
          
          return ApiResponse<List<Chorale>>(data: chorales);
        } else {
          return ApiResponse<List<Chorale>>(error: data['message'] ?? 'Erreur lors de la recherche');
        }
      } else {
        return ApiResponse<List<Chorale>>(error: 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<List<Chorale>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Crée une nouvelle chorale
  static Future<ApiResponse<Chorale>> createChorale({
    required String nom,
    String? description,
    String? ville,
    String? pays,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chorales'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nom': nom,
          'description': description,
          'ville': ville,
          'pays': pays,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          Chorale chorale = Chorale.fromJson(data['data']);
          return ApiResponse<Chorale>(data: chorale);
        } else {
          return ApiResponse<Chorale>(error: data['message'] ?? 'Erreur lors de la création');
        }
      } else {
        return ApiResponse<Chorale>(error: 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<Chorale>(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupère les pupitres d'une chorale
  static Future<ApiResponse<List<ChoralePupitre>>> getPupitres(int choraleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Tenter de charger depuis le serveur
      try {
        Map<String, String> headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        
        String? token = prefs.getString('token');
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        
        final response = await http.get(
          Uri.parse('$_baseUrl/api/chorales/$choraleId/pupitres'),
          headers: headers,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          
          if (data['success'] == true && data['data'] != null) {
            List<ChoralePupitre> pupitres = (data['data'] as List)
                .map((json) => ChoralePupitre.fromJson(json))
                .toList();
            
            // Trier par ordre
            pupitres.sort((a, b) => a.order.compareTo(b.order));
            
            // Sauvegarder dans le cache
            await prefs.setString('$_pupitresKeyPrefix$choraleId', json.encode(data['data']));
            
            return ApiResponse<List<ChoralePupitre>>(data: pupitres);
          }
        }
      } catch (e) {
        print('📡 ChoraleService - Erreur réseau ou timeout, utilisation du cache: $e');
      }

      // Si échec réseau, charger depuis le cache
      final cachedPupitresJson = prefs.getString('$_pupitresKeyPrefix$choraleId');
      if (cachedPupitresJson != null) {
        final List<dynamic> decoded = json.decode(cachedPupitresJson);
        List<ChoralePupitre> pupitres = decoded
            .map((json) => ChoralePupitre.fromJson(json))
            .toList();
        pupitres.sort((a, b) => a.order.compareTo(b.order));
        return ApiResponse<List<ChoralePupitre>>(data: pupitres);
      }

      return ApiResponse<List<ChoralePupitre>>(error: 'Impossible de charger les pupitres et aucun cache disponible');
    } catch (e) {
      return ApiResponse<List<ChoralePupitre>>(error: 'Erreur: $e');
    }
  }

}
