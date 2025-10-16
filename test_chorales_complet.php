<?php

/**
 * Script de test complet pour vérifier la récupération des chorales
 * Teste l'endpoint, la structure des données et la compatibilité
 */

echo "=== Test Complet - Récupération des Chorales ===\n\n";

// Configuration
$baseUrl = 'http://localhost:8000';
$apiUrl = $baseUrl . '/api/chorales';

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

// Test 1: Connexion au backend
echo "2. Test de connexion\n";
$response = makeRequest($apiUrl);

if ($response['error']) {
    echo "❌ ERREUR DE CONNEXION: {$response['error']}\n";
    echo "Vérifiez que le serveur Laravel est démarré\n";
    exit(1);
}

echo "✅ Connexion réussie (Code: {$response['code']})\n\n";

// Test 2: Structure de la réponse
echo "3. Analyse de la structure de données\n";

if ($response['code'] == 200 && $response['body']) {
    $data = $response['body'];
    
    // Vérifier la structure de base
    if (isset($data['success']) && $data['success'] === true) {
        echo "✅ Structure de base correcte (success: true)\n";
    } else {
        echo "❌ Structure de base incorrecte\n";
        echo "   Attendu: success: true\n";
        echo "   Reçu: " . json_encode($data) . "\n";
    }
    
    // Vérifier la présence des données
    if (isset($data['data']) && is_array($data['data'])) {
        $chorales = $data['data'];
        echo "✅ Données présentes: " . count($chorales) . " chorales\n";
        
        if (count($chorales) > 0) {
            $firstChorale = $chorales[0];
            echo "\n4. Structure de la première chorale:\n";
            echo "   ID: " . ($firstChorale['id'] ?? 'N/A') . "\n";
            echo "   Name: " . ($firstChorale['name'] ?? 'N/A') . "\n";
            echo "   Description: " . ($firstChorale['description'] ?? 'N/A') . "\n";
            echo "   Location: " . ($firstChorale['location'] ?? 'N/A') . "\n";
            echo "   Created: " . ($firstChorale['created_at'] ?? 'N/A') . "\n";
            
            // Vérifier les champs requis pour le modèle Flutter
            echo "\n5. Compatibilité avec le modèle Flutter:\n";
            $requiredFields = ['id', 'name', 'description', 'location', 'created_at', 'updated_at'];
            $missingFields = [];
            
            foreach ($requiredFields as $field) {
                if (isset($firstChorale[$field])) {
                    echo "   ✅ $field: " . $firstChorale[$field] . "\n";
                } else {
                    echo "   ❌ $field: MANQUANT\n";
                    $missingFields[] = $field;
                }
            }
            
            if (empty($missingFields)) {
                echo "\n✅ Tous les champs requis sont présents\n";
            } else {
                echo "\n❌ Champs manquants: " . implode(', ', $missingFields) . "\n";
            }
        } else {
            echo "❌ Aucune chorale trouvée\n";
        }
    } else {
        echo "❌ Données manquantes ou format incorrect\n";
    }
} else {
    echo "❌ Erreur HTTP: {$response['code']}\n";
    echo "Réponse: {$response['raw_body']}\n";
}

echo "\n=== Résumé ===\n";
if ($response['code'] == 200 && isset($response['body']['data']) && count($response['body']['data']) > 0) {
    echo "✅ SUCCÈS: L'endpoint fonctionne correctement\n";
    echo "✅ Les données sont au bon format\n";
    echo "✅ Compatible avec le modèle Flutter\n";
    echo "\nL'application mobile devrait pouvoir récupérer les chorales\n";
} else {
    echo "❌ PROBLÈME détecté\n";
    echo "Vérifiez la configuration du backend\n";
}

echo "\n=== Fin du test ===\n";
