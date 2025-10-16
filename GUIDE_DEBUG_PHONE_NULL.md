# Guide de Débogage - _loadUserPhone() Renvoie Null

## ✅ Problème Identifié

La méthode `_loadUserPhone()` renvoie toujours `null`, ce qui signifie que le numéro de téléphone n'est pas sauvegardé dans SharedPreferences lors de la connexion OTP.

## 🔍 Diagnostic Ajouté

### **1. Logs de Débogage Améliorés**

La méthode `_loadUserPhone()` a été améliorée pour afficher :
- Toutes les clés possibles pour le numéro de téléphone
- Toutes les clés disponibles dans SharedPreferences
- Messages d'erreur détaillés

### **2. Interface de Test**

Un bouton "Simuler numéro de test" a été ajouté pour :
- Sauvegarder un numéro de test
- Vérifier que la récupération fonctionne
- Tester le processus complet

## 🧪 Tests de Diagnostic

### **1. Vérifier les Logs de la Console**

Lancez l'application et ouvrez la page d'inscription. Dans la console, vous devriez voir :

```
🔍 Recherche du numéro de téléphone...
   - Clé "user_phone": null
   - Clé "phone": null
   - Clé "phoneNumber": null
   - Clé "user_phone_number": null
📱 Numéro de téléphone récupéré: null
⚠️ Aucun numéro de téléphone trouvé dans SharedPreferences
🔍 Toutes les clés disponibles:
   - token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
   - isConnected: true
   - user: {"id":1,"name":"Test User",...}
```

### **2. Utiliser le Bouton de Test**

Si le numéro n'est pas trouvé, cliquez sur "Simuler numéro de test" :
- Sauvegarde un numéro de test (+22670123456)
- Recharge le numéro
- Affiche un message de confirmation

### **3. Vérifier la Connexion OTP**

Le problème principal est probablement que la connexion OTP ne sauvegarde pas le numéro. Vérifiez dans le code de connexion :

```dart
// Dans la page de connexion OTP, il devrait y avoir :
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_phone', phoneNumber);
print('📱 Numéro sauvegardé: $phoneNumber');
```

## 🔧 Solutions Possibles

### **Solution 1: Corriger la Connexion OTP**

Si la connexion OTP ne sauvegarde pas le numéro, ajoutez ce code :

```dart
// Dans la page de connexion OTP (après validation OTP)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_phone', phoneNumber);
print('📱 Numéro sauvegardé lors de la connexion: $phoneNumber');
```

### **Solution 2: Utiliser une Clé Différente**

Si le numéro est sauvegardé avec une clé différente, modifiez `_loadUserPhone()` :

```dart
// Essayer la clé utilisée par la connexion OTP
_userPhone = prefs.getString('phone_number') ?? // Nouvelle clé
             prefs.getString('user_phone') ?? 
             prefs.getString('phone');
```

### **Solution 3: Récupérer depuis les Données Utilisateur**

Si le numéro est dans les données utilisateur sauvegardées :

```dart
void _loadUserPhone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Essayer de récupérer depuis les données utilisateur
    final userData = prefs.getString('user');
    if (userData != null) {
      final user = jsonDecode(userData);
      _userPhone = user['phone'];
      print('📱 Numéro récupéré depuis les données utilisateur: $_userPhone');
    }
    
    // Si pas trouvé, essayer les clés directes
    if (_userPhone == null) {
      _userPhone = prefs.getString('user_phone') ?? 
                   prefs.getString('phone');
    }
    
    if (mounted) setState(() {});
  } catch (e) {
    print('⚠️ Erreur: $e');
  }
}
```

## 📋 Checklist de Vérification

- [ ] Vérifier les logs de la console
- [ ] Identifier les clés disponibles dans SharedPreferences
- [ ] Vérifier le code de connexion OTP
- [ ] Tester avec le bouton "Simuler numéro de test"
- [ ] Corriger la sauvegarde dans la connexion OTP
- [ ] Vérifier que le numéro est récupéré correctement

## 🎯 Prochaines Étapes

1. **Lancer l'application** et vérifier les logs
2. **Identifier la clé** utilisée pour sauvegarder le numéro
3. **Corriger la connexion OTP** si nécessaire
4. **Tester le processus complet** : Connexion → Inscription

## 📝 Notes Importantes

- **SharedPreferences** : Fonctionne correctement
- **Récupération** : La méthode fonctionne si le numéro est sauvegardé
- **Problème principal** : La connexion OTP ne sauvegarde pas le numéro
- **Solution temporaire** : Utiliser le bouton de test pour vérifier le fonctionnement

## 🔄 Code de Test pour la Connexion OTP

Pour tester la sauvegarde du numéro, ajoutez ce code dans la connexion OTP :

```dart
// Après validation de l'OTP
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_phone', phoneNumber);
print('📱 Numéro sauvegardé: $phoneNumber');

// Vérifier la sauvegarde
final savedPhone = prefs.getString('user_phone');
print('📱 Numéro vérifié: $savedPhone');
```
