# VoXY Backend API

Backend Laravel pour l'application VoXY - Gestion des chorales et partitions musicales.

## 🚀 Installation

1. **Cloner le projet**
```bash
git clone <repository-url>
cd voxbox-backend
```

2. **Installer les dépendances**
```bash
composer install
```

3. **Configurer l'environnement**
```bash
cp .env.example .env
php artisan key:generate
```

4. **Configurer la base de données**
```bash
# Modifier le fichier .env avec vos paramètres de base de données
php artisan migrate
php artisan db:seed
```

5. **Créer le lien de stockage**
```bash
php artisan storage:link
```

6. **Démarrer le serveur**
```bash
php artisan serve
```

## 📋 Fonctionnalités

### 🔐 Authentification
- **Inscription** : Création de compte utilisateur avec validation par administrateur
- **Connexion** : Authentification avec tokens Sanctum
- **Gestion des rôles** : Utilisateur normal et administrateur

### 👥 Gestion des Utilisateurs
- **Inscription** : Nom, email, mot de passe, chorale, pupitre, téléphone
- **Validation** : Approbation/rejet par l'administrateur
- **Pupitres** : SOPRANE, TENOR, MEZOSOPRANE, ALTO, BASSE, BARITON

### 🎵 Gestion des Partitions
- **Upload d'images** : Photos de partitions (max 10MB)
- **Génération PDF** : Conversion automatique des images en PDF
- **Partitions écrites** : Texte des partitions
- **Partitions musicales** : Notation musicale
- **Synchronisation** : Fonctionnement hors ligne avec sync

### 🎤 Gestion des Voix
- **Partitions par pupitre** : Partition spécifique à chaque voix
- **Partitions musique** : Partition musicale par voix
- **Fichiers audio** : Upload d'audio pour chaque voix
- **Mise en commun** : Voix pour la pratique collective

### ⛪ Gestion des Chorales
- **Création** : Nom, description, localisation, contact
- **Membres** : Gestion des utilisateurs par chorale
- **Statistiques** : Nombre de membres, partitions, etc.

## 🔌 API Endpoints

### Authentification
```
POST /api/register          # Inscription utilisateur
POST /api/login             # Connexion
POST /api/logout            # Déconnexion
GET  /api/me                # Profil utilisateur
GET  /api/chorales          # Liste des chorales (public)
```

### Administration (Admin uniquement)
```
GET  /api/admin/pending-users     # Utilisateurs en attente
POST /api/admin/approve-user/{id} # Approuver utilisateur
POST /api/admin/reject-user/{id}  # Rejeter utilisateur
GET  /api/admin/users             # Tous les utilisateurs
GET  /api/admin/stats             # Statistiques dashboard
POST /api/admin/make-admin/{id}   # Promouvoir admin
POST /api/admin/remove-admin/{id} # Retirer admin
```

### Chorales
```
GET    /api/chorales              # Liste des chorales
POST   /api/chorales              # Créer une chorale
GET    /api/chorales/{id}         # Détails d'une chorale
PUT    /api/chorales/{id}         # Modifier une chorale
DELETE /api/chorales/{id}         # Supprimer une chorale
GET    /api/chorales/{id}/stats   # Statistiques chorale
GET    /api/chorales/{id}/users   # Utilisateurs de la chorale
GET    /api/chorales/{id}/partitions # Partitions de la chorale
```

### Partitions
```
GET    /api/partitions                    # Partitions de la chorale
POST   /api/partitions                    # Créer une partition
GET    /api/partitions/{id}               # Détails d'une partition
PUT    /api/partitions/{id}               # Modifier une partition
DELETE /api/partitions/{id}               # Supprimer une partition
GET    /api/partitions/{id}/download-pdf  # Télécharger PDF
GET    /api/partitions/sync               # Synchronisation hors ligne
```

### Voix
```
GET    /api/voice-parts                   # Voix de la chorale
POST   /api/voice-parts                   # Créer une voix
GET    /api/voice-parts/{id}              # Détails d'une voix
PUT    /api/voice-parts/{id}              # Modifier une voix
DELETE /api/voice-parts/{id}              # Supprimer une voix
PUT    /api/voice-parts/{id}/partition-voix    # Partition voix
PUT    /api/voice-parts/{id}/partition-musique # Partition musique
POST   /api/voice-parts/{id}/upload-audio      # Upload audio
```

## 📊 Structure de la Base de Données

### Tables principales
- **users** : Utilisateurs avec chorale_id, pupitre, is_approved, is_admin
- **chorales** : Chorales avec nom, description, localisation
- **partitions** : Partitions avec image_path, pdf_path, partition_ecrite, partition_musicale
- **voice_parts** : Voix par partition avec pupitre, partition_voix, partition_musique, audio_path

## 🔧 Configuration

### Variables d'environnement importantes
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=voxy_backend
DB_USERNAME=root
DB_PASSWORD=

FILESYSTEM_DISK=public
```

### Stockage
- **Images** : `storage/app/public/partitions/images/`
- **PDFs** : `storage/app/public/partitions/pdfs/`
- **Audio** : `storage/app/public/voice-parts/audio/`

## 🧪 Tests

### Compte administrateur par défaut
```
Email: admin@voxy.com
Mot de passe: admin123
```

### Exemple d'inscription utilisateur
```json
{
  "name": "Jean Dupont",
  "email": "jean.dupont@example.com",
  "password": "motdepasse123",
  "password_confirmation": "motdepasse123",
  "chorale_id": 1,
  "pupitre": "BASSE",
  "telephone": "+33 1 23 45 67 89"
}
```

## 🔒 Sécurité

- **Authentification** : Laravel Sanctum
- **Validation** : Règles de validation strictes
- **Autorisation** : Middleware admin pour les routes protégées
- **Fichiers** : Validation des types et tailles de fichiers
- **CORS** : Configuration pour l'application mobile

## 📱 Synchronisation Hors Ligne

L'API supporte la synchronisation pour permettre l'utilisation hors ligne :
- **Sync timestamp** : Suivi des modifications
- **Dernière sync** : Paramètre pour récupérer les nouvelles données
- **Stockage local** : L'application mobile stocke les données localement

## 🚀 Déploiement

1. **Production** : Configurer les variables d'environnement
2. **Base de données** : Migrations et seeders
3. **Stockage** : Lien symbolique pour les fichiers publics
4. **Permissions** : Droits d'écriture pour le stockage

## 📞 Support

Pour toute question ou problème, contactez l'équipe de développement VoXY.
