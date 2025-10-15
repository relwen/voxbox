<?php

/**
 * Script de test pour l'authentification
 * Teste la connexion et la récupération du token
 */

echo "=== Test d'authentification ===\n\n";

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

// Test 1: Vérifier les chorales (endpoint public)
echo "1. Test endpoint public /chorales\n";
$response = makeRequest($baseUrl . '/chorales');
echo "Code HTTP: " . $response['code'] . "\n";
if ($response['code'] == 200) {
    echo "✓ Endpoint public accessible\n";
} else {
    echo "✗ Problème avec l'endpoint public\n";
}
echo "Réponse: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n\n";

// Test 2: Tentative de connexion
echo "2. Test de connexion\n";
echo "Entrez votre email: ";
$email = trim(fgets(STDIN));
echo "Entrez votre mot de passe: ";
$password = trim(fgets(STDIN));

$loginData = [
    'email' => $email,
    'password' => $password
];

$response = makeRequest($baseUrl . '/login', 'POST', $loginData);
echo "Code HTTP: " . $response['code'] . "\n";

if ($response['code'] == 200 && isset($response['body']['token'])) {
    $token = $response['body']['token'];
    echo "✓ Connexion réussie!\n";
    echo "Token: " . substr($token, 0, 20) . "...\n\n";
    
    // Test 3: Utiliser le token pour accéder aux endpoints protégés
    echo "3. Test avec token - /me\n";
    $response = makeRequest($baseUrl . '/me', 'GET', null, $token);
    echo "Code HTTP: " . $response['code'] . "\n";
    if ($response['code'] == 200) {
        echo "✓ Token valide - accès aux données utilisateur\n";
    } else {
        echo "✗ Token invalide\n";
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
}

echo "=== Fin des tests ===\n";
