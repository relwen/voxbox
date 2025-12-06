# Exemple de Migration vers ToastService

## Fichier : login.dart

### AVANT (avec SnackBar)

```dart
void sendOTP() async {
  if (phoneController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez saisir votre numéro de téléphone'),
        backgroundColor: Colors.orange));
    return;
  }

  setState(() {
    loading = true;
  });

  final fullPhoneNumber = selectedCountryCode + phoneController.text;

  final response = await AuthService.requestOTP(fullPhoneNumber);

  setState(() {
    loading = false;
  });

  if (response.error == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code OTP envoyé au $fullPhoneNumber'),
      backgroundColor: Colors.green,
    ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(phoneNumber: fullPhoneNumber),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.error ?? 'Erreur lors de l\'envoi du code'),
      backgroundColor: Colors.red,
    ));
  }
}
```

### APRÈS (avec ToastService)

```dart
import 'package:voxbox/services/toast_service.dart'; // Ajouter cet import

void sendOTP() async {
  // Validation
  if (phoneController.text.isEmpty) {
    ToastService.warning(
      context,
      'Veuillez saisir votre numéro de téléphone',
    );
    return;
  }

  setState(() {
    loading = true;
  });

  final fullPhoneNumber = selectedCountryCode + phoneController.text;

  // Afficher le toast de chargement
  final loadingToast = ToastService.loading(
    context,
    'Envoi du code OTP...',
  );

  final response = await AuthService.requestOTP(fullPhoneNumber);

  setState(() {
    loading = false;
  });

  // Fermer le toast de chargement
  ToastService.dismiss(loadingToast);

  if (response.error == null) {
    // Succès
    ToastService.success(
      context,
      'Code OTP envoyé au $fullPhoneNumber',
      title: 'Succès',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPScreen(phoneNumber: fullPhoneNumber),
      ),
    );
  } else {
    // Erreur
    ToastService.error(
      context,
      response.error ?? 'Erreur lors de l\'envoi du code',
      title: 'Erreur',
    );
  }
}
```

## Comparaison Visuelle

### SnackBar (Ancien)
- Apparaît en bas de l'écran
- Design basique
- Pas d'animation fluide
- Bloque parfois l'interface

### ToastService (Nouveau)
- ✨ Apparaît en haut (ou position personnalisable)
- 🎨 Design moderne et coloré
- 🎭 Animations fluides (slide + fade)
- 📊 Barre de progression
- 🎯 Ne bloque pas l'interface
- 👆 Glisser pour fermer
- ⏸️ Pause au survol
- 🎨 Icônes colorées selon le type

## Autres Exemples de Migration

### 1. Formulaire de création de vocalise

**AVANT:**
```dart
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  content: Text('Vocalise créée avec succès'),
  backgroundColor: Colors.green,
));
```

**APRÈS:**
```dart
ToastService.success(
  context,
  'Vocalise créée avec succès',
  title: 'Bibliothèque',
);
```

### 2. Téléchargement de fichier

**AVANT:**
```dart
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  content: Text('Téléchargement en cours...'),
  duration: Duration(days: 1), // Pour ne pas fermer automatiquement
));

// ... après le téléchargement
ScaffoldMessenger.of(context).clearSnackBars();
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  content: Text('Fichier téléchargé'),
  backgroundColor: Colors.green,
));
```

**APRÈS:**
```dart
final loadingToast = ToastService.loading(
  context,
  'Téléchargement en cours...',
);

// ... après le téléchargement
ToastService.dismiss(loadingToast);
ToastService.success(
  context,
  'Fichier téléchargé',
);
```

### 3. Erreur réseau

**AVANT:**
```dart
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text('Pas de connexion internet'),
  backgroundColor: Colors.red,
  action: SnackBarAction(
    label: 'Réessayer',
    onPressed: () => retry(),
  ),
));
```

**APRÈS:**
```dart
ToastService.error(
  context,
  'Pas de connexion internet',
  title: 'Erreur réseau',
  duration: Duration(seconds: 5),
);
```

### 4. Validation de formulaire

**AVANT:**
```dart
if (_formKey.currentState?.validate() ?? false) {
  // Sauvegarder
} else {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Veuillez remplir tous les champs'),
    backgroundColor: Colors.orange,
  ));
}
```

**APRÈS:**
```dart
if (_formKey.currentState?.validate() ?? false) {
  // Sauvegarder
  ToastService.success(context, 'Enregistré avec succès');
} else {
  ToastService.warning(
    context,
    'Veuillez remplir tous les champs',
  );
}
```

## Script de Migration Automatique

Pour faciliter la migration, utilisez cette recherche/remplacement dans VS Code :

### Étape 1 : Trouver tous les SnackBars

**Rechercher (Regex activée):**
```
ScaffoldMessenger\.of\(context\)\.showSnackBar\(.*?SnackBar\(
```

### Étape 2 : Identifier le type

- `backgroundColor: Colors.green` ou `Colors.teal` → `ToastService.success`
- `backgroundColor: Colors.red` → `ToastService.error`
- `backgroundColor: Colors.orange` ou `Colors.amber` → `ToastService.warning`
- `backgroundColor: Colors.blue` → `ToastService.info`

### Étape 3 : Ajouter l'import

En haut de chaque fichier modifié :
```dart
import 'package:voxbox/services/toast_service.dart';
```

## Checklist de Migration

- [ ] Ajouter `import 'package:voxbox/services/toast_service.dart';` dans les fichiers
- [ ] Remplacer les SnackBars de succès par `ToastService.success()`
- [ ] Remplacer les SnackBars d'erreur par `ToastService.error()`
- [ ] Remplacer les SnackBars d'avertissement par `ToastService.warning()`
- [ ] Remplacer les SnackBars d'info par `ToastService.info()`
- [ ] Utiliser `ToastService.loading()` pour les opérations longues
- [ ] Tester sur différents écrans pour vérifier le positionnement
- [ ] Vérifier que `ToastificationWrapper` est bien dans `main.dart`

## Résultat Attendu

Après la migration, vous aurez :
- ✅ Des notifications plus jolies et modernes
- ✅ Une meilleure expérience utilisateur
- ✅ Des animations fluides
- ✅ Un code plus propre et maintenable
- ✅ Une cohérence visuelle dans toute l'application
