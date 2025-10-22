import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';

void main() async {
  print('🔍 TEST API MESSES - VoXY Box');
  print('==============================\n');

  try {
    // Récupérer le token
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token == null) {
      print('❌ Token non disponible');
      print('Connectez-vous d\'abord à l\'application');
      return;
    }

    print('✅ Token trouvé: ${token.substring(0, 20)}...');
    print('🌐 URL: ${AppConstance.messesURL}');
    print('');

    // Faire la requête
    print('📡 Envoi de la requête...');
    final response = await http.get(
      Uri.parse(AppConstance.messesURL),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📊 Réponse reçue:');
    print('Status Code: ${response.statusCode}');
    print('Content Length: ${response.body.length} bytes');
    print('');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Réponse JSON valide');
      print('Success: ${data['success']}');
      
      if (data['success'] == true && data['data'] != null) {
        final messes = data['data'] as List;
        print('📋 Nombre de messes: ${messes.length}');
        print('');

        // Analyser chaque messe
        for (int i = 0; i < messes.length; i++) {
          final messe = messes[i];
          print('📄 Messe ${i + 1}:');
          print('  ID: ${messe['id']} (type: ${messe['id'].runtimeType})');
          print('  Nom: ${messe['nom']} (type: ${messe['nom'].runtimeType})');
          print('  Description: ${messe['description']} (type: ${messe['description'].runtimeType})');
          print('  Couleur: ${messe['couleur']} (type: ${messe['couleur'].runtimeType})');
          print('  Icône: ${messe['icone']} (type: ${messe['icone'].runtimeType})');
          print('  Active: ${messe['active']} (type: ${messe['active'].runtimeType})');
          print('  Created At: ${messe['created_at']} (type: ${messe['created_at'].runtimeType})');
          print('  Updated At: ${messe['updated_at']} (type: ${messe['updated_at'].runtimeType})');
          
          // Vérifier les champs null
          List<String> nullFields = [];
          if (messe['id'] == null) nullFields.add('id');
          if (messe['nom'] == null) nullFields.add('nom');
          if (messe['couleur'] == null) nullFields.add('couleur');
          if (messe['icone'] == null) nullFields.add('icone');
          if (messe['active'] == null) nullFields.add('active');
          if (messe['created_at'] == null) nullFields.add('created_at');
          if (messe['updated_at'] == null) nullFields.add('updated_at');
          
          if (nullFields.isNotEmpty) {
            print('  ⚠️  Champs null détectés: ${nullFields.join(', ')}');
          } else {
            print('  ✅ Tous les champs requis sont présents');
          }
          
          // Vérifier les sections si présentes
          if (messe['sections'] != null) {
            final sections = messe['sections'] as List;
            print('  📁 Sections: ${sections.length}');
            
            for (int j = 0; j < sections.length; j++) {
              final section = sections[j];
              print('    Section ${j + 1}:');
              print('      ID: ${section['id']} (type: ${section['id'].runtimeType})');
              print('      Nom: ${section['nom']} (type: ${section['nom'].runtimeType})');
              print('      Messe ID: ${section['messe_id']} (type: ${section['messe_id'].runtimeType})');
              
              // Vérifier les champs null des sections
              List<String> sectionNullFields = [];
              if (section['id'] == null) sectionNullFields.add('id');
              if (section['nom'] == null) sectionNullFields.add('nom');
              if (section['messe_id'] == null) sectionNullFields.add('messe_id');
              if (section['created_at'] == null) sectionNullFields.add('created_at');
              if (section['updated_at'] == null) sectionNullFields.add('updated_at');
              
              if (sectionNullFields.isNotEmpty) {
                print('      ⚠️  Champs null détectés: ${sectionNullFields.join(', ')}');
              }
            }
          }
          
          print('');
        }
        
      } else {
        print('❌ Réponse invalide ou pas de données');
        print('Message: ${data['message']}');
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
      print('Réponse: ${response.body}');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('🏁 Test terminé');
}
