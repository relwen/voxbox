# Guide d'utilisation du ToastService

## Vue d'ensemble

Le `ToastService` utilise le package `toastification` pour afficher des messages toast modernes et élégants en haut de l'écran, similaire à Toastify.

## Installation

Le package `toastification` est déjà installé dans `pubspec.yaml`:
```yaml
dependencies:
  toastification: ^1.0.0
```

## Import

```dart
import 'package:voxbox/services/toast_service.dart';
```

## Utilisation

### 1. Toast de Succès

```dart
// Simple
ToastService.success(context, 'Opération réussie !');

// Avec titre
ToastService.success(
  context,
  'Votre profil a été mis à jour avec succès',
  title: 'Succès',
);

// Avec durée personnalisée
ToastService.success(
  context,
  'Fichier téléchargé',
  duration: Duration(seconds: 5),
);
```

### 2. Toast d'Erreur

```dart
// Simple
ToastService.error(context, 'Une erreur est survenue');

// Avec titre
ToastService.error(
  context,
  'Impossible de se connecter au serveur',
  title: 'Erreur',
);

// Position personnalisée (en haut au centre)
ToastService.error(
  context,
  'Veuillez remplir tous les champs',
  alignment: Alignment.topCenter,
);
```

### 3. Toast d'Avertissement

```dart
ToastService.warning(
  context,
  'Votre session expire dans 5 minutes',
  title: 'Attention',
);
```

### 4. Toast d'Information

```dart
ToastService.info(
  context,
  'Nouvelle mise à jour disponible',
  title: 'Info',
);
```

### 5. Toast de Chargement

```dart
// Afficher le toast de chargement
final loadingToast = ToastService.loading(
  context,
  'Téléchargement en cours...',
);

// Plus tard, après l'opération
ToastService.dismiss(loadingToast);
ToastService.success(context, 'Téléchargement terminé !');
```

### 6. Toast Personnalisé

```dart
ToastService.custom(
  context,
  'Nouvelle vocalise ajoutée',
  title: 'Bibliothèque',
  icon: Icons.library_music,
  color: Colors.purple,
);
```

## Remplacement des SnackBars

### Avant (SnackBar)

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Veuillez saisir votre numéro'),
    backgroundColor: Colors.orange,
  ),
);
```

### Après (ToastService)

```dart
ToastService.warning(
  context,
  'Veuillez saisir votre numéro',
);
```

## Exemples dans différents contextes

### Authentification (login.dart)

```dart
// Avant
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  content: Text('Veuillez saisir votre numéro de téléphone'),
  backgroundColor: Colors.orange,
));

// Après
ToastService.warning(
  context,
  'Veuillez saisir votre numéro de téléphone',
);

// Succès de connexion
ToastService.success(
  context,
  'Connexion réussie !',
  title: 'Bienvenue',
);

// Erreur de connexion
ToastService.error(
  context,
  'Numéro de téléphone invalide',
  title: 'Erreur',
);
```

### Téléchargement de fichiers

```dart
// Démarrer le téléchargement
final loadingToast = ToastService.loading(
  context,
  'Téléchargement du fichier audio...',
);

try {
  // ... logique de téléchargement
  await downloadFile();

  // Fermer le toast de chargement
  ToastService.dismiss(loadingToast);

  // Afficher le succès
  ToastService.success(
    context,
    'Fichier téléchargé avec succès',
    title: 'Téléchargement',
  );
} catch (e) {
  // Fermer le toast de chargement
  ToastService.dismiss(loadingToast);

  // Afficher l'erreur
  ToastService.error(
    context,
    'Échec du téléchargement',
    title: 'Erreur',
  );
}
```

### Formulaires

```dart
void _submitForm() {
  if (_formKey.currentState?.validate() ?? false) {
    // Formulaire valide
    ToastService.success(
      context,
      'Vocalise créée avec succès',
    );
  } else {
    // Formulaire invalide
    ToastService.warning(
      context,
      'Veuillez remplir tous les champs requis',
    );
  }
}
```

### Synchronisation

```dart
Future<void> syncData() async {
  final loadingToast = ToastService.loading(
    context,
    'Synchronisation en cours...',
  );

  try {
    await VocaliseService.syncVocalises();

    ToastService.dismiss(loadingToast);
    ToastService.success(
      context,
      'Données synchronisées',
      title: 'Synchronisation',
    );
  } catch (e) {
    ToastService.dismiss(loadingToast);
    ToastService.error(
      context,
      'Erreur de synchronisation',
      title: 'Erreur',
    );
  }
}
```

## Positions disponibles

```dart
// En haut à droite (par défaut)
alignment: Alignment.topRight

// En haut au centre
alignment: Alignment.topCenter

// En haut à gauche
alignment: Alignment.topLeft

// En bas à droite
alignment: Alignment.bottomRight

// En bas au centre
alignment: Alignment.bottomCenter

// En bas à gauche
alignment: Alignment.bottomLeft

// Au centre
alignment: Alignment.center
```

## Caractéristiques

✅ **Animations fluides** : Slide et fade pour une entrée/sortie élégante
✅ **Personnalisable** : Couleurs, icônes, positions personnalisables
✅ **Barre de progression** : Indique visuellement le temps restant
✅ **Glisser pour fermer** : L'utilisateur peut glisser pour fermer
✅ **Pause au survol** : Le timer se met en pause quand la souris est dessus
✅ **Responsive** : S'adapte à tous les types d'écrans
✅ **Ombres modernes** : Apparence professionnelle avec des ombres douces
✅ **Coins arrondis** : Design moderne et épuré

## Fermeture des toasts

```dart
// Fermer tous les toasts
ToastService.dismissAll();

// Fermer un toast spécifique
final toast = ToastService.info(context, 'Message');
ToastService.dismiss(toast);
```

## Configuration du main.dart

Pour utiliser toastification, assurez-vous d'envelopper votre app avec `ToastificationWrapper`:

```dart
import 'package:toastification/toastification.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        // ... votre configuration
      ),
    );
  }
}
```

## Migration rapide

Utilisez cette regex pour trouver et remplacer les SnackBars :

**Rechercher** :
```
ScaffoldMessenger\.of\(context\)\.showSnackBar\(.*SnackBar\(
```

**Remplacer par** :
```dart
ToastService.info(context, "Votre message ici");
// ou
ToastService.success(context, "Votre message ici");
// ou
ToastService.error(context, "Votre message ici");
// ou
ToastService.warning(context, "Votre message ici");
```

## Bonnes Pratiques

1. **Utilisez les bons types** :
   - `success` pour les opérations réussies
   - `error` pour les erreurs
   - `warning` pour les avertissements
   - `info` pour les informations générales
   - `loading` pour les opérations en cours

2. **Durée appropriée** :
   - Messages courts : 2-3 secondes
   - Messages importants : 4-5 secondes
   - Chargement : pas de durée (fermez manuellement)

3. **Messages clairs et concis** :
   ```dart
   // ✅ Bon
   ToastService.success(context, 'Vocalise sauvegardée');

   // ❌ Éviter (trop long)
   ToastService.success(context, 'Votre vocalise a été sauvegardée avec succès dans la base de données et est maintenant disponible pour tous les membres');
   ```

4. **Utilisez les titres pour les messages importants** :
   ```dart
   ToastService.error(
     context,
     'Le serveur ne répond pas',
     title: 'Erreur de connexion',
   );
   ```
