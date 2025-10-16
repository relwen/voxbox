# Guide de Débogage - Récupération des Chorales

## ✅ Problèmes Identifiés et Corrigés

### 1. **URL Backend Incorrecte**
- **Problème** : L'URL était `http://192.168.11.107:8000` au lieu de `http://localhost:8000`
- **Solution** : Corrigé dans `appconstants.dart`
- **Statut** : ✅ Corrigé

### 2. **Incompatibilité des Champs**
- **Problème** : Le modèle Flutter utilisait `nom` et `ville` mais le backend retourne `name` et `location`
- **Solution** : Modifié le modèle `Chorale` pour supporter les deux formats
- **Statut** : ✅ Corrigé

### 3. **Logs de Débogage Ajoutés**
- **Ajouté** : Logs détaillés dans `ChoraleService` et `ChoraleSelector`
- **Statut** : ✅ Ajouté

## 🔧 Modifications Apportées

### **appconstants.dart**
```dart
// Avant
static String baseURL = 'http://192.168.11.107:8000';

// Après
static String baseURL = 'http://localhost:8000';
```

### **models/chorale.dart**
```dart
// Avant
nom: json['nom'],
ville: json['ville'],

// Après
nom: json['name'] ?? json['nom'], // Support des deux formats
ville: json['location'] ?? json['ville'], // Support des deux formats
```

### **services/chorale_service.dart**
```dart
// Ajout de logs détaillés
print('📡 Réponse API chorales: ${response.body}');
print('🔄 Conversion chorale: $json');
print('✅ Chorales converties: ${chorales.length} chorales');
```

### **widgets/chorale_selector.dart**
```dart
// Ajout de logs de débogage
print('🔄 Début du chargement des chorales...');
print('📡 Réponse reçue: error=${response.error}, data=${response.data}');
```

## 🧪 Tests de Vérification

### **Test Backend (Réussi)**
```bash
php test_chorales_complet.php
```
**Résultat** : ✅ 4 chorales récupérées avec structure correcte

### **Test Connexion Mobile (Réussi)**
```bash
php test_mobile_connection.php
```
**Résultat** : ✅ Connexion réussie avec localhost:8000

## 📱 Comment Tester dans l'Application

### **1. Vérifier les Logs**
Lancez l'application et ouvrez la page d'inscription. Dans la console, vous devriez voir :

```
🔄 Chargement des chorales depuis l'API...
🔄 Début du chargement des chorales...
📡 Réponse API chorales: {"success":true,"data":[...]}
🔄 Conversion chorale: {"id":1,"name":"Chorale Saint-Michel",...}
✅ Chorales converties: 4 chorales
   - Chorale Saint-Michel (Paris, France)
   - Ensemble Vocal de Lyon (Lyon, France)
   - Chorale Universitaire (Marseille, France)
   - Voix d'Or (Toulouse, France)
📡 Réponse reçue: error=null, data=[Chorale, Chorale, Chorale, Chorale]
✅ Chorales chargées depuis la BD: 4 chorales
```

### **2. Vérifier l'Affichage**
- Cliquez sur le champ "Chorale" dans le formulaire d'inscription
- Vous devriez voir une liste déroulante avec 4 chorales
- Les chorales devraient s'afficher avec leur nom et localisation

### **3. Vérifier la Recherche**
- Tapez "Saint" dans le champ de recherche
- Vous devriez voir "Chorale Saint-Michel" filtrée

## 🚨 Dépannage

### **Si les chorales ne s'affichent toujours pas :**

1. **Vérifier les logs de la console**
   - Cherchez les messages de débogage
   - Identifiez où le processus s'arrête

2. **Vérifier la connexion réseau**
   ```bash
   # Tester depuis l'émulateur/simulateur
   curl http://localhost:8000/api/chorales
   ```

3. **Vérifier les permissions réseau**
   - iOS : Vérifier `Info.plist` pour les permissions réseau
   - Android : Vérifier `android/app/src/main/AndroidManifest.xml`

4. **Vérifier le cache**
   ```bash
   flutter clean
   flutter pub get
   ```

### **Messages d'Erreur Courants**

#### **"Connection refused"**
- Le serveur Laravel n'est pas démarré
- **Solution** : `php artisan serve` dans le répertoire backend

#### **"Format de réponse incorrect"**
- Le backend retourne un format différent
- **Solution** : Vérifier la structure de la réponse API

#### **"Champs manquants"**
- Le modèle Flutter ne correspond pas aux données
- **Solution** : Vérifier le mapping dans `fromJson()`

## 📋 Checklist de Vérification

- [ ] Serveur Laravel démarré (`php artisan serve`)
- [ ] URL correcte dans `appconstants.dart` (`http://localhost:8000`)
- [ ] Modèle `Chorale` compatible avec les données backend
- [ ] Logs de débogage visibles dans la console
- [ ] Chorales s'affichent dans le sélecteur
- [ ] Recherche de chorales fonctionne
- [ ] Sélection de chorale fonctionne

## 🎯 Prochaines Étapes

1. **Tester l'application** avec les modifications
2. **Vérifier les logs** pour confirmer le bon fonctionnement
3. **Supprimer les logs de débogage** une fois que tout fonctionne
4. **Tester sur différents appareils** (iOS/Android)

## 📝 Notes Importantes

- **Backend** : Fonctionne correctement sur `localhost:8000`
- **Données** : 4 chorales disponibles avec structure correcte
- **Compatibilité** : Modèle Flutter mis à jour pour correspondre au backend
- **Logs** : Ajoutés temporairement pour le débogage
