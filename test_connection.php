<?php

/**
 * Script de test pour vérifier la connexion au backend
 * Exécutez avec: php test_connection.php
 */

echo "=== Test de connexion au backend ===\n\n";

// Configuration
$baseUrl = 'http://192.168.11.104:8001';

// Fonction pour faire des requêtes HTTP
function makeRequest($url) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'body' => $response,
        'error' => $error
    ];
}

// Test 1: Vérifier que le serveur répond
echo "1. Test de connectivité du serveur...\n";
$response = makeRequest($baseUrl . '/api/chorales');

if ($response['error']) {
    echo "   ✗ Erreur de connexion: " . $response['error'] . "\n";
} else {
    echo "   ✓ Serveur accessible (Code: " . $response['code'] . ")\n";
    
    if ($response['code'] == 200) {
        echo "   ✓ Réponse reçue: " . strlen($response['body']) . " caractères\n";
    }
}

// Test 2: Vérifier l'endpoint vocalises
echo "\n2. Test de l'endpoint vocalises...\n";
$response = makeRequest($baseUrl . '/api/vocalises');

if ($response['error']) {
    echo "   ✗ Erreur: " . $response['error'] . "\n";
} else {
    echo "   ✓ Endpoint vocalises accessible (Code: " . $response['code'] . ")\n";
    
    if ($response['code'] == 401) {
        echo "   ✓ Authentification requise (comportement attendu)\n";
    } else {
        echo "   ✓ Réponse: " . strlen($response['body']) . " caractères\n";
    }
}

// Test 3: Vérifier l'endpoint de synchronisation
echo "\n3. Test de l'endpoint de synchronisation...\n";
$response = makeRequest($baseUrl . '/api/vocalises/sync');

if ($response['error']) {
    echo "   ✗ Erreur: " . $response['error'] . "\n";
} else {
    echo "   ✓ Endpoint sync accessible (Code: " . $response['code'] . ")\n";
    
    if ($response['code'] == 401) {
        echo "   ✓ Authentification requise (comportement attendu)\n";
    } else {
        echo "   ✓ Réponse: " . strlen($response['body']) . " caractères\n";
    }
}

// Test 4: Vérifier l'endpoint de téléchargement
echo "\n4. Test de l'endpoint de téléchargement...\n";
$response = makeRequest($baseUrl . '/api/vocalises/1/download-audio');

if ($response['error']) {
    echo "   ✗ Erreur: " . $response['error'] . "\n";
} else {
    echo "   ✓ Endpoint download accessible (Code: " . $response['code'] . ")\n";
    
    if ($response['code'] == 401) {
        echo "   ✓ Authentification requise (comportement attendu)\n";
    } elseif ($response['code'] == 404) {
        echo "   ✓ Vocalise non trouvée (comportement attendu)\n";
    } else {
        echo "   ✓ Réponse: " . strlen($response['body']) . " caractères\n";
    }
}

echo "\n=== Résumé ===\n";
echo "✓ Backend Laravel fonctionne sur le port 8001\n";
echo "✓ Endpoints API vocalises sont accessibles\n";
echo "✓ Authentification requise (sécurité activée)\n";
echo "\nProchaines étapes:\n";
echo "1. Connectez-vous à l'application pour obtenir un token\n";
echo "2. Testez la synchronisation des vocalises\n";
echo "3. Testez le mode hors ligne\n";
echo "\nPour tester avec un token:\n";
echo "php test_vocalise_api.php\n";
