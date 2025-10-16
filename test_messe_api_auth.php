<?php

// Test de l'API des messes avec authentification
$baseURL = 'http://192.168.11.107:8000';

echo "🧪 Test de l'API des Messes avec Authentification\n";
echo "================================================\n\n";

// Étape 1: Connexion
echo "1. 🔐 Connexion...\n";
$loginData = json_encode([
    'email' => 'admin@voxy.com',
    'password' => 'admin123'
]);

$context = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => 'Content-Type: application/json',
        'content' => $loginData
    ]
]);

$response = file_get_contents("$baseURL/api/login", false, $context);
$loginResult = json_decode($response, true);

if ($loginResult && $loginResult['success']) {
    $token = $loginResult['data']['token'];
    echo "✅ Connexion réussie! Token: " . substr($token, 0, 20) . "...\n\n";
    
    // Étape 2: Récupérer les messes
    echo "2. 📋 Récupération des messes...\n";
    $context = stream_context_create([
        'http' => [
            'method' => 'GET',
            'header' => "Authorization: Bearer $token\r\nContent-Type: application/json"
        ]
    ]);
    
    $response = file_get_contents("$baseURL/api/messes", false, $context);
    $data = json_decode($response, true);
    
    if ($data && $data['success']) {
        echo "✅ Succès! " . count($data['data']) . " messes trouvées:\n";
        foreach ($data['data'] as $messe) {
            echo "   - {$messe['nom']} (ID: {$messe['id']})\n";
            echo "     Couleur: {$messe['couleur']}\n";
            echo "     Sections: " . (isset($messe['sections']) ? count($messe['sections']) : 0) . "\n";
        }
    } else {
        echo "❌ Erreur: " . ($data['message'] ?? 'Réponse invalide') . "\n";
        echo "Réponse brute: " . $response . "\n";
    }
    
} else {
    echo "❌ Erreur de connexion: " . ($loginResult['message'] ?? 'Réponse invalide') . "\n";
    echo "Réponse brute: " . $response . "\n";
}

echo "\n🎉 Test terminé!\n";
?>
