<?php

/**
 * Script de test pour vérifier l'accès public aux chorales
 * Teste si /api/chorales est accessible sans authentification
 */

echo "=== Test d'accès public aux chorales ===\n\n";

// Configuration
$baseUrl = 'http://192.168.11.104:8001/api';

// Fonction pour faire des requêtes HTTP
function makeRequest($url, $method = 'GET', $data = null, $token = null) {
    $ch = curl_init();
    
    $headers = [
        'Content-Type: application/json',
        'Accept: application/json'
    ];
    
    if ($token) {
        $headers[] = 'Authorization: Bearer ' . $token;
    }
    
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    
    if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'body' => json_decode($response, true)
    ];
}

// Test 1: Accès aux chorales SANS authentification
echo "1. Test d'accès public aux chorales (sans token)\n";
$response = makeRequest($baseUrl . '/chorales');
echo "Code HTTP: " . $response['code'] . "\n";

if ($response['code'] == 200) {
    echo "✓ SUCCÈS: Endpoint /api/chorales accessible sans authentification\n";
    $chorales = $response['body']['data'] ?? [];
    echo "Nombre de chorales: " . count($chorales) . "\n";
    
    if (count($chorales) > 0) {
        echo "Première chorale: " . ($chorales[0]['nom'] ?? 'N/A') . "\n";
    }
} elseif ($response['code'] == 401) {
    echo "✗ ERREUR 401: Endpoint /api/chorales nécessite une authentification\n";
    echo "PROBLÈME: Le backend bloque l'accès public aux chorales\n";
} else {
    echo "✗ ERREUR {$response['code']}: Problème avec l'endpoint\n";
}

echo "Réponse complète: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n\n";

// Test 2: Accès aux chorales AVEC authentification (pour comparaison)
echo "2. Test d'accès aux chorales avec authentification\n";

// Tentative de connexion
$loginData = [
    'email' => 'admin@voxy.com',
    'password' => 'admin123'
];

$loginResponse = makeRequest($baseUrl . '/login', 'POST', $loginData);

if ($loginResponse['code'] == 200 && isset($loginResponse['body']['token'])) {
    $token = $loginResponse['body']['token'];
    echo "✓ Connexion réussie\n";
    
    // Test avec token
    $response = makeRequest($baseUrl . '/chorales', 'GET', null, $token);
    echo "Code HTTP avec token: " . $response['code'] . "\n";
    
    if ($response['code'] == 200) {
        echo "✓ SUCCÈS: Endpoint /api/chorales accessible avec authentification\n";
        $chorales = $response['body']['data'] ?? [];
        echo "Nombre de chorales: " . count($chorales) . "\n";
    } else {
        echo "✗ ERREUR: Problème même avec authentification\n";
    }
} else {
    echo "✗ Impossible de se connecter pour le test avec authentification\n";
}

echo "\n=== Résumé ===\n";
echo "L'endpoint /api/chorales devrait être accessible SANS authentification\n";
echo "Si vous obtenez une erreur 401, le backend doit être configuré pour permettre l'accès public\n";

echo "\n=== Instructions de correction ===\n";
echo "Pour corriger le backend Laravel:\n";
echo "1. Ouvrir le fichier routes/api.php\n";
echo "2. S'assurer que la route /api/chorales n'a pas de middleware 'auth:sanctum'\n";
echo "3. Exemple de route publique:\n";
echo "   Route::get('/chorales', [ChoraleController::class, 'index']);\n";
echo "4. Redémarrer le serveur Laravel\n";

echo "\n=== Fin du test ===\n";
