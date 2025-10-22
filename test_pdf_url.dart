import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';

void main() async {
  print('🔍 TEST URL PDF - VoXY Box');
  print('==========================\n');

  // Test avec le fichier mentionné dans l'erreur
  final testFile = 'partitions/clark_eulalie_kyrie.pdf';
  final fullUrl = '${AppConstance.baseURL}/$testFile';
  
  print('📋 Configuration:');
  print('Base URL: ${AppConstance.baseURL}');
  print('Fichier: $testFile');
  print('URL complète: $fullUrl');
  print('');

  try {
    print('🌐 Test de connectivité...');
    final response = await http.get(Uri.parse(fullUrl));
    
    print('📡 Réponse HTTP:');
    print('Status Code: ${response.statusCode}');
    print('Reason Phrase: ${response.reasonPhrase}');
    print('Content Length: ${response.bodyBytes.length} bytes');
    print('Content Type: ${response.headers['content-type']}');
    print('');

    if (response.statusCode == 200) {
      print('✅ SUCCÈS: Le fichier PDF est accessible');
      
      // Vérifier si c'est bien un PDF
      if (response.bodyBytes.length > 4) {
        final header = String.fromCharCodes(response.bodyBytes.take(4));
        print('📄 Header du fichier: $header');
        
        if (header == '%PDF') {
          print('✅ Le fichier est bien un PDF valide');
        } else {
          print('❌ Le fichier ne semble pas être un PDF valide');
        }
      }
      
      // Sauvegarder un échantillon pour vérification
      final file = File('test_pdf_sample.pdf');
      await file.writeAsBytes(response.bodyBytes);
      print('💾 Échantillon sauvegardé: ${file.path}');
      
    } else {
      print('❌ ERREUR: Le fichier n\'est pas accessible');
      print('Vérifiez que:');
      print('1. Le serveur est en cours d\'exécution');
      print('2. L\'URL est correcte');
      print('3. Le fichier existe sur le serveur');
    }
    
  } catch (e) {
    print('❌ ERREUR de connexion: $e');
    print('');
    print('🔧 Solutions possibles:');
    print('1. Vérifiez votre connexion réseau');
    print('2. Vérifiez que le serveur est accessible');
    print('3. Vérifiez l\'IP dans appconstants.dart');
  }

  print('');
  print('🏁 Test terminé');
}
