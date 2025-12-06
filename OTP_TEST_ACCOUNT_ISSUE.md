# Problème avec les comptes de test OTP

## Problème identifié

Le compte de test avec le numéro **57023486** présente les problèmes suivants :

1. **Code OTP figé** : Le code OTP retourné est toujours le même (probablement hardcodé pour les numéros de test)
2. **Compte non créé en base** : Le compte n'est pas réellement créé en base de données lors de la vérification OTP

## Analyse du code Flutter

Le code Flutter appelle simplement les API backend :
- `POST /api/request-otp` : Pour demander un code OTP
- `POST /api/verify-otp` : Pour vérifier le code OTP et se connecter

La logique de gestion des comptes de test est gérée côté **backend Laravel**.

## Solutions à implémenter côté backend

### Option 1 : Créer réellement les comptes de test en base

Modifier le backend Laravel pour que lors de la vérification OTP d'un numéro de test :
1. Le compte soit réellement créé en base de données
2. Un OTP unique soit généré (même pour les numéros de test)
3. Le compte soit sauvegardé avec un statut approprié

### Option 2 : Améliorer la gestion des numéros de test

Si vous voulez garder un OTP fixe pour les tests, assurez-vous que :
1. Le compte soit créé en base lors de la première vérification OTP
2. Les vérifications suivantes utilisent le compte existant
3. L'OTP de test soit documenté (ex: "123456" pour tous les numéros de test)

### Option 3 : Mode développement avec création automatique

Créer un mode développement où :
- Les numéros de test sont identifiés (ex: commençant par "5702")
- Un OTP fixe est utilisé (ex: "123456")
- Le compte est automatiquement créé en base lors de la vérification
- Le compte est créé avec des données par défaut si nécessaire

## Vérifications à faire côté backend Laravel

1. **Vérifier le contrôleur OTP** (`app/Http/Controllers/Auth/OtpController.php` ou similaire) :
   - Comment les numéros de test sont-ils gérés ?
   - Le compte est-il créé lors de `verify-otp` ?
   - L'OTP est-il hardcodé pour certains numéros ?

2. **Vérifier le modèle User** :
   - Le compte est-il créé avec `User::create()` ou `User::firstOrCreate()` ?
   - Les données par défaut sont-elles correctement définies ?

3. **Vérifier la migration de la table users** :
   - Tous les champs nécessaires sont-ils présents ?
   - Les contraintes sont-elles correctes ?

## Exemple de code backend suggéré

```php
// Dans le contrôleur verify-otp
public function verifyOtp(Request $request)
{
    $phone = $request->input('phone');
    $otp = $request->input('otp');
    
    // Vérifier si c'est un numéro de test
    $isTestNumber = $this->isTestNumber($phone);
    $testOtp = '123456'; // OTP fixe pour les tests
    
    if ($isTestNumber && $otp === $testOtp) {
        // Créer ou récupérer le compte de test
        $user = User::firstOrCreate(
            ['phone' => $phone],
            [
                'name' => 'Test User',
                'email' => "test_{$phone}@voxbox.bf",
                'status' => 'approved', // ou 'pending' selon vos besoins
                // ... autres champs par défaut
            ]
        );
        
        // Générer un token
        $token = $user->createToken('mobile-app')->plainTextToken;
        
        return response()->json([
            'success' => true,
            'token' => $token,
            'user' => $user,
            'profile_complete' => $user->isProfileComplete(),
            'profile_incomplete' => !$user->isProfileComplete(),
        ]);
    }
    
    // Logique normale pour les vrais numéros...
}

private function isTestNumber($phone)
{
    // Définir les numéros de test (ex: commençant par 5702)
    return strpos($phone, '5702') === 0 || 
           in_array($phone, ['+22657023486', '57023486']);
}
```

## Actions immédiates

1. ✅ Vérifier les logs backend lors de la demande OTP pour le numéro 57023486
2. ✅ Vérifier les logs backend lors de la vérification OTP
3. ✅ Vérifier si le compte existe en base de données après vérification OTP
4. ✅ Modifier le backend pour créer réellement le compte lors de la vérification OTP

## Notes

- Le code Flutter est correct et appelle bien les bonnes API
- Le problème est dans la logique backend qui ne crée pas le compte
- Il faut modifier le backend Laravel pour résoudre ce problème

