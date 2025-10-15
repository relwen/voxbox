#!/usr/bin/env dart

/**
 * Script de vérification des URLs dans le projet VoXY Box
 * Vérifie que toutes les URLs utilisent AppConstance.baseURL
 */

import 'dart:io';

void main() {
  print('🔍 VÉRIFICATION DES URLs - VoXY Box');
  print('===================================\n');

  final libDir = Directory('lib');
  final issues = <String>[];

  // Parcourir tous les fichiers Dart
  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineNumber = i + 1;
        
        // Vérifier les URLs codées en dur
        if (line.contains(RegExp(r'http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+')) &&
            !line.contains('// static String baseURL') &&
            !line.contains('// ← IP locale')) {
          issues.add('${entity.path}:$lineNumber - URL codée en dur: ${line.trim()}');
        }
        
        // Vérifier les URLs localhost codées en dur
        if (line.contains(RegExp(r'http://localhost:[0-9]+')) &&
            !line.contains('// static String baseURL') &&
            !line.contains('// Pour iOS Simulator')) {
          issues.add('${entity.path}:$lineNumber - URL localhost codée en dur: ${line.trim()}');
        }
        
        // Vérifier les URLs 10.0.2.2 codées en dur
        if (line.contains(RegExp(r'http://10\.0\.2\.2:[0-9]+')) &&
            !line.contains('// static String baseURL') &&
            !line.contains('// Pour émulateur Android')) {
          issues.add('${entity.path}:$lineNumber - URL émulateur codée en dur: ${line.trim()}');
        }
        
        // Vérifier les constructions d'URLs manuelles
        if (line.contains('\${AppConstance.baseURL}/api/') &&
            !line.contains('AppConstance.vocalisesURL') &&
            !line.contains('AppConstance.partitionsURL') &&
            !line.contains('AppConstance.categoriesURL') &&
            !line.contains('AppConstance.messesURL') &&
            !line.contains('AppConstance.loginURL') &&
            !line.contains('AppConstance.registerURL')) {
          issues.add('${entity.path}:$lineNumber - URL construite manuellement: ${line.trim()}');
        }
      }
    }
  });

  // Afficher les résultats
  if (issues.isEmpty) {
    print('✅ Toutes les URLs utilisent correctement AppConstance.baseURL !');
    print('\n📋 URLs définies dans AppConstance:');
    print('   - baseURL: http://10.5.27.241:8001');
    print('   - loginURL: \$baseURL/api/login');
    print('   - registerURL: \$baseURL/api/register');
    print('   - vocalisesURL: \$baseURL/api/vocalises');
    print('   - partitionsURL: \$baseURL/api/partitions');
    print('   - categoriesURL: \$baseURL/api/categories');
    print('   - messesURL: \$baseURL/api/messes');
    print('   - voicePartsURL: \$baseURL/api/voice-parts');
  } else {
    print('❌ Problèmes détectés:');
    for (final issue in issues) {
      print('   $issue');
    }
  }

  print('\n🎯 Résumé:');
  print('   - Fichiers vérifiés: ${libDir.listSync(recursive: true).where((e) => e is File && e.path.endsWith('.dart')).length}');
  print('   - Problèmes trouvés: ${issues.length}');
  
  if (issues.isEmpty) {
    print('\n🚀 Votre application utilise correctement les constantes d\'URL !');
  } else {
    print('\n🔧 Veuillez corriger les problèmes ci-dessus.');
  }
}
