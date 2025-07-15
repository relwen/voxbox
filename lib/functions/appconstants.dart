import 'package:flutter/material.dart';

class AppConstance {
  static Color primary = Color.fromARGB(255, 2, 101, 158);
  static Color priGradient = Color.fromARGB(255, 78, 13, 4);
  static Color secondary = Color.fromARGB(255, 179, 5, 5);

// #18915A
// Color(0xff18915A)

/////////////////////////////
  ///  App URL - Mise à jour pour votre backend local
//

  // Changez cette URL selon votre configuration
  // static String baseURL = 'http://10.0.2.2:8000'; // Pour émulateur Android
  // static String baseURL = 'http://localhost:8000'; // Pour iOS Simulator
  static String baseURL = 'http://192.168.1.100:8000'; // Pour appareil physique
  
  static String appName = 'Voxy Box';
  
  // Nouveaux endpoints pour votre backend Laravel
  static String loginURL = '$baseURL/api/login';
  static String registerURL = '$baseURL/api/register';
  static String logoutURL = '$baseURL/api/logout';
  static String meURL = '$baseURL/api/me';
  static String choralesURL = '$baseURL/api/chorales';
  
  // Endpoints pour les partitions et voix
  static String partitionsURL = '$baseURL/api/partitions';
  static String voicePartsURL = '$baseURL/api/voice-parts';
  
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
