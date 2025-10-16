<?php

/**
 * Script de test pour vérifier les pupitres acceptés par le backend
 */

echo "=== Test des Pupitres Acceptés ===\n\n";

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

// Liste des pupitres à tester
$voiceParts = [
    'soprano', 'SOPRANO', 'SOPRANE',
    'alto', 'ALTO',
    'tenor', 'TENOR', 'TÉNOR',
    'basse', 'BASSE',
    'tutti', 'TUTTI',
    'baritone', 'BARITONE', 'BARITON',
    'mezzo-soprano', 'MEZZO-SOPRANO', 'MEZZOSOPRANE'
];

echo "2. Test des différents pupitres\n\n";

foreach ($voiceParts as $voicePart) {
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
        echo "   ✅ SUCCÈS: Pupitre '$voicePart' accepté\n";
    } elseif ($response['code'] == 422) {
        if ($response['body'] && isset($response['body']['errors']['voice_part'])) {
            echo "   ❌ ERREUR: " . implode(', ', $response['body']['errors']['voice_part']) . "\n";
        } else {
            echo "   ❌ ERREUR 422: Validation échouée\n";
        }
    } else {
        echo "   ❌ ERREUR: Code {$response['code']}\n";
    }
    
    echo "\n";
}

echo "=== Résumé ===\n";
echo "Les pupitres acceptés par le backend sont listés ci-dessus avec ✅\n";
echo "Modifiez la liste dans l'application mobile pour utiliser les bonnes valeurs.\n";

echo "\n=== Fin du test ===\n";
