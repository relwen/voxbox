import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';

void main() async {
  print('🔍 TEST SECTION CHANTS - VoXY Box');
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

    if (messesResponse.statusCode == 200) {
      final messesData = json.decode(messesResponse.body);
      print('✅ Succès! ${messesData['data'].length} messes trouvées');
      
      // Trouver la messe "Amina"
      var aminaMesse;
      for (var messe in messesData['data']) {
        if (messe['nom'].toString().toLowerCase().contains('amina')) {
          aminaMesse = messe;
          break;
        }
      }
      
      if (aminaMesse != null) {
        print('🎯 Messe Amina trouvée: ${aminaMesse['nom']} (ID: ${aminaMesse['id']})');
        
        // Test 2: Récupérer les sections de la messe Amina
        print('\n📂 Test 2: Récupération des sections de la messe Amina...');
        final sectionsResponse = await http.get(
          Uri.parse('${AppConstance.messesURL}/${aminaMesse['id']}/sections'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        print('Status Code: ${sectionsResponse.statusCode}');
        
        if (sectionsResponse.statusCode == 200) {
          final sectionsData = json.decode(sectionsResponse.body);
          print('✅ Succès! ${sectionsData['data'].length} sections trouvées');
          
          // Trouver la section "Gloria"
          var gloriaSection;
          for (var section in sectionsData['data']) {
            if (section['name'].toString().toLowerCase().contains('gloria')) {
              gloriaSection = section;
              break;
            }
          }
          
          if (gloriaSection != null) {
            print('🎯 Section Gloria trouvée: ${gloriaSection['name']} (ID: ${gloriaSection['id']})');
            
            // Test 3: Récupérer les chants de la section Gloria
            print('\n🎵 Test 3: Récupération des chants de la section Gloria...');
            final chantsResponse = await http.get(
              Uri.parse('${AppConstance.baseURL}/api/references/${gloriaSection['id']}/partitions'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
            
            print('Status Code: ${chantsResponse.statusCode}');
            print('URL appelée: ${AppConstance.baseURL}/api/references/${gloriaSection['id']}/partitions');
            
            if (chantsResponse.statusCode == 200) {
              final chantsData = json.decode(chantsResponse.body);
              print('✅ Succès! ${chantsData['data'].length} chants trouvés');
              
              for (var chant in chantsData['data']) {
                print('  🎶 Chant: ${chant['title']} (ID: ${chant['id']})');
                print('     Audio: ${chant['audio_path']}');
                print('     PDF: ${chant['pdf_path']}');
                print('     Image: ${chant['image_path']}');
              }
            } else {
              print('❌ Erreur chants: ${chantsResponse.statusCode}');
              print('Réponse: ${chantsResponse.body}');
            }
          } else {
            print('❌ Section Gloria non trouvée');
            print('Sections disponibles:');
            for (var section in sectionsData['data']) {
              print('  - ${section['name']} (ID: ${section['id']})');
            }
          }
        } else {
          print('❌ Erreur sections: ${sectionsResponse.statusCode}');
          print('Réponse: ${sectionsResponse.body}');
        }
      } else {
        print('❌ Messe Amina non trouvée');
        print('Messes disponibles:');
        for (var messe in messesData['data']) {
          print('  - ${messe['nom']} (ID: ${messe['id']})');
        }
      }
    } else {
      print('❌ Erreur messes: ${messesResponse.statusCode}');
      print('Réponse: ${messesResponse.body}');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('\n🏁 Test terminé');
}
