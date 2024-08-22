import 'package:flutter/material.dart';

class AppConstance {
  static Color primary = Color.fromARGB(255, 2, 101, 158);
  static Color priGradient = Color.fromARGB(255, 78, 13, 4);
  static Color secondary = Color.fromARGB(255, 179, 5, 5);

// #18915A
// Color(0xff18915A)

/////////////////////////////
  ///  App URL
//

  static String baseURL = 'http://compendium-mali.ml';
  static String appName = 'Voxy CCB';
  static String loginURL = '$baseURL/api/checkLoginCollector';

  static String token =
      "85RPObzQW6xFBJzgIyMLqoLFQ1Vg8fPWCkPo1m6B4ylVDVkorGaHgW9EVM9mYTi4";
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
