// Script de test pour le service vocalise
// Exécutez avec: dart test_vocalise_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Test du service vocalise ===\n');
  
  // Configuration
  String baseUrl = 'http://192.168.11.104:8001';
  
  try {
    // 1. Connexion pour obtenir un token
    print('1. Connexion...');
    var loginResponse = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': 'admin@voxy.com',
        'password': 'admin123',
      }),
    );
    
    if (loginResponse.statusCode == 200) {
      var loginData = jsonDecode(loginResponse.body);
      String token = loginData['token'];
      print('✓ Connexion réussie');
      print('Token: ${token.substring(0, 30)}...\n');
      
      // 2. Test de récupération des vocalises
      print('2. Test de récupération des vocalises...');
      var vocalisesResponse = await http.get(
        Uri.parse('$baseUrl/api/vocalises'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Code HTTP: ${vocalisesResponse.statusCode}');
      
      if (vocalisesResponse.statusCode == 200) {
        var vocalisesData = jsonDecode(vocalisesResponse.body);
        print('✓ Vocalises récupérées avec succès');
        print('Structure de la réponse:');
        print('  - success: ${vocalisesData['success']}');
        print('  - data: ${vocalisesData['data']?.length ?? 0} éléments');
        
        if (vocalisesData['data'] != null && vocalisesData['data'].isNotEmpty) {
          var firstVocalise = vocalisesData['data'][0];
          print('\nPremier élément:');
          print('  - id: ${firstVocalise['id']}');
          print('  - title: ${firstVocalise['title']}');
          print('  - voice_part: ${firstVocalise['voice_part']}');
          print('  - audio_path: ${firstVocalise['audio_path']}');
          print('  - chorale: ${firstVocalise['chorale']?['name']}');
        }
        
        // 3. Test de la synchronisation
        print('\n3. Test de synchronisation...');
        var syncResponse = await http.get(
          Uri.parse('$baseUrl/api/vocalises/sync'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        
        print('Code HTTP: ${syncResponse.statusCode}');
        
        if (syncResponse.statusCode == 200) {
          var syncData = jsonDecode(syncResponse.body);
          print('✓ Synchronisation réussie');
          print('  - success: ${syncData['success']}');
          print('  - data: ${syncData['data']?.length ?? 0} éléments');
          print('  - last_sync: ${syncData['last_sync']}');
        } else {
          print('✗ Erreur de synchronisation');
          print('Réponse: ${syncResponse.body}');
        }
        
      } else {
        print('✗ Erreur lors de la récupération des vocalises');
        print('Réponse: ${vocalisesResponse.body}');
      }
      
    } else {
      print('✗ Échec de la connexion');
      print('Code: ${loginResponse.statusCode}');
      print('Réponse: ${loginResponse.body}');
    }
    
  } catch (e) {
    print('✗ Erreur: $e');
  }
  
  print('\n=== Fin du test ===');
}
