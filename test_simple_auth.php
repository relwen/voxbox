<?php

/**
 * Script de test simple pour l'authentification
 */

echo "=== Test d'authentification simple ===\n\n";

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

// Test 1: Tentative de connexion avec des données de test
echo "1. Test de connexion avec des données de test\n";

// Utilisez vos vraies données de connexion ici
$loginData = [
    'email' => 'admin@voxy.com',     // Email de l'admin
    'password' => 'admin123'         // Mot de passe correct
];

echo "Tentative de connexion avec: " . $loginData['email'] . "\n";

$response = makeRequest($baseUrl . '/login', 'POST', $loginData);
echo "Code HTTP: " . $response['code'] . "\n";

if ($response['code'] == 200 && isset($response['body']['token'])) {
    $token = $response['body']['token'];
    echo "✓ Connexion réussie!\n";
    echo "Token: " . substr($token, 0, 30) . "...\n\n";
    
    // Test 2: Utiliser le token pour accéder aux endpoints protégés
    echo "2. Test avec token - /me\n";
    $response = makeRequest($baseUrl . '/me', 'GET', null, $token);
    echo "Code HTTP: " . $response['code'] . "\n";
    if ($response['code'] == 200) {
        echo "✓ Token valide - accès aux données utilisateur\n";
        echo "Utilisateur: " . ($response['body']['user']['name'] ?? 'N/A') . "\n";
    } else {
        echo "✗ Token invalide\n";
    }
    echo "Réponse: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n\n";
    
    // Test 3: Accéder aux chorales avec le token
    echo "3. Test avec token - /chorales\n";
    $response = makeRequest($baseUrl . '/chorales', 'GET', null, $token);
    echo "Code HTTP: " . $response['code'] . "\n";
    if ($response['code'] == 200) {
        echo "✓ Token valide - accès aux chorales\n";
        $chorales = $response['body']['data'] ?? [];
        echo "Nombre de chorales: " . count($chorales) . "\n";
    } else {
        echo "✗ Token invalide pour les chorales\n";
    }
    echo "Réponse: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n\n";
    
    // Test 4: Accéder aux vocalises avec le token
    echo "4. Test avec token - /vocalises\n";
    $response = makeRequest($baseUrl . '/vocalises', 'GET', null, $token);
    echo "Code HTTP: " . $response['code'] . "\n";
    if ($response['code'] == 200) {
        echo "✓ Token valide - accès aux vocalises\n";
        $vocalises = $response['body']['data'] ?? [];
        echo "Nombre de vocalises: " . count($vocalises) . "\n";
    } else {
        echo "✗ Token invalide pour les vocalises\n";
    }
    echo "Réponse: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n\n";
    
} else {
    echo "✗ Échec de la connexion\n";
    echo "Réponse: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n\n";
    
    echo "Vérifiez que:\n";
    echo "1. Votre email et mot de passe sont corrects\n";
    echo "2. L'utilisateur existe dans la base de données\n";
    echo "3. Le serveur Laravel fonctionne correctement\n";
}

echo "=== Fin des tests ===\n";
