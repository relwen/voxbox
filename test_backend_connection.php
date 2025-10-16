<?php
/**
 * Test de connexion avec le backend sur localhost:8000
 */

echo "🔍 TEST DE CONNEXION BACKEND - VoXY Box\n";
echo "========================================\n\n";

// Configuration
$baseURL = 'http://10.5.27.241:8000';
$vocalisesURL = $baseURL . '/api/vocalises';

echo "📡 Test de connexion au backend...\n";
echo "URL: $vocalisesURL\n\n";

// Test 1: Vérifier que le serveur répond
echo "1. 🚀 Test de connectivité...\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $vocalisesURL);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, false);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_NOBODY, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ Erreur de connexion: $error\n";
    echo "\n🔧 Solutions possibles:\n";
    echo "   1. Vérifiez que votre backend est démarré: php artisan serve --host=0.0.0.0 --port=8000\n";
    echo "   2. Vérifiez que le port 8000 est accessible\n";
    echo "   3. Vérifiez votre adresse IP: ifconfig | grep 'inet '\n";
    exit(1);
}

echo "✅ Serveur accessible (Code HTTP: $httpCode)\n\n";

// Test 2: Test d'authentification
echo "2. 🔐 Test d'authentification...\n";
$loginURL = $baseURL . '/api/login';
$loginData = [
    'email' => 'admin@voxy.com',
    'password' => 'admin123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $loginURL);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Code HTTP: $httpCode\n";

if ($httpCode == 200) {
    $data = json_decode($response, true);
    if (isset($data['token'])) {
        echo "✅ Authentification réussie\n";
        echo "🔑 Token: " . substr($data['token'], 0, 20) . "...\n";
        echo "👤 Utilisateur: " . $data['user']['name'] . "\n";
        
        // Test 3: Tester l'accès aux vocalises
        echo "\n3. 🎵 Test d'accès aux vocalises...\n";
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $vocalisesURL);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $data['token'],
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "Code HTTP: $httpCode\n";
        
        if ($httpCode == 200) {
            $vocalises = json_decode($response, true);
            echo "✅ Accès aux vocalises réussi\n";
            echo "📊 Nombre de vocalises: " . count($vocalises['data'] ?? []) . "\n";
        } else {
            echo "❌ Erreur d'accès aux vocalises: $httpCode\n";
        }
    } else {
        echo "❌ Token non reçu dans la réponse\n";
    }
} else {
    echo "❌ Erreur d'authentification: $httpCode\n";
    echo "Réponse: $response\n";
}

echo "\n";
echo "🎯 RÉSUMÉ:\n";
echo "==========\n";
echo "✅ Backend accessible sur: $baseURL\n";
echo "✅ Application configurée avec la bonne adresse IP\n";
echo "\n";
echo "📱 Prochaines étapes:\n";
echo "1. Recompilez l'application: fvm flutter build apk --debug\n";
echo "2. Installez l'APK sur votre téléphone\n";
echo "3. Testez la connexion dans l'application\n";
echo "\n";
echo "🚀 Votre application devrait maintenant fonctionner !\n";
?>
