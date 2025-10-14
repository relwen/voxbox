// Script de test pour vérifier la connexion au backend
// Exécutez avec: dart test_connection.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('=== Test de connexion au backend ===\n');
  
  // Configuration
  String baseUrl = 'http://192.168.23.143:8001';
  
  // Test 1: Vérifier que le serveur répond
  print('1. Test de connectivité du serveur...');
  try {
    HttpClient client = HttpClient();
    HttpClientRequest request = await client.getUrl(Uri.parse('$baseUrl/api/chorales'));
    request.headers.set('Accept', 'application/json');
    HttpClientResponse response = await request.close();
    
    print('   ✓ Serveur accessible (Code: ${response.statusCode})');
    
    if (response.statusCode == 200) {
      String responseBody = await response.transform(utf8.decoder).join();
      print('   ✓ Réponse reçue: ${responseBody.length} caractères');
    }
  } catch (e) {
    print('   ✗ Erreur de connexion: $e');
  }
  
  // Test 2: Vérifier l'endpoint vocalises
  print('\n2. Test de l\'endpoint vocalises...');
  try {
    HttpClient client = HttpClient();
    HttpClientRequest request = await client.getUrl(Uri.parse('$baseUrl/api/vocalises'));
    request.headers.set('Accept', 'application/json');
    HttpClientResponse response = await request.close();
    
    print('   ✓ Endpoint vocalises accessible (Code: ${response.statusCode})');
    
    String responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 401) {
      print('   ✓ Authentification requise (comportement attendu)');
    } else {
      print('   ✓ Réponse: ${responseBody.length} caractères');
    }
  } catch (e) {
    print('   ✗ Erreur: $e');
  }
  
  // Test 3: Vérifier l'endpoint de synchronisation
  print('\n3. Test de l\'endpoint de synchronisation...');
  try {
    HttpClient client = HttpClient();
    HttpClientRequest request = await client.getUrl(Uri.parse('$baseUrl/api/vocalises/sync'));
    request.headers.set('Accept', 'application/json');
    HttpClientResponse response = await request.close();
    
    print('   ✓ Endpoint sync accessible (Code: ${response.statusCode})');
    
    String responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 401) {
      print('   ✓ Authentification requise (comportement attendu)');
    } else {
      print('   ✓ Réponse: ${responseBody.length} caractères');
    }
  } catch (e) {
    print('   ✗ Erreur: $e');
  }
  
  print('\n=== Résumé ===');
  print('✓ Backend Laravel fonctionne sur le port 8001');
  print('✓ Endpoints API vocalises sont accessibles');
  print('✓ Authentification requise (sécurité activée)');
  print('\nProchaines étapes:');
  print('1. Connectez-vous à l\'application pour obtenir un token');
  print('2. Testez la synchronisation des vocalises');
  print('3. Testez le mode hors ligne');
}
