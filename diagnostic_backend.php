<?php

/**
 * Script de diagnostic pour vérifier la connectivité au backend
 */

echo "=== Diagnostic Backend ===\n\n";

// Configuration
$baseUrl = 'http://192.168.11.104:8001';
$apiUrl = $baseUrl . '/api';

// Test 1: Vérifier si le serveur répond
echo "1. Test de connectivité au serveur\n";
echo "URL: $baseUrl\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
curl_setopt($ch, CURLOPT_NOBODY, true); // HEAD request seulement

$result = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "✗ ERREUR DE CONNEXION: $error\n";
    echo "Le serveur backend n'est pas accessible à l'adresse $baseUrl\n";
    echo "\nVérifiez que:\n";
    echo "1. Le serveur Laravel est démarré (php artisan serve)\n";
    echo "2. L'adresse IP est correcte (192.168.11.104)\n";
    echo "3. Le port 8001 est ouvert\n";
    echo "4. Le firewall n'bloque pas la connexion\n";
} else {
    echo "✓ Serveur accessible (Code HTTP: $httpCode)\n";
}

echo "\n";

// Test 2: Vérifier l'endpoint API
echo "2. Test de l'endpoint API\n";
echo "URL: $apiUrl\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json'
]);

$result = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "✗ ERREUR API: $error\n";
} else {
    echo "✓ API accessible (Code HTTP: $httpCode)\n";
    if ($result) {
        $data = json_decode($result, true);
        if ($data) {
            echo "Réponse API: " . json_encode($data, JSON_PRETTY_PRINT) . "\n";
        }
    }
}

echo "\n";

// Test 3: Test spécifique des chorales
echo "3. Test spécifique de l'endpoint chorales\n";
echo "URL: $apiUrl/chorales\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl . '/chorales');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json',
    'Content-Type: application/json'
]);

$result = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "✗ ERREUR CHORALES: $error\n";
} else {
    echo "Code HTTP: $httpCode\n";
    
    if ($httpCode == 200) {
        echo "✓ SUCCÈS: Endpoint chorales accessible\n";
        $data = json_decode($result, true);
        if ($data && isset($data['data'])) {
            echo "Nombre de chorales: " . count($data['data']) . "\n";
        }
    } elseif ($httpCode == 401) {
        echo "✗ ERREUR 401: Authentification requise\n";
        echo "PROBLÈME: L'endpoint chorales nécessite une authentification\n";
        echo "SOLUTION: Modifier routes/api.php pour rendre l'endpoint public\n";
    } elseif ($httpCode == 404) {
        echo "✗ ERREUR 404: Endpoint non trouvé\n";
        echo "PROBLÈME: La route /api/chorales n'existe pas\n";
        echo "SOLUTION: Vérifier routes/api.php\n";
    } else {
        echo "✗ ERREUR $httpCode: Problème avec l'endpoint\n";
    }
    
    if ($result) {
        echo "Réponse: " . substr($result, 0, 500) . "\n";
    }
}

echo "\n=== Résumé ===\n";
echo "Si vous obtenez une erreur 401, suivez les instructions dans:\n";
echo "CORRECTION_BACKEND_CHORALES_PUBLIC.md\n";

echo "\n=== Fin du diagnostic ===\n";
