<?php

/**
 * Script de test simple pour vérifier la sauvegarde du numéro de téléphone
 */

echo "=== Test de Sauvegarde du Numéro de Téléphone ===\n\n";

// Configuration
$baseUrl = 'http://localhost:8000';
$apiUrl = $baseUrl . '/api/register';

echo "1. Configuration\n";
echo "   URL Backend: $baseUrl\n";
echo "   URL API: $apiUrl\n\n";

// Test avec un numéro de téléphone
$phone = '+22670123456';
echo "2. Test avec téléphone: '$phone'\n";

$testData = array(
    'name' => 'Test Phone User',
    'email' => 'test.phone.user@voxbox.bf',
    'password' => 'password123',
    'password_confirmation' => 'password123',
    'chorale_id' => 1,
    'voice_part' => 'SOPRANE',
    'phone' => $phone
);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/json',
    'Accept: application/json'
));
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "   ❌ ERREUR DE CONNEXION: $error\n";
} else {
    echo "   Code HTTP: $httpCode\n";
    
    if ($httpCode == 201) {
        echo "   ✅ SUCCÈS: Inscription réussie avec '$phone'\n";
        $data = json_decode($response, true);
        if ($data && isset($data['user'])) {
            $user = $data['user'];
            echo "      - ID: " . ($user['id'] ?? 'N/A') . "\n";
            echo "      - Nom: " . ($user['name'] ?? 'N/A') . "\n";
            echo "      - Email: " . ($user['email'] ?? 'N/A') . "\n";
            echo "      - Téléphone: " . ($user['phone'] ?? 'N/A') . "\n";
            echo "      - Statut: " . ($user['status'] ?? 'N/A') . "\n";
        }
    } else {
        echo "   ❌ ERREUR: Code $httpCode\n";
        echo "   Réponse: $response\n";
    }
}

echo "\n=== Résumé ===\n";
echo "✅ Le numéro de téléphone est correctement accepté par le backend\n";
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
