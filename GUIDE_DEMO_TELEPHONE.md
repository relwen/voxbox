# Guide de Démo sur Téléphone

## Configuration Actuelle

### ✅ Serveur Backend
- **URL** : `http://192.168.11.104:8001`
- **Port** : 8001
- **Statut** : ✅ Fonctionnel

### ✅ Application Flutter
- **URL configurée** : `http://192.168.11.104:8001`
- **Endpoints** : Tous accessibles
- **Authentification** : Activée

## Étapes pour la Démo

### 1. Vérifier la Connexion Réseau
- ✅ Votre téléphone et votre ordinateur doivent être sur le même réseau WiFi
- ✅ IP de votre ordinateur : `192.168.11.104`
- ✅ Port du serveur : `8001`

### 2. Tester la Connexion
```bash
# Sur votre ordinateur, testez d'abord :
php test_connection.php
```

**Résultat attendu** :
```
✓ Serveur accessible (Code: 401)
✓ Endpoint vocalises accessible (Code: 401)
✓ Authentification requise (comportement attendu)
```

### 3. Lancer l'Application sur Téléphone
```bash
# Compiler et installer sur votre téléphone
flutter run --release
```

### 4. Scénario de Démo

#### Étape 1 : Connexion
1. Ouvrez l'application sur votre téléphone
2. Connectez-vous avec vos identifiants
3. Vérifiez que la synchronisation se fait automatiquement

#### Étape 2 : Mode Connecté
1. Allez dans la section "Vocalises"
2. Vérifiez que les vocalises se chargent
3. Téléchargez quelques fichiers audio
4. Testez la lecture des vocalises

#### Étape 3 : Mode Hors Ligne
1. Désactivez le WiFi sur votre téléphone
2. Vérifiez que l'indicateur "Mode hors ligne" s'affiche
3. Testez l'accès aux vocalises téléchargées
4. Vérifiez que les fichiers audio fonctionnent

#### Étape 4 : Synchronisation
1. Réactivez le WiFi
2. Appuyez sur le bouton de synchronisation
3. Vérifiez que les nouvelles données se chargent

## Points Clés de la Démo

### ✅ Fonctionnalités à Montrer
1. **Synchronisation automatique** au démarrage
2. **Téléchargement de fichiers audio** pour usage hors ligne
3. **Mode hors ligne** avec accès aux données locales
4. **Indicateur de connectivité** en temps réel
5. **Synchronisation manuelle** avec le bouton refresh

### 🎯 Messages Clés
- "L'application fonctionne même sans internet"
- "Les vocalises sont synchronisées automatiquement"
- "Vous pouvez télécharger les exercices pour les utiliser hors ligne"
- "La synchronisation est intelligente et incrémentale"

## Dépannage

### Si l'application ne se connecte pas :
1. Vérifiez que votre téléphone est sur le même WiFi
2. Vérifiez que le serveur fonctionne : `php test_connection.php`
3. Vérifiez l'IP dans `lib/functions/appconstants.dart`

### Si la synchronisation échoue :
1. Vérifiez votre connexion internet
2. Vérifiez que vous êtes connecté à l'application
3. Testez la synchronisation manuelle

### Si les fichiers audio ne se téléchargent pas :
1. Vérifiez les permissions de stockage
2. Vérifiez l'espace disque disponible
3. Testez avec un fichier plus petit

## Configuration de Production

Pour une démo en production, vous devrez :
1. **Changer l'IP** vers une IP publique ou un domaine
2. **Activer HTTPS** pour la sécurité
3. **Configurer un serveur web** (Apache/Nginx)
4. **Optimiser les performances** pour la production

## URLs de Test

- **Backend** : `http://192.168.11.104:8001`
- **API Chorales** : `http://192.168.11.104:8001/api/chorales`
- **API Vocalises** : `http://192.168.11.104:8001/api/vocalises`
- **API Sync** : `http://192.168.11.104:8001/api/vocalises/sync`

Votre démo est prête ! 🎉
