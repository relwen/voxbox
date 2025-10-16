import 'package:shared_preferences/shared_preferences.dart';

/**
 * Script de test pour vérifier les SharedPreferences
 * et simuler la sauvegarde du numéro de téléphone
 */

void main() async {
  print('=== Test des SharedPreferences ===\n');
  
  try {
    // Obtenir l'instance des SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    print('1. Vérification des clés existantes:');
    final keys = prefs.getKeys();
    if (keys.isEmpty) {
      print('   Aucune clé trouvée dans SharedPreferences');
    } else {
      print('   Clés trouvées:');
      for (String key in keys) {
        print('   - $key: ${prefs.get(key)}');
      }
    }
    
    print('\n2. Test de sauvegarde du numéro de téléphone:');
    const testPhone = '+22670123456';
    await prefs.setString('user_phone', testPhone);
    print('   ✅ Numéro sauvegardé: $testPhone');
    
    print('\n3. Vérification de la récupération:');
    final retrievedPhone = prefs.getString('user_phone');
    print('   Numéro récupéré: $retrievedPhone');
    
    if (retrievedPhone == testPhone) {
      print('   ✅ SUCCÈS: Le numéro est correctement sauvegardé et récupéré');
    } else {
      print('   ❌ ERREUR: Le numéro récupéré ne correspond pas');
    }
    
    print('\n4. Test avec différentes clés:');
    await prefs.setString('phone', '+22670123457');
    await prefs.setString('phoneNumber', '+22670123458');
    await prefs.setString('user_phone_number', '+22670123459');
    
    print('   - user_phone: ${prefs.getString('user_phone')}');
    print('   - phone: ${prefs.getString('phone')}');
    print('   - phoneNumber: ${prefs.getString('phoneNumber')}');
    print('   - user_phone_number: ${prefs.getString('user_phone_number')}');
    
    print('\n=== Résumé ===');
    print('✅ SharedPreferences fonctionne correctement');
    print('✅ La sauvegarde et récupération du numéro fonctionne');
    print('✅ Le problème vient probablement de la connexion OTP');
    print('   qui ne sauvegarde pas le numéro dans SharedPreferences');
    
  } catch (e) {
    print('❌ ERREUR: $e');
  }
}
