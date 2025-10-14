# Guide de Déploiement - Fonctionnalité Vocalises Hors Ligne

## Prérequis

### Backend (Laravel)
- PHP 8.1+
- Composer
- Laravel 10+
- Base de données (MySQL/SQLite)
- Serveur web (Apache/Nginx)

### Frontend (Flutter)
- Flutter 3.3.1+
- Dart SDK
- Android Studio / Xcode
- Émulateur ou appareil physique

## Installation Backend

### 1. Configuration de la base de données
```bash
cd /path/to/voxbobackend
php artisan migrate
php artisan db:seed
```

### 2. Configuration des permissions
```bash
chmod -R 775 storage/
chmod -R 775 bootstrap/cache/
```

### 3. Génération de la clé d'application
```bash
php artisan key:generate
```

### 4. Configuration des fichiers de stockage
```bash
php artisan storage:link
```

### 5. Test des endpoints
```bash
php test_vocalise_api.php
```

## Installation Frontend

### 1. Installation des dépendances
```bash
cd /path/to/voxbox
flutter pub get
```

### 2. Configuration de l'URL du backend
Modifiez `lib/functions/appconstants.dart` :
```dart
static String baseURL = 'http://VOTRE_IP:8000';
```

### 3. Compilation et test
```bash
# Android
flutter build apk --debug

# iOS
flutter build ios --debug
```

## Configuration Réseau

### Pour les tests locaux
1. **Android Emulator** : Utilisez `http://10.0.2.2:8000`
2. **iOS Simulator** : Utilisez `http://localhost:8000`
3. **Appareil physique** : Utilisez l'IP locale de votre machine

### Pour la production
1. Configurez un domaine ou une IP publique
2. Activez HTTPS pour la sécurité
3. Configurez les certificats SSL

## Tests de Fonctionnalité

### 1. Test de connectivité
- [ ] L'application se connecte au backend
- [ ] L'authentification fonctionne
- [ ] Les vocalises se chargent correctement

### 2. Test de synchronisation
- [ ] Synchronisation automatique au démarrage
- [ ] Synchronisation manuelle avec le bouton refresh
- [ ] Synchronisation incrémentale

### 3. Test hors ligne
- [ ] Désactivez le WiFi/Données mobiles
- [ ] Vérifiez que l'indicateur "Mode hors ligne" s'affiche
- [ ] Vérifiez que les vocalises locales sont accessibles
- [ ] Testez le téléchargement de fichiers audio

### 4. Test de téléchargement
- [ ] Téléchargez un fichier audio
- [ ] Vérifiez qu'il est stocké localement
- [ ] Testez la lecture hors ligne
- [ ] Testez la suppression du fichier

## Dépannage

### Problèmes Backend
1. **Erreur 500** : Vérifiez les logs Laravel
2. **Erreur de base de données** : Vérifiez les migrations
3. **Erreur de permissions** : Vérifiez les permissions des dossiers

### Problèmes Frontend
1. **Erreur de connexion** : Vérifiez l'URL du backend
2. **Erreur de compilation** : Vérifiez les dépendances
3. **Erreur de permissions** : Vérifiez les permissions Android/iOS

### Logs utiles
```bash
# Backend
tail -f storage/logs/laravel.log

# Frontend (Android)
adb logcat | grep flutter

# Frontend (iOS)
# Utilisez Xcode Console
```

## Optimisations

### Backend
1. **Cache** : Activez le cache Laravel
2. **Compression** : Activez la compression Gzip
3. **CDN** : Utilisez un CDN pour les fichiers audio

### Frontend
1. **Images** : Optimisez les images
2. **Code splitting** : Divisez le code en chunks
3. **Lazy loading** : Chargez les données à la demande

## Sécurité

### Backend
1. **HTTPS** : Utilisez toujours HTTPS en production
2. **CORS** : Configurez CORS correctement
3. **Rate limiting** : Limitez les requêtes par IP
4. **Validation** : Validez toutes les entrées

### Frontend
1. **Certificats** : Utilisez des certificats valides
2. **Stockage** : Chiffrez les données sensibles
3. **Permissions** : Demandez seulement les permissions nécessaires

## Monitoring

### Métriques importantes
1. **Temps de réponse** de l'API
2. **Taux d'erreur** des requêtes
3. **Utilisation de l'espace disque** pour les fichiers audio
4. **Temps de synchronisation**

### Outils recommandés
1. **Laravel Telescope** pour le debugging
2. **Sentry** pour le monitoring des erreurs
3. **Google Analytics** pour l'usage
4. **Firebase Analytics** pour les métriques mobiles

## Maintenance

### Tâches régulières
1. **Nettoyage** des fichiers audio orphelins
2. **Sauvegarde** de la base de données
3. **Mise à jour** des dépendances
4. **Monitoring** des performances

### Scripts utiles
```bash
# Nettoyage des fichiers audio
php artisan vocalise:cleanup

# Sauvegarde de la base de données
php artisan backup:run

# Mise à jour des dépendances
composer update
flutter pub upgrade
```

## Support

### Documentation
- [Laravel Documentation](https://laravel.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [API Documentation](./FONCTIONNALITE_HORS_LIGNE.md)

### Contact
- Email : support@voxbox.com
- GitHub : [Repository Issues](https://github.com/your-repo/issues)
- Documentation : [Wiki du projet](https://github.com/your-repo/wiki)
