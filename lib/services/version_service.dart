import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/services/api_response.dart';

class VersionInfo {
  final String currentVersion;
  final String latestVersion;
  final String minimumVersion;
  final bool updateAvailable;
  final bool updateRequired;
  final bool forceUpdate;
  final String downloadUrl;
  final String platform;
  final String message;

  VersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateAvailable,
    required this.updateRequired,
    required this.forceUpdate,
    required this.downloadUrl,
    required this.platform,
    required this.message,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      currentVersion: json['current_version'] ?? '1.0.0',
      latestVersion: json['latest_version'] ?? '1.0.0',
      minimumVersion: json['minimum_version'] ?? '1.0.0',
      updateAvailable: json['update_available'] ?? false,
      updateRequired: json['update_required'] ?? false,
      forceUpdate: json['force_update'] ?? false,
      downloadUrl: json['download_url'] ?? '',
      platform: json['platform'] ?? 'android',
      message: json['message'] ?? '',
    );
  }
}

class VersionService {
  /// Vérifier si une mise à jour est disponible
  static Future<ApiResponse<VersionInfo>> checkForUpdate() async {
    ApiResponse<VersionInfo> apiResponse = ApiResponse();

    try {
      // Récupérer les informations du package
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      // Déterminer la plateforme
      final String platform = Platform.isIOS ? 'ios' : 'android';

      debugPrint('🔍 Vérification de mise à jour...');
      debugPrint('   Plateforme: $platform');
      debugPrint('   Version actuelle: $currentVersion');

      // Appeler l'API
      final response = await http.post(
        Uri.parse('${AppConstance.baseURL}/api/check-update'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'platform': platform,
          'version': currentVersion,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors de la vérification de mise à jour');
        },
      );

      debugPrint('📡 Réponse check-update: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final versionInfo = VersionInfo.fromJson(responseData['data']);

          debugPrint('✅ Vérification réussie');
          debugPrint('   Dernière version: ${versionInfo.latestVersion}');
          debugPrint('   Mise à jour disponible: ${versionInfo.updateAvailable}');
          debugPrint('   Mise à jour requise: ${versionInfo.updateRequired}');
          debugPrint('   Forcer la mise à jour: ${versionInfo.forceUpdate}');

          apiResponse.data = versionInfo;
        } else {
          apiResponse.error = responseData['message'] ?? 'Erreur lors de la vérification';
        }
      } else {
        apiResponse.error = 'Erreur serveur (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification version: $e');
      apiResponse.error = 'Erreur: ${e.toString()}';
    }

    return apiResponse;
  }

  /// Récupérer la configuration de l'application
  static Future<ApiResponse<Map<String, dynamic>>> getAppConfig() async {
    ApiResponse<Map<String, dynamic>> apiResponse = ApiResponse();

    try {
      debugPrint('🔍 Récupération de la configuration...');

      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/config'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors de la récupération de la configuration');
        },
      );

      debugPrint('📡 Réponse config: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          debugPrint('✅ Configuration récupérée avec succès');
          apiResponse.data = responseData['data'];
        } else {
          apiResponse.error = responseData['message'] ?? 'Erreur lors de la récupération';
        }
      } else {
        apiResponse.error = 'Erreur serveur (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération config: $e');
      apiResponse.error = 'Erreur: ${e.toString()}';
    }

    return apiResponse;
  }

  /// Comparer deux versions (retourne true si version1 < version2)
  static bool isVersionLessThan(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2Parts = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Normaliser la longueur
      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }

      // Comparer partie par partie
      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] < v2Parts[i]) return true;
        if (v1Parts[i] > v2Parts[i]) return false;
      }

      return false; // Les versions sont égales
    } catch (e) {
      debugPrint('Erreur comparaison versions: $e');
      return false;
    }
  }
}
