#!/usr/bin/env dart

/**
 * Script de test de téléchargement audio - VoXY Box
 */

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🔍 TEST TÉLÉCHARGEMENT AUDIO - VoXY Box');
  print('=======================================\n');

  try {
    // Configuration
    String baseURL = 'http://192.168.11.102:8000';
    String loginURL = '$baseURL/api/login';
    String vocalisesURL = '$baseURL/api/vocalises';
    
    print('📡 Configuration:');
    print('   - Backend: $baseURL');
    print('   - Login: $loginURL');
    print('   - Vocalises: $vocalisesURL\n');

    // Test 1: Authentification
    print('1. 🔐 Test d\'authentification...');
    
    HttpClient httpClient = HttpClient();
    HttpClientRequest loginRequest = await httpClient.postUrl(Uri.parse(loginURL));
    loginRequest.headers.set('Content-Type', 'application/json');
    loginRequest.headers.set('Accept', 'application/json');
    
    String loginBody = jsonEncode({
      'email': 'admin@voxy.com',
      'password': 'admin123'
    });
    loginRequest.write(loginBody);
    
    HttpClientResponse loginResponse = await loginRequest.close();
    String loginResponseBody = await loginResponse.transform(utf8.decoder).join();
    
    if (loginResponse.statusCode == 200) {
      Map<String, dynamic> loginData = jsonDecode(loginResponseBody);
      String token = loginData['token'];
      print('✅ Authentification réussie');
      print('   Token: ${token.substring(0, 20)}...');
      
      // Test 2: Récupération des vocalises
      print('\n2. 📋 Récupération des vocalises...');
      
      HttpClientRequest vocalisesRequest = await httpClient.getUrl(Uri.parse(vocalisesURL));
      vocalisesRequest.headers.set('Accept', 'application/json');
      vocalisesRequest.headers.set('Authorization', 'Bearer $token');
      
      HttpClientResponse vocalisesResponse = await vocalisesRequest.close();
      String vocalisesResponseBody = await vocalisesResponse.transform(utf8.decoder).join();
      
      if (vocalisesResponse.statusCode == 200) {
        Map<String, dynamic> vocalisesData = jsonDecode(vocalisesResponseBody);
        List<dynamic> vocalises = vocalisesData['data'] ?? [];
        
        print('✅ Vocalises récupérées: ${vocalises.length}');
        
        if (vocalises.isNotEmpty) {
          // Test 3: Téléchargement du premier fichier audio
          print('\n3. 🎵 Test de téléchargement audio...');
          
          Map<String, dynamic> firstVocalise = vocalises.first;
          int vocaliseId = firstVocalise['id'];
          String? audioPath = firstVocalise['audio_path'];
          
          print('   - ID: $vocaliseId');
          print('   - Titre: ${firstVocalise['title']}');
          print('   - Chemin audio: $audioPath');
          
          if (audioPath != null) {
            String downloadURL = '$baseURL/api/vocalises/$vocaliseId/download-audio';
            print('   - URL de téléchargement: $downloadURL');
            
            // Télécharger le fichier
            HttpClientRequest downloadRequest = await httpClient.getUrl(Uri.parse(downloadURL));
            downloadRequest.headers.set('Accept', 'application/json');
            downloadRequest.headers.set('Authorization', 'Bearer $token');
            
            HttpClientResponse downloadResponse = await downloadRequest.close();
            
            if (downloadResponse.statusCode == 200) {
              print('✅ Téléchargement réussi');
              
              // Obtenir le répertoire de documents
              Directory appDocDir = await getApplicationDocumentsDirectory();
              Directory vocalisesDir = Directory('${appDocDir.path}/vocalises');
              
              if (!await vocalisesDir.exists()) {
                await vocalisesDir.create(recursive: true);
              }
              
              // Sauvegarder le fichier
              String fileName = 'vocalise_${vocaliseId}.mp3';
              File localFile = File('${vocalisesDir.path}/$fileName');
              
              List<int> audioData = await downloadResponse.fold<List<int>>(
                <int>[],
                (previous, element) => [...previous, ...element],
              );
              
              await localFile.writeAsBytes(audioData);
              
              print('✅ Fichier sauvegardé: ${localFile.path}');
              print('   Taille: ${await localFile.length()} bytes');
              print('   Existe: ${await localFile.exists()}');
              
              // Test 4: Vérification du fichier
              print('\n4. 🔍 Vérification du fichier...');
              
              if (await localFile.exists()) {
                List<int> fileContent = await localFile.readAsBytes();
                print('✅ Fichier lisible');
                print('   Taille: ${fileContent.length} bytes');
                print('   Début: ${fileContent.take(10).toList()}');
                
                // Vérifier si c'est un fichier audio valide
                if (fileContent.length > 0) {
                  print('✅ Fichier audio valide');
                } else {
                  print('❌ Fichier vide');
                }
              } else {
                print('❌ Fichier non trouvé');
              }
              
            } else {
              print('❌ Échec du téléchargement');
              print('   Code: ${downloadResponse.statusCode}');
            }
          } else {
            print('❌ Pas de fichier audio pour cette vocalise');
          }
        } else {
          print('❌ Aucune vocalise trouvée');
        }
      } else {
        print('❌ Échec de récupération des vocalises');
        print('   Code: ${vocalisesResponse.statusCode}');
        print('   Réponse: $vocalisesResponseBody');
      }
    } else {
      print('❌ Échec de l\'authentification');
      print('   Code: ${loginResponse.statusCode}');
      print('   Réponse: $loginResponseBody');
    }
    
    httpClient.close();
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
  
  print('\n🎯 RÉSUMÉ:');
  print('==========');
  print('✅ Test terminé');
  print('💡 Vérifiez que les fichiers sont téléchargés correctement');
  print('💡 Vérifiez que les chemins locaux sont corrects');
}
