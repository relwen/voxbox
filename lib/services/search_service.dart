import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/partition.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/services/api_response.dart';

class SearchResults {
  final List<Partition> partitions;
  final List<Vocalise> vocalises;
  final List<Messe> messes;
  final List<ChantDeMesse> chants;

  SearchResults({
    this.partitions = const [],
    this.vocalises = const [],
    this.messes = const [],
    this.chants = const [],
  });

  int get totalCount => partitions.length + vocalises.length + messes.length + chants.length;

  bool get isEmpty => totalCount == 0;
}

class SearchService {
  /// Rechercher dans toutes les catégories
  static Future<ApiResponse<SearchResults>> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return ApiResponse(
        error: 'Veuillez entrer un terme de recherche',
        data: null,
      );
    }

    try {
      // URL de l'endpoint de recherche globale
      final searchUrl = '${AppConstance.baseURL}/api/search?q=${Uri.encodeComponent(query)}';

      debugPrint('🔍 Recherche globale: $searchUrl');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null)
            'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('La recherche a pris trop de temps. Vérifiez votre connexion.');
        },
      );

      debugPrint('📡 Réponse recherche: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];

          // Parser les résultats
          List<Partition> partitions = [];
          List<Vocalise> vocalises = [];
          List<Messe> messes = [];
          List<ChantDeMesse> chants = [];

          if (data['partitions'] != null) {
            partitions = (data['partitions'] as List)
                .map((item) => Partition.fromJson(item))
                .toList();
          }

          if (data['vocalises'] != null) {
            vocalises = (data['vocalises'] as List)
                .map((item) => Vocalise.fromJson(item))
                .toList();
          }

          if (data['messes'] != null) {
            messes = (data['messes'] as List)
                .map((item) => Messe.fromJson(item))
                .toList();
          }

          if (data['chants'] != null || data['chants_de_messe'] != null) {
            chants = ((data['chants'] ?? data['chants_de_messe']) as List)
                .map((item) => ChantDeMesse.fromJson(item))
                .toList();
          }

          final results = SearchResults(
            partitions: partitions,
            vocalises: vocalises,
            messes: messes,
            chants: chants,
          );

          debugPrint('✅ Recherche terminée: ${results.totalCount} résultats');

          return ApiResponse(
            error: null,
            data: results,
          );
        } else {
          return ApiResponse(
            error: responseData['message'] ?? 'Erreur lors de la recherche',
            data: null,
          );
        }
      } else if (response.statusCode == 404) {
        // Si l'endpoint n'existe pas, essayer de rechercher manuellement
        debugPrint('⚠️ Endpoint de recherche non trouvé, recherche manuelle...');
        return await _fallbackSearch(query);
      } else {
        return ApiResponse(
          error: 'Erreur serveur (${response.statusCode})',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur de recherche: $e');

      // En cas d'erreur, essayer la recherche manuelle
      return await _fallbackSearch(query);
    }
  }

  /// Recherche manuelle (fallback) si l'endpoint global n'existe pas
  static Future<ApiResponse<SearchResults>> _fallbackSearch(String query) async {
    try {
      debugPrint('🔄 Recherche manuelle dans chaque catégorie...');

      List<Partition> partitions = [];
      List<Vocalise> vocalises = [];
      List<Messe> messes = [];
      List<ChantDeMesse> chants = [];

      final queryLower = query.toLowerCase();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Rechercher dans les partitions
      try {
        final partitionsResponse = await http.get(
          Uri.parse(AppConstance.partitionsURL),
          headers: {
            'Accept': 'application/json',
            if (token != null)
              'Authorization': 'Bearer $token',
          },
        );

        if (partitionsResponse.statusCode == 200) {
          final data = jsonDecode(partitionsResponse.body);
          if (data['success'] == true && data['data'] != null) {
            final allPartitions = (data['data'] as List)
                .map((item) => Partition.fromJson(item))
                .toList();

            partitions = allPartitions.where((p) {
              return p.title.toLowerCase().contains(queryLower) ||
                  (p.description?.toLowerCase().contains(queryLower) ?? false);
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('Erreur recherche partitions: $e');
      }

      // Rechercher dans les vocalises
      try {
        final vocalisesResponse = await http.get(
          Uri.parse(AppConstance.vocalisesURL),
          headers: {
            'Accept': 'application/json',
            if (token != null)
              'Authorization': 'Bearer $token',
          },
        );

        if (vocalisesResponse.statusCode == 200) {
          final data = jsonDecode(vocalisesResponse.body);
          if (data['success'] == true && data['data'] != null) {
            final allVocalises = (data['data'] as List)
                .map((item) => Vocalise.fromJson(item))
                .toList();

            vocalises = allVocalises.where((v) {
              return v.title.toLowerCase().contains(queryLower) ||
                  (v.description?.toLowerCase().contains(queryLower) ?? false) ||
                  v.voicePart.toLowerCase().contains(queryLower);
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('Erreur recherche vocalises: $e');
      }

      // Rechercher dans les messes
      try {
        final messesResponse = await http.get(
          Uri.parse(AppConstance.messesURL),
          headers: {
            'Accept': 'application/json',
            if (token != null)
              'Authorization': 'Bearer $token',
          },
        );

        if (messesResponse.statusCode == 200) {
          final data = jsonDecode(messesResponse.body);
          if (data['success'] == true && data['data'] != null) {
            final allMesses = (data['data'] as List)
                .map((item) => Messe.fromJson(item))
                .toList();

            messes = allMesses.where((m) {
              return m.nom.toLowerCase().contains(queryLower) ||
                  (m.description?.toLowerCase().contains(queryLower) ?? false);
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('Erreur recherche messes: $e');
      }

      final results = SearchResults(
        partitions: partitions,
        vocalises: vocalises,
        messes: messes,
        chants: chants,
      );

      debugPrint('✅ Recherche manuelle terminée: ${results.totalCount} résultats');

      return ApiResponse(
        error: null,
        data: results,
      );
    } catch (e) {
      debugPrint('❌ Erreur recherche manuelle: $e');
      return ApiResponse(
        error: 'Erreur lors de la recherche: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Rechercher uniquement dans les partitions
  static Future<ApiResponse<List<Partition>>> searchPartitions(String query) async {
    try {
      final searchUrl = '${AppConstance.partitionsURL}?search=$query';
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Accept': 'application/json',
          if (token != null)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<Partition> partitions = (responseData['data'] as List)
              .map((item) => Partition.fromJson(item))
              .toList();

          return ApiResponse(error: null, data: partitions);
        }
      }

      return ApiResponse(
        error: 'Erreur lors de la recherche des partitions',
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        error: 'Erreur: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Rechercher uniquement dans les vocalises
  static Future<ApiResponse<List<Vocalise>>> searchVocalises(String query) async {
    try {
      debugPrint('🔍 Recherche de vocalises: $query');

      final searchUrl = '${AppConstance.vocalisesURL}?search=${Uri.encodeComponent(query)}';
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null)
            'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('La recherche a pris trop de temps');
        },
      );

      debugPrint('📡 Réponse recherche vocalises: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // Le backend retourne déjà les fichiers organisés par sous-dossiers/pupitres
          // Les fichiers audio_files, pdf_files, soprano_files, etc. sont automatiquement
          // récupérés selon la configuration des sous-dossiers sur le backend
          List<Vocalise> vocalises = (responseData['data'] as List)
              .map((item) => Vocalise.fromJson(item))
              .toList();

          debugPrint('✅ Recherche vocalises terminée: ${vocalises.length} résultats');

          return ApiResponse(error: null, data: vocalises);
        }
      }

      return ApiResponse(
        error: 'Erreur lors de la recherche des vocalises',
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Erreur recherche vocalises: $e');
      return ApiResponse(
        error: 'Erreur: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Rechercher uniquement dans les messes
  static Future<ApiResponse<List<Messe>>> searchMesses(String query) async {
    try {
      final searchUrl = '${AppConstance.messesURL}?search=$query';
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Accept': 'application/json',
          if (token != null)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<Messe> messes = (responseData['data'] as List)
              .map((item) => Messe.fromJson(item))
              .toList();

          return ApiResponse(error: null, data: messes);
        }
      }

      return ApiResponse(
        error: 'Erreur lors de la recherche des messes',
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        error: 'Erreur: ${e.toString()}',
        data: null,
      );
    }
  }
}
