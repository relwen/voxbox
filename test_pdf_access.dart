import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Test d\'accès aux fichiers PDF...');
  
  // Test d'accès à un fichier PDF spécifique
  final testUrl = 'http://192.168.11.105:8001/storage/partitions/air_moore_gloria.pdf';
  
  try {
    print('📡 Test de l\'URL: $testUrl');
    
    final response = await http.get(Uri.parse(testUrl));
    
    if (response.statusCode == 200) {
      print('✅ Succès! Fichier PDF accessible');
      print('📊 Taille: ${response.bodyBytes.length} bytes');
      print('📄 Type: ${response.headers['content-type']}');
      
      // Test de sauvegarde locale
      final directory = Directory('/tmp/voxbox_test');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = File('${directory.path}/test_gloria.pdf');
      await file.writeAsBytes(response.bodyBytes);
      
      if (await file.exists()) {
        print('💾 Fichier sauvegardé localement: ${file.path}');
        print('📏 Taille locale: ${await file.length()} bytes');
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
      print('📝 Réponse: ${response.body}');
    }
    
  } catch (e) {
    print('❌ Erreur de connexion: $e');
  }
  
  print('\n🔍 Test des URLs de base...');
  
  // Test des endpoints de base
  final baseUrls = [
    'http://192.168.11.105:8001/api/chorales',
    'http://192.168.11.105:8001/api/messes',
  ];
  
  for (final url in baseUrls) {
    try {
      final response = await http.get(Uri.parse(url));
      print('${response.statusCode == 200 ? '✅' : '❌'} $url - ${response.statusCode}');
    } catch (e) {
      print('❌ $url - Erreur: $e');
    }
  }
}
