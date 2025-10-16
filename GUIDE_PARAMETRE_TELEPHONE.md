# Guide - Numéro de Téléphone en Paramètre

## ✅ Nouvelle Approche

J'ai modifié `UserRegistrationScreen` pour accepter le numéro de téléphone en paramètre au lieu d'utiliser SharedPreferences.

## 🔧 Modifications Apportées

### **1. Constructeur Modifié**

**Avant** :
```dart
class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});
}
```

**Après** :
```dart
class UserRegistrationScreen extends StatefulWidget {
  final String? phoneNumber;
  
  const UserRegistrationScreen({
    super.key,
    this.phoneNumber,
  });
}
```

### **2. Suppression de SharedPreferences**

**Supprimé** :
- Variable `_userPhone`
- Méthode `_loadUserPhone()`
- Appel dans `initState()`
- Logs de récupération

### **3. Utilisation du Paramètre**

**Dans la validation** :
```dart
if (_fullNameController.text.isEmpty || 
    widget.phoneNumber == null ||
    _selectedPupitre == null || 
    _selectedChorale == null) {
  // Erreur
}
```

**Dans l'affichage** :
```dart
if (widget.phoneNumber != null)
  Container(
    // ...
    Text('Téléphone: ${widget.phoneNumber}'),
  ),
```

**Dans l'envoi au backend** :
```dart
String phone = widget.phoneNumber!;
```

## 📱 Comment Utiliser

### **1. Depuis la Page de Connexion OTP**

```dart
// Après validation de l'OTP
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UserRegistrationScreen(
      phoneNumber: phoneNumber, // Passer le numéro ici
    ),
  ),
);
```

### **2. Depuis une Autre Page**

```dart
// Si vous avez le numéro de téléphone
const phoneNumber = '+22670123456';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UserRegistrationScreen(
      phoneNumber: phoneNumber,
    ),
  ),
);
```

### **3. Sans Numéro (Optionnel)**

```dart
// Si le numéro n'est pas disponible
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UserRegistrationScreen(),
  ),
);
```

## 🔍 Comportement

### **1. Avec Numéro**
- ✅ **Affichage** : Le numéro s'affiche en lecture seule
- ✅ **Validation** : Le numéro est utilisé pour l'inscription
- ✅ **Envoi** : Le numéro est envoyé au backend

### **2. Sans Numéro**
- ❌ **Affichage** : Rien ne s'affiche
- ❌ **Validation** : Erreur "Veuillez remplir tous les champs"
- ❌ **Envoi** : L'inscription ne peut pas se faire

## 🧪 Test de Vérification

### **Test avec Numéro**
```dart
// Dans votre page de test
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UserRegistrationScreen(
      phoneNumber: '+22670123456',
    ),
  ),
);
```

**Résultat attendu** :
- Le numéro s'affiche dans le formulaire
- L'inscription fonctionne avec ce numéro

### **Test sans Numéro**
```dart
// Dans votre page de test
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UserRegistrationScreen(),
  ),
);
```

**Résultat attendu** :
- Aucun numéro affiché
- Erreur lors de la tentative d'inscription

## 📋 Avantages de cette Approche

### **1. Simplicité**
- ✅ **Pas de SharedPreferences** : Plus de gestion de clés
- ✅ **Pas de récupération asynchrone** : Le numéro est directement disponible
- ✅ **Pas de logs de débogage** : Code plus propre

### **2. Flexibilité**
- ✅ **Paramètre optionnel** : Peut être null
- ✅ **Réutilisable** : Peut être appelé depuis n'importe où
- ✅ **Testable** : Facile à tester avec différents numéros

### **3. Performance**
- ✅ **Pas d'appel asynchrone** : Plus rapide
- ✅ **Pas de lecture de stockage** : Plus efficace
- ✅ **Données directes** : Pas de délai

## 🎯 Prochaines Étapes

1. **Modifier la page de connexion OTP** pour passer le numéro en paramètre
2. **Tester l'inscription** avec le numéro passé
3. **Vérifier le fonctionnement** complet

## 📝 Exemple Complet

```dart
// Dans votre page de connexion OTP
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Simuler un numéro de téléphone
            const phoneNumber = '+22670123456';
            
            // Naviguer vers l'inscription avec le numéro
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserRegistrationScreen(
                  phoneNumber: phoneNumber,
                ),
              ),
            );
          },
          child: const Text('Aller à l\'inscription'),
        ),
      ),
    );
  }
}
```

## 🔄 Migration depuis SharedPreferences

Si vous aviez du code qui utilisait SharedPreferences :

**Avant** :
```dart
// Récupérer le numéro depuis SharedPreferences
final prefs = await SharedPreferences.getInstance();
final phone = prefs.getString('user_phone');

// Naviguer vers l'inscription
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UserRegistrationScreen(),
  ),
);
```

**Après** :
```dart
// Récupérer le numéro depuis SharedPreferences
final prefs = await SharedPreferences.getInstance();
final phone = prefs.getString('user_phone');

// Naviguer vers l'inscription avec le numéro
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UserRegistrationScreen(
      phoneNumber: phone,
    ),
  ),
);
```
