#!/usr/bin/env dart

/**
 * Script de diagnostic des fichiers audio - VoXY Box
 */

import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('🔍 DIAGNOSTIC FICHIERS AUDIO - VoXY Box');
  print('=======================================\n');

  try {
    // Obtenir le répertoire de documents
    Directory appDocDir = await getApplicationDocumentsDirectory();
    print('📁 Répertoire de documents: ${appDocDir.path}');
    
    // Vérifier le répertoire vocalises
    Directory vocalisesDir = Directory('${appDocDir.path}/vocalises');
    print('📁 Répertoire vocalises: ${vocalisesDir.path}');
    
    if (await vocalisesDir.exists()) {
      print('✅ Répertoire vocalises existe');
      
      // Lister les fichiers
      List<FileSystemEntity> files = vocalisesDir.listSync();
      print('📊 Nombre de fichiers: ${files.length}');
      
      for (FileSystemEntity file in files) {
        if (file is File) {
          print('   📄 ${file.path}');
          print('      Taille: ${await file.length()} bytes');
          print('      Existe: ${await file.exists()}');
        }
      }
    } else {
      print('❌ Répertoire vocalises n\'existe pas');
      print('💡 Création du répertoire...');
      await vocalisesDir.create(recursive: true);
      print('✅ Répertoire créé');
    }
    
    // Vérifier les permissions
    print('\n🔐 Vérification des permissions:');
    print('   Lecture: ${await vocalisesDir.exists() ? 'OK' : 'ERREUR'}');
    
    // Test de création de fichier
    File testFile = File('${vocalisesDir.path}/test.txt');
    try {
      await testFile.writeAsString('test');
      await testFile.delete();
      print('   Écriture: OK');
    } catch (e) {
      print('   Écriture: ERREUR - $e');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
  
  print('\n🎯 RÉSUMÉ:');
  print('==========');
  print('✅ Diagnostic terminé');
  print('💡 Vérifiez que les fichiers audio sont téléchargés');
  print('💡 Vérifiez que les chemins locaux sont corrects');
}
