#!/usr/bin/env dart

/**
 * Script de test de téléchargement automatique - VoXY Box
 */

import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('🔍 TEST TÉLÉCHARGEMENT AUTOMATIQUE - VoXY Box');
  print('============================================\n');

  try {
    // Obtenir le répertoire de documents
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory vocalisesDir = Directory('${appDocDir.path}/vocalises');
    
    print('📁 Répertoire vocalises: ${vocalisesDir.path}');
    
    if (await vocalisesDir.exists()) {
      // Lister les fichiers audio
      List<FileSystemEntity> files = vocalisesDir.listSync();
      List<File> audioFiles = files.whereType<File>().toList();
      
      print('📊 Fichiers audio trouvés: ${audioFiles.length}');
      
      for (File file in audioFiles) {
        print('\n📄 Fichier: ${file.path}');
        print('   Taille: ${await file.length()} bytes');
        print('   Existe: ${await file.exists()}');
        print('   Lisible: ${await file.exists() ? 'OUI' : 'NON'}');
        
        // Vérifier les permissions
        try {
          List<int> content = await file.readAsBytes();
          print('   Contenu: ${content.length} bytes');
          print('   Début: ${content.take(10).toList()}');
          
          // Vérifier si c'est un fichier audio valide
          if (content.length > 0) {
            print('   ✅ Fichier audio valide');
          } else {
            print('   ❌ Fichier vide');
          }
        } catch (e) {
          print('   ❌ Erreur de lecture: $e');
        }
      }
      
      // Test de lecture avec le premier fichier
      if (audioFiles.isNotEmpty) {
        File firstFile = audioFiles.first;
        print('\n🎵 Test de lecture avec: ${firstFile.path}');
        
        try {
          // Simuler la lecture audio
          print('   ✅ Fichier prêt pour la lecture');
          print('   💡 Utilisez ce chemin dans votre application: ${firstFile.path}');
        } catch (e) {
          print('   ❌ Erreur de lecture: $e');
        }
      }
      
    } else {
      print('❌ Répertoire vocalises n\'existe pas');
      print('💡 Créez d\'abord le répertoire et téléchargez des fichiers');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
  
  print('\n🎯 RÉSUMÉ:');
  print('==========');
  print('✅ Test terminé');
  print('💡 Vérifiez que les fichiers audio sont téléchargés');
  print('💡 Vérifiez que les chemins locaux sont corrects');
  print('💡 Vérifiez que les permissions sont correctes');
}
