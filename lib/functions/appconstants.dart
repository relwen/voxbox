import 'package:flutter/material.dart';

class AppConstance {
  // Nouvelle palette de couleurs harmonieuse et moderne

  static Color primary = Color.fromARGB(255, 158, 2, 80);
  static Color priGradient = Color.fromARGB(255, 78, 13, 4);
  static Color secondary = Color.fromARGB(255, 179, 5, 5);

  // static Color primary = const Color(0xFF667eea); // Bleu doux moderne
  // static Color priGradient = const Color(0xFF764ba2); // Violet doux
  // static Color secondary = const Color(0xFFf093fb); // Rose doux

  // Couleurs d'accent pour une meilleure UX
  static Color accent = const Color(0xFF4facfe); // Bleu ciel
  static Color success = const Color(0xFF00b894); // Vert moderne
  static Color warning = const Color(0xFFfdcb6e); // Orange doux
  static Color error = const Color(0xFFe17055); // Rouge doux

// #18915A
// Color(0xff18915A)

/////////////////////////////
  ///  App URL - Mise à jour pour votre backend local
//

  // Changez cette URL selon votre configuration
  // static String baseURL = 'http://10.0.2.2:8000'; // Pour émulateur Android
  // static String baseURL = 'http://localhost:8000'; // Pour iOS Simulator
  // static String baseURL = 'http://192.168.11.107:8000'; // ← IP locale WiFi pour backend localhost:8000
  static String baseURL =
      'https://voxychoir.site'; // ← IP locale WiFi pour backend localhost:8000

  static String appName = 'VoXY';

  // Nouveaux endpoints pour votre backend Laravel

  static String loginURL = '$baseURL/api/login';
  static String registerURL = '$baseURL/api/register';
  static String logoutURL = '$baseURL/api/logout';
  static String meURL = '$baseURL/api/me';
  static String partitionsURL = '$baseURL/api/partitions';
  static String voicePartsURL = '$baseURL/api/voice-parts';

  // Endpoints pour les vocalises (utilise vocalises-sections qui retourne les partitions)
  static String vocalisesURL = '$baseURL/api/vocalises-sections';

  // Endpoints pour les catégories
  static String categoriesURL = '$baseURL/api/categories';

  // Endpoints pour les messes
  static String messesURL = '$baseURL/api/messes';
  static String messeSectionsURL = '$baseURL/api/messe-sections';
  static String chantsDeMesseURL = '$baseURL/api/chants-de-messe';

  // Endpoints pour l'authentification OTP
  static String requestOTPURL = '$baseURL/api/request-otp';
  static String verifyOTPURL = '$baseURL/api/verify-otp';
  static String checkPhoneURL = '$baseURL/api/check-phone';

  // Token sera géré dynamiquement après connexion
  static String? token;

  // Anciens endpoints (à supprimer progressivement)
  static String getlocality = '$baseURL/api/getLocality';
  static String saveWomanMobile = '$baseURL/api/saveWomanMobile';
  static String saveOscMobile = '$baseURL/api/saveOscMobile';
}

class AppImages {
  static String logo = "assets/images/logo.png";
}

class StringsUtils {
//Errors
  static String serverError = 'Server error';
  static String unauthorized = 'Non autorisé';
  static String somethingwentwrong = 'Une erreur est survenue';

  static int countRefresh = 100000;
}
