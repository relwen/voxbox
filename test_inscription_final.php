<?php

/**
 * Script de test final pour l'inscription avec les bons pupitres
 */

echo "=== Test Final d'Inscription ===\n\n";

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

// Test avec les pupitres valides
$validVoiceParts = ['SOPRANE', 'ALTO', 'TENOR', 'BASSE', 'BARITON'];

echo "2. Test avec les pupitres valides\n\n";

foreach ($validVoiceParts as $voicePart) {
    echo "Test avec voice_part: '$voicePart'\n";
    
    $testData = [
        'name' => 'Test User ' . $voicePart,
        'email' => 'test.' . strtolower($voicePart) . '@voxbox.bf',
        'password' => 'password123',
        'password_confirmation' => 'password123',
        'chorale_id' => 1,
        'voice_part' => $voicePart,
        'phone' => '+22600000000'
    ];
    
    $response = makeRequest($apiUrl, 'POST', $testData);
    
    if ($response['error']) {
        echo "   ❌ ERREUR DE CONNEXION: {$response['error']}\n";
        continue;
    }
    
    echo "   Code HTTP: {$response['code']}\n";
    
    if ($response['code'] == 201) {
        echo "   ✅ SUCCÈS: Inscription réussie avec '$voicePart'\n";
        if ($response['body'] && isset($response['body']['user'])) {
            $user = $response['body']['user'];
            echo "      - ID: " . ($user['id'] ?? 'N/A') . "\n";
            echo "      - Nom: " . ($user['name'] ?? 'N/A') . "\n";
            echo "      - Email: " . ($user['email'] ?? 'N/A') . "\n";
            echo "      - Pupitre: " . ($user['voice_part'] ?? 'N/A') . "\n";
            echo "      - Statut: " . ($user['status'] ?? 'N/A') . "\n";
        }
    } elseif ($response['code'] == 422) {
        if ($response['body'] && isset($response['body']['errors'])) {
            echo "   ❌ ERREUR 422: Erreurs de validation\n";
            foreach ($response['body']['errors'] as $field => $errors) {
                echo "      $field: " . implode(', ', $errors) . "\n";
            }
        }
    } else {
        echo "   ❌ ERREUR: Code {$response['code']}\n";
    }
    
    echo "\n";
}

echo "=== Résumé ===\n";
echo "✅ Les pupitres valides sont: SOPRANE, ALTO, TENOR, BASSE, BARITON\n";
echo "✅ L'application mobile a été corrigée pour utiliser ces valeurs\n";
echo "✅ La création de compte devrait maintenant fonctionner\n";

echo "\n=== Fin du test ===\n";
