# 🚀 Toast Service - Référence Rapide

## Import
```dart
import 'package:voxbox/services/toast_service.dart';
```

## Usage en 1 Ligne

```dart
// ✅ Succès
ToastService.success(context, 'Message');

// ❌ Erreur
ToastService.error(context, 'Message');

// ⚠️ Avertissement
ToastService.warning(context, 'Message');

// ℹ️ Information
ToastService.info(context, 'Message');

// ⏳ Chargement
final toast = ToastService.loading(context, 'Message');
ToastService.dismiss(toast);

// 🎨 Personnalisé
ToastService.custom(context, 'Message', icon: Icons.star, color: Colors.purple);
```

## Avec Titre
```dart
ToastService.success(context, 'Message', title: 'Titre');
```

## Avec Durée
```dart
ToastService.info(context, 'Message', duration: Duration(seconds: 5));
```

## Avec Position
```dart
ToastService.warning(context, 'Message', alignment: Alignment.topCenter);
```

## Migration depuis SnackBar

### Avant
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message'), backgroundColor: Colors.green)
);
```

### Après
```dart
ToastService.success(context, 'Message');
```

## Positions Disponibles
- `Alignment.topRight` (défaut)
- `Alignment.topCenter`
- `Alignment.topLeft`
- `Alignment.bottomRight`
- `Alignment.bottomCenter`
- `Alignment.bottomLeft`
- `Alignment.center`

## Fermer les Toasts
```dart
ToastService.dismissAll(); // Tout fermer
ToastService.dismiss(toast); // Fermer un toast spécifique
```

## Exemples Pratiques

### Formulaire
```dart
if (valid) {
  ToastService.success(context, 'Enregistré');
} else {
  ToastService.warning(context, 'Champs requis');
}
```

### Async/Await
```dart
final loading = ToastService.loading(context, 'Chargement...');
await operation();
ToastService.dismiss(loading);
ToastService.success(context, 'Terminé !');
```

### Try/Catch
```dart
try {
  await saveData();
  ToastService.success(context, 'Sauvegardé');
} catch (e) {
  ToastService.error(context, 'Erreur: $e');
}
```

## Types de Toast

| Méthode | Couleur | Icône | Usage |
|---------|---------|-------|-------|
| `success()` | Vert | ✅ | Succès |
| `error()` | Rouge | ❌ | Erreur |
| `warning()` | Orange | ⚠️ | Avertissement |
| `info()` | Bleu | ℹ️ | Information |
| `loading()` | Bleu | ⏳ | Chargement |
| `custom()` | 🎨 | 🎨 | Personnalisé |

## Durées par Défaut
- Success: 3s
- Error: 4s
- Warning: 3s
- Info: 3s
- Loading: ∞ (manuel)

## Fichiers Créés
1. `lib/services/toast_service.dart` - Service
2. `lib/view/toast_demo_screen.dart` - Démo
3. `TOAST_USAGE_GUIDE.md` - Guide complet
4. `TOAST_MIGRATION_EXAMPLE.md` - Migration
5. `TOAST_ALTERNATIVES.md` - Alternatives
6. `TOAST_VISUAL_EXAMPLES.md` - Visuels
7. `TOAST_IMPLEMENTATION_SUMMARY.md` - Résumé

## Tester
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ToastDemoScreen()),
);
```

## Configuration Main
✅ Déjà fait - `ToastificationWrapper` ajouté dans `lib/main.dart`

## Package Utilisé
✅ `toastification: ^1.0.0` (déjà installé)

---

**C'est tout ! Vous êtes prêt à utiliser les toasts. 🎉**
