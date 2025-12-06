import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/api_response.dart';

// Service d'inscription pour Laravel
Future<ApiResponse> registerWithLaravel({
  required String name,
  required String email,
  required String password,
  required String passwordConfirmation,
  required int choraleId,
  required String voicePart,
  String? phone,
}) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    print('🔄 Tentative d\'inscription...');
    print('👤 Nom: $name');
    print('📧 Email: $email');
    print('🎵 Chorale ID: $choraleId');
    print('🎤 Pupitre: $voicePart');
    print('🌐 URL: ${AppConstance.registerURL}');
    
    final response = await http.post(
      Uri.parse(AppConstance.registerURL),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'chorale_id': choraleId,
        'voice_part': voicePart,
        'phone': phone,
      }),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    switch (response.statusCode) {
      case 201:
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // L'inscription est réussie mais le compte est en attente d'approbation
          // Pas de token généré pour les comptes en attente
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isConnected', false); // Pas encore connecté
          await prefs.setString('pending_user', jsonEncode(responseData['user']));
          apiResponse.data = User.fromJson(responseData['user']);
        } else {
          apiResponse.error = responseData['message'];
        }
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 400:
        apiResponse.error = jsonDecode(response.body)['message'];
    
        break;
      default:
        apiResponse.error = "Erreur serveur (${response.statusCode})";
        
    }
  } catch (e) {
    apiResponse.error = "Erreur de connexion: $e";
    print('💥 Exception: $e');
  }

  return apiResponse;
}

// Demander un code OTP pour un numéro de téléphone
Future<ApiResponse> requestOTP(String phoneNumber) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    print('🔄 Demande d\'OTP pour: $phoneNumber');
    print('🌐 URL: ${AppConstance.requestOTPURL}');

    final response = await http.post(
      Uri.parse(AppConstance.requestOTPURL),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phoneNumber,
      }),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        print('✅ OTP envoyé avec succès');
        if (responseData['success'] == true) {
          apiResponse.data = responseData; // Contient phone et otp (en mode debug)
          print('📱 OTP envoyé au numéro: ${responseData['phone']}');
          // En mode développement, l'OTP peut être dans responseData['otp']
          if (responseData.containsKey('otp')) {
            print('🔑 Code OTP (DEBUG): ${responseData['otp']}');
          }
        } else {
          apiResponse.error = responseData['message'];
          print('❌ Erreur: ${responseData['message']}');
        }
        break;
      case 404:
        apiResponse.error = 'Numéro de téléphone non trouvé';
        print('❌ Erreur 404: Numéro non trouvé');
        break;
      case 403:
        final responseData = jsonDecode(response.body);
        apiResponse.error = responseData['message'] ?? 'Compte non autorisé';
        print('❌ Erreur 403: ${apiResponse.error}');
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        print('❌ Erreur 422: ${apiResponse.error}');
        break;
      case 500:
        final responseData = jsonDecode(response.body);
        apiResponse.error = responseData['message'] ?? 'Erreur lors de l\'envoi du SMS';
        print('❌ Erreur 500: ${apiResponse.error}');
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

