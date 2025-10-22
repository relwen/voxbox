import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';

void main() async {
  print('🔍 TEST CHEMINS PDF - VoXY Box');
  print('==============================\n');

  final baseUrl = AppConstance.baseURL;
  final fileName = 'clark_eulalie_kyrie.pdf';
  
  // Différents chemins possibles à tester
  final possiblePaths = [
    'partitions/$fileName',
    'storage/partitions/$fileName',
    'public/partitions/$fileName',
    'uploads/partitions/$fileName',
    'files/partitions/$fileName',
    'assets/partitions/$fileName',
    'storage/app/public/partitions/$fileName',
    'public/uploads/partitions/$fileName',
    'storage/uploads/partitions/$fileName',
    'app/public/partitions/$fileName',
    'resources/partitions/$fileName',
    'media/partitions/$fileName',
    'documents/partitions/$fileName',
    'pdfs/$fileName',
    'storage/pdfs/$fileName',
    'public/pdfs/$fileName',
  ];

  print('📋 Test de ${possiblePaths.length} chemins possibles...\n');

  for (int i = 0; i < possiblePaths.length; i++) {
    final path = possiblePaths[i];
    final fullUrl = '$baseUrl/$path';
    
    print('${i + 1}. Test: $path');
    
    try {
      final response = await http.get(Uri.parse(fullUrl));
      
      if (response.statusCode == 200) {
        print('   ✅ TROUVÉ! Status: ${response.statusCode}');
        print('   📏 Taille: ${response.bodyBytes.length} bytes');
        print('   🌐 URL: $fullUrl');
        
        // Vérifier si c'est bien un PDF
        if (response.bodyBytes.length > 4) {
          final header = String.fromCharCodes(response.bodyBytes.take(4));
          if (header == '%PDF') {
            print('   📄 PDF valide détecté');
          } else {
            print('   ⚠️  Fichier trouvé mais pas un PDF valide (header: $header)');
          }
        }
        print('');
        break; // Arrêter après le premier succès
      } else {
        print('   ❌ Status: ${response.statusCode}');
      }
    } catch (e) {
      print('   ❌ Erreur: $e');
    }
    
    // Petite pause pour éviter de surcharger le serveur
    await Future.delayed(Duration(milliseconds: 100));
  }

  print('🏁 Test terminé');
  print('');
  print('💡 Si aucun fichier n\'a été trouvé, vérifiez:');
  print('1. Que le serveur Laravel est configuré pour servir les fichiers statiques');
  print('2. Que les fichiers PDF sont dans le bon dossier');
  print('3. Que les permissions sont correctes');
  print('4. Que la route est configurée dans Laravel');
}
