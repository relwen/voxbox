<?php

/**
 * Script pour tester la structure de la réponse des vocalises
 */

echo "=== Test de la structure des vocalises ===\n\n";

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

// 1. Connexion pour obtenir un token
echo "1. Connexion...\n";
$loginData = [
    'email' => 'admin@voxy.com',
    'password' => 'admin123'
];

$response = makeRequest($baseUrl . '/login', 'POST', $loginData);
if ($response['code'] == 200 && isset($response['body']['token'])) {
    $token = $response['body']['token'];
    echo "✓ Connexion réussie\n\n";
    
    // 2. Test de la structure des vocalises
    echo "2. Test de la structure des vocalises...\n";
    $response = makeRequest($baseUrl . '/vocalises', 'GET', null, $token);
    
    echo "Code HTTP: " . $response['code'] . "\n";
    echo "Structure de la réponse:\n";
    echo json_encode($response['body'], JSON_PRETTY_PRINT) . "\n\n";
    
    // 3. Analyse de la structure
    if (isset($response['body']['data'])) {
        echo "✓ La réponse contient une clé 'data'\n";
        echo "Nombre d'éléments dans 'data': " . count($response['body']['data']) . "\n";
        
        if (count($response['body']['data']) > 0) {
            echo "Premier élément:\n";
            echo json_encode($response['body']['data'][0], JSON_PRETTY_PRINT) . "\n";
        }
    } else {
        echo "✗ La réponse ne contient pas de clé 'data'\n";
        echo "Clés disponibles: " . implode(', ', array_keys($response['body'])) . "\n";
    }
    
} else {
    echo "✗ Échec de la connexion\n";
}

echo "\n=== Fin du test ===\n";