// Vérifier le code OTP et se connecter
Future<ApiResponse> verifyOTP(String phoneNumber, String otp) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    print('🔄 Vérification OTP pour: $phoneNumber');
    print('🔑 Code OTP: $otp');
    print('🌐 URL: ${AppConstance.verifyOTPURL}');

    final response = await http.post(
      Uri.parse(AppConstance.verifyOTPURL),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phoneNumber,
        'otp': otp,
      }),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        print('✅ Réponse 200 reçue');
        if (responseData['success'] == true) {
          // Sauvegarder le token dans SharedPreferences
          AppConstance.token = responseData['token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          await prefs.setBool('isConnected', true);

          // Créer l'utilisateur avec les données complètes incluant profile_incomplete
          User user = User.fromJson(responseData['user']);
          user.profileComplete = responseData['profile_complete'] ?? false;
          user.profileIncomplete = responseData['profile_incomplete'] ?? true;
          
          // Sauvegarder l'utilisateur
          await prefs.setString('user', jsonEncode(user.toJson()));

          // Sauvegarder chorale_id séparément pour un accès facile
          if (user.choraleId != null) {
            await prefs.setInt('chorale_id', user.choraleId!);
            print('💾 Chorale ID sauvegardé: ${user.choraleId}');
          }

          // Sauvegarder le nom de la chorale si disponible
          if (user.chorale != null && user.chorale!['name'] != null) {
            await prefs.setString('chorale_name', user.chorale!['name'].toString());
            print('💾 Nom de la chorale sauvegardé: ${user.chorale!['name']}');
          }

          // Retourner l'utilisateur
          apiResponse.data = user;
          print('🎉 Connexion réussie via OTP!');
          print('🔑 Token: ${responseData['token']}');
          print('📋 Profil complet: ${user.profileComplete}');
          print('📋 Profil incomplet: ${user.profileIncomplete}');
        } else {
          apiResponse.error = responseData['message'];
          print('❌ Erreur: ${responseData['message']}');
        }
        break;
      case 400:
        final responseData = jsonDecode(response.body);
        apiResponse.error = responseData['message'] ?? 'Code OTP incorrect ou expiré';
        print('❌ Erreur 400: ${apiResponse.error}');
        break;
      case 429:
        apiResponse.error = 'Trop de tentatives. Veuillez demander un nouveau code.';
        print('❌ Erreur 429: Trop de tentatives');
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        print('❌ Erreur 422: ${apiResponse.error}');
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

// Vérifier si un numéro de téléphone existe en base de données
Future<ApiResponse> checkPhoneExists(String phoneNumber) async {
  ApiResponse apiResponse = ApiResponse();

  try {


    final response = await http.post(
      Uri.parse(AppConstance.checkPhoneURL),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phoneNumber,
      }),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        print('✅ Réponse 200 reçue');
        if (responseData['success'] == true) {
          apiResponse.data = responseData['exists']; // true si existe, false sinon
          print('📱 Numéro existe: ${responseData['exists']}');
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
      case 400:
        apiResponse.error = jsonDecode(response.body)['message'];
        print('❌ Erreur 400: ${apiResponse.error}');
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

// Connexion par numéro de téléphone (sans mot de passe)
Future<ApiResponse> loginByPhone(String phoneNumber) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    print('🔄 Connexion par numéro de téléphone: $phoneNumber');
    print('🌐 URL: ${AppConstance.baseURL}/api/login-by-phone');
    
    final response = await http.post(
      Uri.parse('${AppConstance.baseURL}/api/login-by-phone'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phoneNumber,
      }),
    );

    print('📡 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        print('✅ Réponse 200 reçue');
        if (responseData['success'] == true) {
          // Sauvegarder le token dans SharedPreferences
          AppConstance.token = responseData['token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          
          // Créer l'utilisateur
          User user = User.fromJson(responseData['user']);
          
          // Sauvegarder l'utilisateur
          await prefs.setString('user', jsonEncode(user.toJson()));

          // Sauvegarder chorale_id séparément pour un accès facile
          if (user.choraleId != null) {
            await prefs.setInt('chorale_id', user.choraleId!);
            print('💾 Chorale ID sauvegardé: ${user.choraleId}');
          }

          // Sauvegarder le nom de la chorale si disponible
          if (user.chorale != null && user.chorale!['name'] != null) {
            await prefs.setString('chorale_name', user.chorale!['name'].toString());
            print('💾 Nom de la chorale sauvegardé: ${user.chorale!['name']}');
          }
          
          apiResponse.data = user;
          print('🎉 Connexion par téléphone réussie!');
        } else {
          apiResponse.error = responseData['message'];
          print('❌ Erreur: ${responseData['message']}');
        }
        break;
      case 404:
        apiResponse.error = 'Numéro de téléphone non trouvé';
        print('❌ Erreur 404: Numéro non trouvé');
        break;
      case 403:
        apiResponse.error = 'Votre compte est en attente d\'approbation';
        print('❌ Erreur 403: Compte en attente');
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        print('❌ Erreur 422: ${apiResponse.error}');
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
          // Sauvegarder le token dans SharedPreferences
          AppConstance.token = responseData['token'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
          await prefs.setBool('isConnected', true);
          
          // Créer l'utilisateur avec les données complètes
          User user = User.fromJson(responseData['user']);
          user.profileComplete = responseData['profile_complete'] ?? false;
          user.profileIncomplete = responseData['profile_incomplete'] ?? true;
          
          // Sauvegarder l'utilisateur
          await prefs.setString('user', jsonEncode(user.toJson()));

          // Sauvegarder chorale_id séparément pour un accès facile
          if (user.choraleId != null) {
            await prefs.setInt('chorale_id', user.choraleId!);
            print('💾 Chorale ID sauvegardé: ${user.choraleId}');
          }

          // Sauvegarder le nom de la chorale si disponible
          if (user.chorale != null && user.chorale!['name'] != null) {
            await prefs.setString('chorale_name', user.chorale!['name'].toString());
            print('💾 Nom de la chorale sauvegardé: ${user.chorale!['name']}');
          }
          
          apiResponse.data = user;
          print('🎉 Connexion réussie!');
          print('📋 Profil complet: ${user.profileComplete}');
          print('📋 Profil incomplet: ${user.profileIncomplete}');
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
    // Récupérer le token depuis SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token == null) {
      apiResponse.error = 'Token non disponible';
      return apiResponse;
    }

    final response = await http.get(
      Uri.parse(AppConstance.meURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          User user = User.fromJson(responseData['user']);
          user.profileComplete = responseData['profile_complete'] ?? false;
          user.profileIncomplete = responseData['profile_incomplete'] ?? true;
          
          // Sauvegarder l'utilisateur mis à jour
          await prefs.setString('user', jsonEncode(user.toJson()));

          // Sauvegarder chorale_id séparément pour un accès facile
          if (user.choraleId != null) {
            await prefs.setInt('chorale_id', user.choraleId!);
            print('💾 Chorale ID sauvegardé: ${user.choraleId}');
          }

          // Sauvegarder le nom de la chorale si disponible
          if (user.chorale != null && user.chorale!['name'] != null) {
            await prefs.setString('chorale_name', user.chorale!['name'].toString());
            print('💾 Nom de la chorale sauvegardé: ${user.chorale!['name']}');
          }
          
          apiResponse.data = user;
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
    // Récupérer le token depuis SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token == null) {
      apiResponse.error = 'Token non disponible';
      return apiResponse;
    }

    final response = await http.post(
      Uri.parse(AppConstance.logoutURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Supprimer le token
      AppConstance.token = null;
      await prefs.remove('token');
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
