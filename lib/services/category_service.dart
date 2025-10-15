import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/category.dart';
import 'package:voxbox/services/api_response.dart';

class CategoryService {
  static const String _localCategoriesKey = 'local_categories';

  // Récupérer les catégories depuis le stockage local
  static Future<List<Category>> getLocalCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? categoriesJson = prefs.getString(_localCategoriesKey);

    if (categoriesJson != null) {
      List<dynamic> categoriesList = jsonDecode(categoriesJson);
      return categoriesList.map((json) => Category.fromJson(json)).toList();
    }
    return [];
  }

  // Sauvegarder les catégories localement
  static Future<void> saveLocalCategories(List<Category> categories) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String categoriesJson = jsonEncode(categories.map((category) => category.toJson()).toList());
    await prefs.setString(_localCategoriesKey, categoriesJson);
  }

  // Récupérer les catégories depuis le serveur
  static Future<ApiResponse> getCategoriesFromServer() async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      final response = await http.get(
        Uri.parse(AppConstance.categoriesURL),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          List<dynamic> serverCategories = jsonDecode(response.body)['data'];
          List<Category> categories = serverCategories.map((c) => Category.fromJson(c)).toList();
          
          apiResponse.data = categories;
          apiResponse.error = null;
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = 'Erreur serveur lors de la récupération des catégories';
          break;
      }
    } catch (e) {
      apiResponse.error = 'Erreur de connexion lors de la récupération des catégories: $e';
    }
    return apiResponse;
  }

  // Récupérer les catégories (avec option de rafraîchissement forcé)
  static Future<ApiResponse> getCategories({bool forceRefresh = false}) async {
    ApiResponse apiResponse = ApiResponse();
    List<Category> localCategories = await getLocalCategories();

    if (localCategories.isNotEmpty && !forceRefresh) {
      apiResponse.data = localCategories;
      apiResponse.error = null;
      return apiResponse;
    }

    // Tenter de récupérer depuis le serveur
    try {
      var serverResponse = await getCategoriesFromServer();
      if (serverResponse.error == null) {
        List<Category> categories = serverResponse.data as List<Category>;
        await saveLocalCategories(categories);
        apiResponse.data = categories;
        apiResponse.error = null;
      } else {
        // Si la récupération échoue, retourner les données locales si disponibles
        if (localCategories.isNotEmpty) {
          apiResponse.data = localCategories;
          apiResponse.error = serverResponse.error; // Indiquer l'erreur de sync
        } else {
          apiResponse.error = serverResponse.error;
        }
      }
    } catch (e) {
      // En cas d'erreur de connexion, retourner les données locales
      if (localCategories.isNotEmpty) {
        apiResponse.data = localCategories;
        apiResponse.error = 'Erreur de connexion, affichage des données locales.';
      } else {
        apiResponse.error = 'Erreur de connexion: $e';
      }
    }
    return apiResponse;
  }

  // Créer une nouvelle catégorie
  static Future<ApiResponse> createCategory({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    ApiResponse apiResponse = ApiResponse();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        apiResponse.error = 'Token non disponible';
        return apiResponse;
      }

      Map<String, dynamic> data = {
        'name': name,
        'description': description,
        'color': color,
        'icon': icon,
      };

      final response = await http.post(
        Uri.parse(AppConstance.categoriesURL),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      switch (response.statusCode) {
        case 201:
          var responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            apiResponse.data = Category.fromJson(responseData['data']);
            apiResponse.error = null;
          } else {
            apiResponse.error = responseData['message'] ?? 'Erreur lors de la création';
          }
          break;
        case 422:
          var errors = jsonDecode(response.body)['errors'];
          apiResponse.error = errors[errors.keys.elementAt(0)][0];
          break;
        case 401:
          apiResponse.error = 'Non autorisé';
          break;
        default:
          apiResponse.error = 'Erreur serveur lors de la création';
          break;
      }
    } catch (e) {
      apiResponse.error = 'Erreur de connexion lors de la création: $e';
    }
    return apiResponse;
  }
}
