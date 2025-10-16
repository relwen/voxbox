<?php

/**
 * Script de test pour vérifier la connexion mobile vers le backend
 * Utilise la même URL que l'application Flutter
 */

echo "=== Test de connexion mobile vers backend ===\n\n";

// URL configurée dans l'application mobile
$baseUrl = 'http://localhost:8000';
$apiUrl = $baseUrl . '/api/chorales';

echo "1. URL de base configurée: $baseUrl\n";
echo "2. URL complète des chorales: $apiUrl\n\n";

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
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    
    if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'body' => json_decode($response, true),
        'error' => $error
    ];
}

// Test de l'endpoint des chorales
echo "3. Test de l'endpoint /api/chorales\n";

$response = makeRequest($apiUrl);

if ($response['error']) {
    echo "❌ ERREUR DE CONNEXION: {$response['error']}\n";
    echo "\nVérifiez que:\n";
    echo "1. Le serveur Laravel est démarré (php artisan serve)\n";
    echo "2. L'URL dans appconstants.dart est correcte\n";
    echo "3. Le backend est accessible depuis l'application\n";
} else {
    echo "Code HTTP: {$response['code']}\n";
    
    if ($response['code'] == 200) {
        echo "✅ SUCCÈS: Connexion au backend réussie\n";
        
        if ($response['body'] && $response['body']['success'] == true && isset($response['body']['data'])) {
            $chorales = $response['body']['data'];
            echo "Nombre de chorales récupérées: " . count($chorales) . "\n";
            
            if (count($chorales) > 0) {
                echo "Première chorale: " . $chorales[0]['name'] . "\n";
            }
        } else {
            echo "❌ ERREUR: Format de réponse incorrect\n";
            echo "Réponse: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n";
        }
    } else {
        echo "❌ ERREUR: Code HTTP {$response['code']}\n";
        echo "Réponse: " . json_encode($response['body'], JSON_PRETTY_PRINT) . "\n";
    }
}

echo "\n=== Résumé ===\n";
if ($response['code'] == 200) {
    echo "✅ La connexion mobile fonctionne correctement\n";
    echo "L'application devrait pouvoir récupérer les chorales\n";
} else {
    echo "❌ Problème de connexion détecté\n";
    echo "Vérifiez la configuration de l'URL dans appconstants.dart\n";
}

echo "\n=== Fin du test ===\n";
