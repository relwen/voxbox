# Fonctionnalité Hors Ligne - Vocalises

## Vue d'ensemble

L'application VoxBox prend en charge le fonctionnement hors ligne pour les exercices vocalises. Cette fonctionnalité permet aux utilisateurs d'accéder à leurs vocalises même sans connexion internet.

## Fonctionnalités

### 1. Synchronisation Automatique
- **Au démarrage** : L'application synchronise automatiquement les vocalises lors du lancement
- **Synchronisation incrémentale** : Seules les nouvelles vocalises ou les modifications sont téléchargées
- **Synchronisation manuelle** : Bouton de rafraîchissement disponible dans l'interface

### 2. Stockage Local
- **Données** : Les métadonnées des vocalises sont stockées localement avec SharedPreferences
- **Fichiers audio** : Les fichiers audio peuvent être téléchargés pour un accès hors ligne
- **Gestion intelligente** : L'application gère automatiquement l'espace de stockage

### 3. Mode Hors Ligne
- **Indicateur visuel** : Bandeau orange indiquant le mode hors ligne
- **Accès aux données** : Toutes les vocalises stockées localement restent accessibles
- **Fichiers téléchargés** : Les fichiers audio téléchargés fonctionnent sans internet

## Architecture Technique

### Backend (Laravel)
```
/api/vocalises - Récupérer toutes les vocalises
/api/vocalises/sync - Synchronisation incrémentale
/api/vocalises/{id}/download-audio - Télécharger un fichier audio
```

### Frontend (Flutter)
```
lib/models/vocalise.dart - Modèle de données
lib/services/vocalise_service.dart - Service de gestion
lib/view/vocalize/vocalize.dart - Interface utilisateur
lib/widgets/sync_indicator.dart - Indicateur de synchronisation
```

## Utilisation

### Pour l'utilisateur
1. **Première utilisation** : Connectez-vous à internet pour synchroniser les vocalises
2. **Téléchargement** : Téléchargez les fichiers audio des vocalises importantes
3. **Mode hors ligne** : Utilisez l'application normalement, même sans internet
4. **Synchronisation** : Reconnectez-vous périodiquement pour mettre à jour

### Pour le développeur
1. **Service VocaliseService** : Gère toute la logique de synchronisation
2. **Modèle Vocalise** : Représente une vocalise avec support hors ligne
3. **Interface** : Affiche automatiquement l'état de connectivité
4. **Gestion des erreurs** : Fallback automatique vers les données locales

## Configuration

### Backend
Les endpoints API sont configurés dans `routes/api.php` :
```php
Route::apiResource("vocalises", VocaliseController::class);
Route::get("/vocalises/sync", [VocaliseController::class, "getForSync"]);
Route::get("/vocalises/{id}/download-audio", [VocaliseController::class, "downloadAudio"]);
```

### Frontend
L'URL de base est configurée dans `lib/functions/appconstants.dart` :
```dart
static String baseURL = 'http://192.168.23.143:8000';
static String vocalisesURL = '$baseURL/api/vocalises';
```

## Gestion des Fichiers

### Téléchargement
- Les fichiers audio sont stockés dans le répertoire de documents de l'application
- Structure : `/documents/vocalises/vocalise_{id}.mp3`
- Gestion automatique des permissions et de l'espace disque

### Nettoyage
- Fonction `cleanupDownloadedAudios()` pour supprimer les fichiers orphelins
- Gestion intelligente de l'espace de stockage
- Possibilité de supprimer manuellement les fichiers téléchargés

## États de l'Application

### Connecté
- ✅ Synchronisation automatique
- ✅ Téléchargement de nouveaux fichiers
- ✅ Mise à jour des données
- ✅ Indicateur vert "Connecté"

### Hors Ligne
- ⚠️ Accès aux données locales uniquement
- ⚠️ Pas de téléchargement de nouveaux fichiers
- ⚠️ Indicateur orange "Mode hors ligne"
- ✅ Fonctionnement normal avec les données existantes

## Dépannage

### Problèmes Courants
1. **Pas de vocalises** : Vérifiez la connexion et synchronisez manuellement
2. **Fichiers audio manquants** : Téléchargez les fichiers en mode connecté
3. **Erreurs de synchronisation** : Vérifiez l'URL du backend et les permissions

### Logs
Les erreurs sont loggées dans la console pour le débogage :
```dart
print('Erreur de synchronisation des vocalises: $e');
```

## Sécurité

- Authentification requise pour toutes les opérations
- Token Bearer pour l'autorisation
- Validation des fichiers téléchargés
- Gestion sécurisée du stockage local

## Performance

- Synchronisation incrémentale pour réduire la bande passante
- Cache local pour un accès rapide
- Téléchargement asynchrone des fichiers audio
- Gestion optimisée de la mémoire
