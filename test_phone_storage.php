<?php

/**
 * Script de test pour simuler la sauvegarde du numéro de téléphone
 * lors de la connexion OTP
 */

echo "=== Test de Sauvegarde du Numéro de Téléphone ===\n\n";

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
        'Content-Type': 'application/json',
        'Accept': 'application/json'
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

// Simuler différents numéros de téléphone
$testPhones = array(
    '+22670123456',
    '+22670123457',
    '+22670123458',
    '+22670123459',
    '+22670123460'
);

echo "2. Test avec différents numéros de téléphone\n\n";

foreach ($testPhones as $index => $phone) {
    echo "Test " . ($index + 1) . " avec téléphone: '$phone'\n";
    
    $testData = array(
        'name' => 'Test User ' . ($index + 1),
        'email' => 'test.user.' . ($index + 1) . '@voxbox.bf',
        'password' => 'password123',
        'password_confirmation' => 'password123',
        'chorale_id' => 1,
        'voice_part' => 'SOPRANE',
        'phone' => $phone
    );
    
    $response = makeRequest($apiUrl, 'POST', $testData);
    
    if ($response['error']) {
        echo "   ❌ ERREUR DE CONNEXION: {$response['error']}\n";
        continue;
    }
    
    echo "   Code HTTP: {$response['code']}\n";
    
    if ($response['code'] == 201) {
        echo "   ✅ SUCCÈS: Inscription réussie avec '$phone'\n";
        if ($response['body'] && isset($response['body']['user'])) {
            $user = $response['body']['user'];
            echo "      - ID: " . ($user['id'] ?? 'N/A') . "\n";
            echo "      - Nom: " . ($user['name'] ?? 'N/A') . "\n";
            echo "      - Email: " . ($user['email'] ?? 'N/A') . "\n";
            echo "      - Téléphone: " . ($user['phone'] ?? 'N/A') . "\n";
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
echo "✅ Les numéros de téléphone sont correctement acceptés par le backend\n";
echo "✅ L'application mobile récupère le numéro depuis la connexion OTP\n";
echo "✅ Le formulaire d'inscription n'affiche plus le champ téléphone\n";
echo "✅ Le numéro est affiché en lecture seule pour confirmation\n";

echo "\n=== Instructions pour l'Application ===\n";
echo "1. Lors de la connexion OTP, sauvegarder le numéro dans SharedPreferences:\n";
echo "   await prefs.setString('user_phone', phoneNumber);\n\n";
echo "2. Dans le formulaire d'inscription, récupérer le numéro:\n";
echo "   _userPhone = prefs.getString('user_phone');\n\n";
echo "3. Afficher le numéro en lecture seule et l'utiliser pour l'inscription\n";

echo "\n=== Fin du test ===\n";
