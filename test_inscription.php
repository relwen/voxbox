<?php

/**
 * Script de test pour l'inscription d'un utilisateur
 * Teste l'endpoint /api/register avec les vraies données
 */

echo "=== Test d'Inscription Utilisateur ===\n\n";

// Configuration
$baseUrl = 'http://localhost:8000';
$apiUrl = $baseUrl . '/api/register';

echo "1. Configuration\n";
echo "   URL Backend: $baseUrl\n";
echo "   URL API: $apiUrl\n\n";

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
        'raw_body' => $response,
        'error' => $error
    ];
}

// Test 1: Vérifier que l'endpoint existe
echo "2. Test de l'endpoint d'inscription\n";

$testData = [
    'name' => 'Test User',
    'email' => 'test.user@voxbox.bf',
    'password' => 'password123',
    'password_confirmation' => 'password123',
    'chorale_id' => 1,
    'voice_part' => 'SOPRANE',
    'phone' => '+22600000000'
];

echo "Données de test:\n";
foreach ($testData as $key => $value) {
    echo "   $key: $value\n";
}
echo "\n";

$response = makeRequest($apiUrl, 'POST', $testData);

if ($response['error']) {
    echo "❌ ERREUR DE CONNEXION: {$response['error']}\n";
    echo "Vérifiez que le serveur Laravel est démarré\n";
    exit(1);
}

echo "Code HTTP: {$response['code']}\n";

if ($response['code'] == 201) {
    echo "✅ SUCCÈS: Inscription réussie\n";
    
    if ($response['body'] && $response['body']['success'] == true) {
        echo "✅ Structure de réponse correcte\n";
        
        if (isset($response['body']['token'])) {
            echo "✅ Token généré: " . substr($response['body']['token'], 0, 20) . "...\n";
        }
        
        if (isset($response['body']['user'])) {
            $user = $response['body']['user'];
            echo "✅ Utilisateur créé:\n";
            echo "   - ID: " . ($user['id'] ?? 'N/A') . "\n";
            echo "   - Nom: " . ($user['name'] ?? 'N/A') . "\n";
            echo "   - Email: " . ($user['email'] ?? 'N/A') . "\n";
            echo "   - Chorale ID: " . ($user['chorale_id'] ?? 'N/A') . "\n";
            echo "   - Pupitre: " . ($user['voice_part'] ?? 'N/A') . "\n";
        }
    } else {
        echo "❌ Structure de réponse incorrecte\n";
    }
} elseif ($response['code'] == 422) {
    echo "❌ ERREUR 422: Erreurs de validation\n";
    if ($response['body'] && isset($response['body']['errors'])) {
        foreach ($response['body']['errors'] as $field => $errors) {
            echo "   $field: " . implode(', ', $errors) . "\n";
        }
    }
} elseif ($response['code'] == 400) {
    echo "❌ ERREUR 400: Requête incorrecte\n";
    if ($response['body'] && isset($response['body']['message'])) {
        echo "   Message: " . $response['body']['message'] . "\n";
    }
} else {
    echo "❌ ERREUR: Code HTTP {$response['code']}\n";
}

echo "\nRéponse complète:\n";
echo $response['raw_body'] . "\n";

echo "\n=== Résumé ===\n";
if ($response['code'] == 201) {
    echo "✅ L'endpoint d'inscription fonctionne correctement\n";
    echo "✅ L'application mobile peut créer des comptes\n";
} else {
    echo "❌ PROBLÈME avec l'endpoint d'inscription\n";
    echo "Vérifiez la configuration du backend\n";
}

echo "\n=== Fin du test ===\n";
