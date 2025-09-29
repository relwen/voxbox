import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/api_response.dart';

// Nouveau service d'authentification pour Laravel
Future<ApiResponse> loginWithLaravel(String email, String password) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    print('🔄 Tentative de connexion...');
    print('📧 Email: $email');
    print('🌐 URL: ${AppConstance.loginURL}');
    
    final response = await http.post(
      Uri.parse(AppConstance.loginURL),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        print('✅ Réponse 200 reçue');
        if (responseData['success'] == true) {
          // Sauvegarder le token
          AppConstance.token = responseData['token'];
          apiResponse.data = User.fromJson(responseData['user']);
          print('🎉 Connexion réussie!');
        } else {
          apiResponse.error = responseData['message'];
          print('❌ Erreur: ${responseData['message']}');
        }
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        print('❌ Erreur 422: ${apiResponse.error}');
        break;
      case 401:
        apiResponse.error = jsonDecode(response.body)['message'];
        print('❌ Erreur 401: ${apiResponse.error}');
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        print('❌ Erreur 403: ${apiResponse.error}');
        break;
      default:
        apiResponse.error = "Erreur serveur (${response.statusCode})";
        print('❌ Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    apiResponse.error = "Erreur de connexion: $e";
    print('💥 Exception: $e');
  }

  return apiResponse;
}

// Service pour récupérer les informations utilisateur
Future<ApiResponse> getUserInfo() async {
  ApiResponse apiResponse = ApiResponse();

  try {
    final response = await http.get(
      Uri.parse(AppConstance.meURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${AppConstance.token}',
      },
    );

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          apiResponse.data = User.fromJson(responseData['user']);
        } else {
          apiResponse.error = responseData['message'];
        }
        break;
      case 401:
        apiResponse.error = "Non autorisé";
        break;
      default:
        apiResponse.error = "Erreur serveur";
    }
  } catch (e) {
    apiResponse.error = "Erreur de connexion";
  }

  return apiResponse;
}

// Service pour la déconnexion
Future<ApiResponse> logout() async {
  ApiResponse apiResponse = ApiResponse();

  try {
    final response = await http.post(
      Uri.parse(AppConstance.logoutURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${AppConstance.token}',
      },
    );

    if (response.statusCode == 200) {
      AppConstance.token = null;
      apiResponse.data = "Déconnexion réussie";
    } else {
      apiResponse.error = "Erreur lors de la déconnexion";
    }
  } catch (e) {
    apiResponse.error = "Erreur de connexion";
  }

  return apiResponse;
}

// Ancien service (garder pour compatibilité)
Future<ApiResponse> login(String phone, String password) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    final response =
        await http.post(Uri.parse(AppConstance.loginURL), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${AppConstance.token}',
    }, body: {
      'phone': phone,
      'password': password
    });

    switch (response.statusCode) {
      case 200:
        apiResponse.data = Collector.fromJson(jsonDecode(response.body));
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        apiResponse.error = null;
    }
  } catch (e) {
    apiResponse.error = "serverError";
  }

  return apiResponse;
}
