import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';

void main() async {
  print('=== Test de connexion mobile vers backend ===\n');
  
  // Test 1: Vérifier l'URL de base
  print('1. URL de base configurée: ${AppConstance.baseURL}');
  
  // Test 2: Tester l'endpoint des chorales
  print('\n2. Test de l\'endpoint /api/chorales');
  print('URL complète: ${AppConstance.baseURL}/api/chorales');
  
  try {
    final response = await http.get(
      Uri.parse('${AppConstance.baseURL}/api/chorales'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    print('Code HTTP: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ SUCCÈS: Connexion au backend réussie');
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final chorales = data['data'] as List;
        print('Nombre de chorales récupérées: ${chorales.length}');
        
        if (chorales.isNotEmpty) {
          print('Première chorale: ${chorales[0]['name']}');
        }
      } else {
        print('❌ ERREUR: Format de réponse incorrect');
        print('Réponse: ${response.body}');
      }
    } else {
      print('❌ ERREUR: Code HTTP ${response.statusCode}');
      print('Réponse: ${response.body}');
    }
  } catch (e) {
    print('❌ ERREUR DE CONNEXION: $e');
    print('\nVérifiez que:');
    print('1. Le serveur Laravel est démarré (php artisan serve)');
    print('2. L\'URL dans appconstants.dart est correcte');
    print('3. Le backend est accessible depuis l\'application');
  }
  
  print('\n=== Fin du test ===');
}
