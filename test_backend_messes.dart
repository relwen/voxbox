import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';

void main() async {
  print('🔍 TEST BACKEND MESSES - VoXY Box');
  print('==================================\n');

  try {
    // Récupérer le token
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token == null) {
      print('❌ Token non disponible');
      print('Connectez-vous d\'abord à l\'application');
      return;
    }

    print('✅ Token trouvé: ${token.substring(0, 20)}...');
    print('🌐 Base URL: ${AppConstance.baseURL}');
    print('');

    // Test 1: Récupérer toutes les messes
    print('📋 Test 1: Récupération des messes...');
    final messesResponse = await http.get(
      Uri.parse(AppConstance.messesURL),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Status Code: ${messesResponse.statusCode}');
    
    if (messesResponse.statusCode == 200) {
      final messesData = json.decode(messesResponse.body);
      print('✅ Succès! ${messesData['data'].length} messes trouvées:');
      
      for (var messe in messesData['data']) {
        print('  📄 Messe: ${messe['nom']} (ID: ${messe['id']})');
        print('     Couleur: ${messe['couleur']}');
        print('     Icône: ${messe['icone']}');
        print('     Active: ${messe['active']}');
        
        // Vérifier les références (sections)
        if (messe['references'] != null) {
          print('     Références: ${messe['references'].length}');
          for (var ref in messe['references']) {
            print('       - ${ref['name']} (ID: ${ref['id']})');
            print('         Position: ${ref['order_position']}');
            if (ref['partitions'] != null) {
              print('         Partitions: ${ref['partitions'].length}');
            }
          }
        } else {
          print('     ❌ Aucune référence trouvée');
        }
        print('');
      }
      
      // Test 2: Récupérer les sections d'une messe
      if (messesData['data'].isNotEmpty) {
        final firstMesse = messesData['data'][0];
        final messeId = firstMesse['id'];
        
        print('📂 Test 2: Récupération des sections de la messe ID $messeId...');
        final sectionsResponse = await http.get(
          Uri.parse('${AppConstance.messesURL}/$messeId/sections'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        print('Status Code: ${sectionsResponse.statusCode}');
        
        if (sectionsResponse.statusCode == 200) {
          final sectionsData = json.decode(sectionsResponse.body);
          print('✅ Succès! ${sectionsData['data'].length} sections trouvées:');
          
          for (var section in sectionsData['data']) {
            print('  📁 Section: ${section['name']} (ID: ${section['id']})');
            print('     Description: ${section['description']}');
            print('     Position: ${section['order_position']}');
            print('     Messe ID: ${section['messe_id']}');
            
            if (section['partitions'] != null) {
              print('     Partitions: ${section['partitions'].length}');
              for (var partition in section['partitions']) {
                print('       - ${partition['title']} (ID: ${partition['id']})');
                print('         Audio: ${partition['audio_path']}');
                print('         PDF: ${partition['pdf_path']}');
                print('         Image: ${partition['image_path']}');
              }
            }
            print('');
          }
        } else {
          print('❌ Erreur sections: ${sectionsResponse.statusCode}');
          print('Réponse: ${sectionsResponse.body}');
        }
      }
      
    } else {
      print('❌ Erreur messes: ${messesResponse.statusCode}');
      print('Réponse: ${messesResponse.body}');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('🏁 Test terminé');
}
