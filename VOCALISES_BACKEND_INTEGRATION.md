# Intégration Backend pour les Vocalises avec Sous-dossiers

## Vue d'ensemble

Les vocalises utilisent maintenant le même système que les messes pour gérer les fichiers organisés par sous-dossiers (pupitres). Le backend gère automatiquement l'organisation des fichiers selon la configuration des sous-dossiers.

## Architecture

### 1. BackendAdapter

Le `BackendAdapter` a été étendu pour supporter les vocalises avec les mêmes fonctionnalités que les messes :

```dart
// Conversion des données backend vers Vocalise
BackendAdapter.backendDataToVocalise(Map<String, dynamic> vocaliseData)

// Conversion d'une liste
BackendAdapter.backendDataListToVocalises(List<dynamic> vocalisesData)
```

#### Fonctionnalités du BackendAdapter pour Vocalises

- **Support multi-fichiers** : Gère les listes de fichiers audio, PDF et images
- **Organisation par pupitre** : Supporte soprano, alto, ténor, basse et tutti
- **Système unifié** : Utilise le champ `files` avec métadonnées ou les anciens champs séparés
- **Rétrocompatibilité** : Supporte l'ancien format avec `audio_path`, `audio_files`, etc.

### 2. Format des Données Backend

Le backend peut retourner les données dans deux formats :

#### Format Unifié (Recommandé)

```json
{
  "id": 1,
  "title": "Vocalise Do Majeur",
  "files": [
    {
      "path": "vocalises/soprano/do_majeur.mp3",
      "name": "do_majeur.mp3",
      "type": "audio",
      "pupitre": "soprano"
    },
    {
      "path": "vocalises/alto/do_majeur.mp3",
      "type": "audio",
      "pupitre": "alto"
    },
    {
      "path": "vocalises/partition.pdf",
      "type": "pdf"
    }
  ]
}
```

#### Format Séparé (Rétrocompatible)

```json
{
  "id": 1,
  "title": "Vocalise Do Majeur",
  "audio_files": ["vocalises/audio1.mp3", "vocalises/audio2.mp3"],
  "pdf_files": ["vocalises/partition.pdf"],
  "soprano_files": ["vocalises/soprano/do_majeur.mp3"],
  "alto_files": ["vocalises/alto/do_majeur.mp3"],
  "tenor_files": ["vocalises/tenor/do_majeur.mp3"],
  "basse_files": ["vocalises/basse/do_majeur.mp3"],
  "tutti_files": ["vocalises/tutti/do_majeur.mp3"]
}
```

### 3. VocaliseService

Le `VocaliseService` utilise maintenant le `BackendAdapter` pour convertir les données :

```dart
// Récupération depuis le serveur
List<Vocalise> vocalises = BackendAdapter.backendDataListToVocalises(responseData['data']);
```

#### Méthodes Mises à Jour

- `getVocalisesFromServer()` : Utilise l'adaptateur pour la conversion
- `syncVocalises()` : Synchronisation incrémentale avec l'adaptateur
- Les deux méthodes gèrent automatiquement les fichiers organisés par pupitre

### 4. SearchService

Le service de recherche est compatible avec les sous-dossiers :

```dart
// La recherche retourne automatiquement les fichiers organisés
searchVocalises(String query)
```

## Modèle Vocalise

Le modèle `Vocalise` supporte :

### Fichiers Globaux
- `audioFiles` : Liste de tous les fichiers audio
- `pdfFiles` : Liste de tous les fichiers PDF
- `imageFiles` : Liste de tous les fichiers images

### Fichiers par Pupitre
- `sopranoFiles` : Fichiers spécifiques au pupitre Soprano
- `altoFiles` : Fichiers spécifiques au pupitre Alto
- `tenorFiles` : Fichiers spécifiques au pupitre Ténor
- `basseFiles` : Fichiers spécifiques au pupitre Basse
- `tuttiFiles` : Fichiers pour tous les pupitres

### URLs Générées Automatiquement
```dart
vocalise.sopranoUrls  // URLs complètes pour les fichiers Soprano
vocalise.altoUrls     // URLs complètes pour les fichiers Alto
vocalise.tenorUrls    // URLs complètes pour les fichiers Ténor
vocalise.basseUrls    // URLs complètes pour les fichiers Basse
vocalise.tuttiUrls    // URLs complètes pour les fichiers Tutti
```

## Flux de Données

```
Backend API
    ↓
VocaliseService (avec BackendAdapter)
    ↓
Conversion des données avec organisation par sous-dossiers
    ↓
Modèle Vocalise avec fichiers organisés par pupitre
    ↓
Stockage Local (SharedPreferences)
    ↓
UI (accès aux fichiers selon le pupitre de l'utilisateur)
```

## Avantages

1. **Cohérence** : Même système que les messes
2. **Flexibilité** : Support de plusieurs formats de données backend
3. **Organisation** : Fichiers automatiquement organisés par pupitre
4. **Rétrocompatibilité** : Support de l'ancien format
5. **Maintenance** : Code centralisé dans le BackendAdapter

## Configuration Backend Requise

Le backend doit :

1. Organiser les fichiers dans des sous-dossiers par pupitre
2. Retourner les chemins des fichiers dans le format approprié
3. Supporter l'endpoint de recherche avec les fichiers organisés
4. Gérer la synchronisation incrémentale

## Exemple d'Utilisation dans l'UI

```dart
// Récupérer les fichiers selon le pupitre de l'utilisateur
String userPupitre = 'soprano';
List<String> files;

switch (userPupitre.toLowerCase()) {
  case 'soprano':
    files = vocalise.sopranoFiles ?? vocalise.audioFiles ?? [];
    break;
  case 'alto':
    files = vocalise.altoFiles ?? vocalise.audioFiles ?? [];
    break;
  case 'tenor':
  case 'ténor':
    files = vocalise.tenorFiles ?? vocalise.audioFiles ?? [];
    break;
  case 'basse':
    files = vocalise.basseFiles ?? vocalise.audioFiles ?? [];
    break;
  case 'tutti':
    files = vocalise.tuttiFiles ?? vocalise.audioFiles ?? [];
    break;
  default:
    files = vocalise.audioFiles ?? [];
}

// Utiliser les URLs complètes
List<String> urls = vocalise.sopranoUrls;
```

## Tests Recommandés

1. Tester avec le format unifié (champ `files`)
2. Tester avec le format séparé (champs `soprano_files`, etc.)
3. Vérifier la rétrocompatibilité avec l'ancien format
4. Tester la synchronisation incrémentale
5. Vérifier la recherche avec fichiers organisés
6. Tester le téléchargement des fichiers par pupitre

## Fichiers Modifiés

1. `lib/services/backend_adapter.dart` - Ajout des méthodes pour Vocalise
2. `lib/services/vocalise_service.dart` - Utilisation du BackendAdapter
3. `lib/services/search_service.dart` - Support des sous-dossiers
4. `lib/models/vocalise.dart` - Déjà compatible (inchangé)

## Notes Importantes

- Le backend doit retourner `success: true` dans la réponse
- Les fichiers peuvent être organisés automatiquement par le backend selon la configuration des sous-dossiers
- La conversion gère automatiquement les différents formats de données
- Les URLs sont générées automatiquement à partir du `baseURL` configuré
