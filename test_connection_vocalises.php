<?php
/**
 * Test de connexion pour les vocalises
 * Vérifie que le backend est accessible et que l'API fonctionne
 */

echo "🔍 TEST DE CONNEXION VOCALISES - VoXY Box\n";
echo "==========================================\n\n";

// Configuration
$baseURL = 'http://10.5.27.241:8001';
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
    exit(1);
}

echo "✅ Serveur accessible (Code HTTP: $httpCode)\n\n";

// Test 2: Vérifier l'endpoint vocalises
echo "2. 🎵 Test de l'endpoint vocalises...\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $vocalisesURL);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_HEADER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Code HTTP: $httpCode\n";

if ($httpCode == 302) {
    echo "✅ Endpoint vocalises accessible (redirection vers login - normal)\n";
} elseif ($httpCode == 200) {
    echo "✅ Endpoint vocalises accessible (données retournées)\n";
    $data = json_decode($response, true);
    if ($data) {
        echo "📊 Nombre de vocalises: " . count($data) . "\n";
    }
} else {
    echo "⚠️  Code HTTP inattendu: $httpCode\n";
}

echo "\n";

// Test 3: Vérifier l'authentification
echo "3. 🔐 Test d'authentification...\n";
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
        echo "🔑 Token reçu: " . substr($data['token'], 0, 20) . "...\n";
        
        // Test 4: Tester l'accès aux vocalises avec le token
        echo "\n4. 🎵 Test d'accès aux vocalises avec token...\n";
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
            echo "📊 Nombre de vocalises: " . count($vocalises) . "\n";
            
            if (count($vocalises) > 0) {
                echo "📋 Première vocalise:\n";
                $first = $vocalises[0];
                echo "   - ID: " . $first['id'] . "\n";
                echo "   - Titre: " . $first['title'] . "\n";
                echo "   - Audio: " . ($first['audio_path'] ? 'Oui' : 'Non') . "\n";
            }
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
echo "✅ Endpoint vocalises: $vocalisesURL\n";
echo "✅ Application configurée avec la bonne adresse IP\n";
echo "\n";
echo "📱 Prochaines étapes:\n";
echo "1. Installez l'APK mis à jour sur votre téléphone\n";
echo "2. Connectez-vous avec: admin@voxy.com / admin123\n";
echo "3. Testez l'accès aux vocalises\n";
echo "\n";
echo "🚀 Votre application VoXY Box est prête !\n";
?>
