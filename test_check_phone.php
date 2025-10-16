<?php

/**
 * Script de test pour l'endpoint de vérification du numéro de téléphone
 */

echo "=== Test de Vérification du Numéro de Téléphone ===\n\n";

// Configuration
$baseUrl = 'http://localhost:8000';
$apiUrl = $baseUrl . '/api/check-phone';

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
    
    return array(
        'code' => $httpCode,
        'body' => json_decode($response, true),
        'raw_body' => $response,
        'error' => $error
    );
}

// Test avec différents numéros
$testPhones = array(
    '+22670123456', // Numéro qui pourrait exister
    '+22670123457', // Numéro qui pourrait ne pas exister
    '+22670123458', // Numéro qui pourrait ne pas exister
);

echo "2. Test avec différents numéros\n\n";

foreach ($testPhones as $phone) {
    echo "Test avec numéro: '$phone'\n";
    
    $testData = array(
        'phone' => $phone
    );
    
    $response = makeRequest($apiUrl, 'POST', $testData);
    
    if ($response['error']) {
        echo "   ❌ ERREUR DE CONNEXION: {$response['error']}\n";
        continue;
    }
    
    echo "   Code HTTP: {$response['code']}\n";
    
    if ($response['code'] == 200) {
        if ($response['body'] && isset($response['body']['success']) && $response['body']['success'] == true) {
            $exists = $response['body']['exists'];
            echo "   ✅ SUCCÈS: Numéro " . ($exists ? "EXISTE" : "N'EXISTE PAS") . "\n";
            if ($exists) {
                echo "      → Redirection vers la connexion (HomePage)\n";
            } else {
                echo "      → Redirection vers l'inscription\n";
            }
        } else {
            echo "   ❌ Structure de réponse incorrecte\n";
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
echo "✅ L'endpoint /api/check-phone doit être implémenté dans le backend\n";
echo "✅ Il doit retourner {\"success\": true, \"exists\": true/false}\n";
echo "✅ Si exists=true → Connexion directe\n";
echo "✅ Si exists=false → Inscription\n";

echo "\n=== Structure de Réponse Attendue ===\n";
echo "{\n";
echo "  \"success\": true,\n";
echo "  \"exists\": true,\n";
echo "  \"message\": \"Numéro trouvé\"\n";
echo "}\n";

echo "\n=== Fin du test ===\n";
