<?php
/**
 * Script de diagnostic d'authentification - VoXY Box
 */

echo "🔍 DIAGNOSTIC AUTHENTIFICATION - VoXY Box\n";
echo "==========================================\n\n";

// Configuration
$baseURL = 'http://192.168.11.102:8000';
$loginURL = $baseURL . '/api/login';

echo "📡 Configuration:\n";
echo "   - URL Backend: $baseURL\n";
echo "   - URL Login: $loginURL\n\n";

// Test 1: Vérifier la connectivité
echo "1. 🚀 Test de connectivité...\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $loginURL);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_NOBODY, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ Erreur de connexion: $error\n";
    echo "\n🔧 SOLUTIONS:\n";
    echo "   1. Arrêtez votre backend actuel (Ctrl+C)\n";
    echo "   2. Redémarrez avec: php artisan serve --host=0.0.0.0 --port=8000\n";
    echo "   3. Vérifiez que vous êtes sur le même réseau WiFi que votre téléphone\n";
    echo "\n📋 Commandes à exécuter:\n";
    echo "   cd /Users/apple/Desktop/Tech/KuilingaTechnologies/ProjectHouse/voxbobackend\n";
    echo "   php artisan serve --host=0.0.0.0 --port=8000\n";
    exit(1);
}

echo "✅ Serveur accessible (Code HTTP: $httpCode)\n\n";

// Test 2: Test d'authentification avec différents identifiants
echo "2. 🔐 Test d'authentification...\n";

$testCredentials = [
    ['email' => 'admin@voxy.com', 'password' => 'admin123', 'description' => 'Admin par défaut'],
    ['email' => 'admin@voxy.com', 'password' => 'password', 'description' => 'Admin avec password'],
    ['email' => 'admin@voxy.com', 'password' => 'admin', 'description' => 'Admin avec admin'],
];

foreach ($testCredentials as $index => $cred) {
    echo "   Test " . ($index + 1) . ": {$cred['description']}\n";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $loginURL);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        'email' => $cred['email'],
        'password' => $cred['password']
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    echo "      Code HTTP: $httpCode\n";
    
    if ($httpCode == 200) {
        $data = json_decode($response, true);
        if (isset($data['token'])) {
            echo "      ✅ SUCCÈS! Token reçu: " . substr($data['token'], 0, 20) . "...\n";
            echo "      👤 Utilisateur: " . ($data['user']['name'] ?? 'N/A') . "\n";
            echo "      📧 Email: " . ($data['user']['email'] ?? 'N/A') . "\n";
            break;
        } else {
            echo "      ❌ Pas de token dans la réponse\n";
        }
    } else {
        echo "      ❌ Échec: $httpCode\n";
        if ($httpCode == 401) {
            $data = json_decode($response, true);
            echo "      Message: " . ($data['message'] ?? 'Non autorisé') . "\n";
        }
    }
    echo "\n";
}

// Test 3: Vérifier les utilisateurs dans la base de données
echo "3. 👥 Vérification des utilisateurs...\n";
echo "   Exécutez cette commande dans votre backend:\n";
echo "   php artisan tinker --execute=\"echo 'Users: '; App\\Models\\User::all(['email', 'name'])->each(function(\$u) { echo \$u->email . ' - ' . \$u->name . PHP_EOL; });\"\n\n";

// Test 4: Vérifier la configuration de l'application mobile
echo "4. 📱 Configuration application mobile...\n";
echo "   Vérifiez que dans lib/functions/appconstants.dart:\n";
echo "   static String baseURL = 'http://192.168.11.102:8000';\n\n";

echo "🎯 RÉSUMÉ:\n";
echo "==========\n";
echo "✅ Backend accessible: " . ($httpCode ? "Oui" : "Non") . "\n";
echo "✅ Authentification: " . (isset($data['token']) ? "Fonctionnelle" : "Problème") . "\n";
echo "\n";
echo "📱 Prochaines étapes:\n";
echo "1. Si le backend n'est pas accessible, redémarrez avec --host=0.0.0.0\n";
echo "2. Si l'auth échoue, vérifiez les identifiants dans la base de données\n";
echo "3. Recompilez l'application mobile avec la bonne URL\n";
echo "4. Testez sur votre téléphone\n";
?>
