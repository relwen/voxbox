import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/chorale.dart';
import 'package:voxbox/services/api_response.dart';

class ChoraleService {
  static String get _baseUrl => AppConstance.baseURL;

  /// Récupère toutes les chorales depuis le serveur
  static Future<ApiResponse<List<Chorale>>> getChorales() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chorales'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          List<Chorale> chorales = (data['data'] as List)
              .map((json) => Chorale.fromJson(json))
              .toList();
          
          return ApiResponse<List<Chorale>>(data: chorales);
        } else {
          return ApiResponse<List<Chorale>>(error: data['message'] ?? 'Erreur lors du chargement des chorales');
        }
      } else {
        return ApiResponse<List<Chorale>>(error: 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<List<Chorale>>(error: 'Erreur de connexion: $e');
    }
  }

  /// Recherche des chorales par nom
  static Future<ApiResponse<List<Chorale>>> searchChorales(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chorales/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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

  /// Données de test pour le développement
  static List<Chorale> getTestChorales() {
    return [
      Chorale(
        id: 1,
        nom: 'Chorale Saint Gabriel',
        description: 'Chorale paroissiale de Saint Gabriel',
        ville: 'Ouagadougou',
        pays: 'Burkina Faso',
        active: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      Chorale(
        id: 2,
        nom: 'Chorale de la Sympathie',
        description: 'Chorale communautaire de la Sympathie',
        ville: 'Bobo-Dioulasso',
        pays: 'Burkina Faso',
        active: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      Chorale(
        id: 3,
        nom: 'Chorale de l\'Espoir',
        description: 'Chorale de l\'église de l\'Espoir',
        ville: 'Koudougou',
        pays: 'Burkina Faso',
        active: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      Chorale(
        id: 4,
        nom: 'Chorale Notre-Dame',
        description: 'Chorale de la cathédrale Notre-Dame',
        ville: 'Ouagadougou',
        pays: 'Burkina Faso',
        active: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      Chorale(
        id: 5,
        nom: 'Chorale Sainte Thérèse',
        description: 'Chorale de la paroisse Sainte Thérèse',
        ville: 'Fada N\'Gourma',
        pays: 'Burkina Faso',
        active: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      Chorale(
        id: 6,
        nom: 'Chorale Saint Joseph',
        description: 'Chorale de l\'église Saint Joseph',
        ville: 'Banfora',
        pays: 'Burkina Faso',
        active: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
