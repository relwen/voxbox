<?php
// Script de test pour vérifier la connexion entre l'app mobile et le backend

$baseUrl = 'http://localhost:8000/api';

// Fonction pour faire des appels API
function makeApiCall($url, $method = 'GET', $data = null, $token = null) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $headers = [
        'Content-Type: application/json',
        'Accept: application/json'
    ];
    
    if ($token) {
        $headers[] = 'Authorization: Bearer ' . $token;
    }
    
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'data' => json_decode($response, true)
    ];
}

try {
    echo "🔍 Test de connexion VoxBox App ↔ Backend\n";
    echo "==========================================\n\n";
    
    // 1. Test des endpoints publics
    echo "1️⃣ Test des endpoints publics...\n";
    
    $response = makeApiCall($baseUrl . '/chorales');
    if ($response['code'] === 200) {
        $chorales = $response['data']['data'] ?? [];
        echo "✅ Chorales accessibles: " . count($chorales) . " chorales trouvées\n";
        foreach ($chorales as $chorale) {
            echo "   - {$chorale['name']} ({$chorale['location']})\n";
        }
    } else {
        echo "❌ Erreur chorales: " . $response['code'] . "\n";
    }
    
    // 2. Test de connexion avec un utilisateur
    echo "\n2️⃣ Test de connexion utilisateur...\n";
    
    $loginData = [
        'email' => 'jacobs@voxbox.bf',
        'password' => 'password123'
    ];
    
    $loginResponse = makeApiCall($baseUrl . '/login', 'POST', $loginData);
    echo "   Réponse de connexion: " . json_encode($loginResponse) . "\n";
    
    if ($loginResponse['code'] === 200 && isset($loginResponse['data']['token'])) {
        $token = $loginResponse['data']['token'];
        echo "✅ Connexion réussie avec jacobs@voxbox.bf\n";
        echo "   Token: " . substr($token, 0, 20) . "...\n";
        
        // 3. Test des endpoints protégés
        echo "\n3️⃣ Test des endpoints protégés...\n";
        
        // Test messes
        $messesResponse = makeApiCall($baseUrl . '/messes', 'GET', null, $token);
        if ($messesResponse['code'] === 200) {
            $messes = $messesResponse['data']['data'] ?? [];
            echo "✅ Messes accessibles: " . count($messes) . " messes trouvées\n";
            foreach ($messes as $messe) {
                echo "   - {$messe['nom']}\n";
            }
        } else {
            echo "❌ Erreur messes: " . $messesResponse['code'] . "\n";
            if (isset($messesResponse['data']['message'])) {
                echo "   Message: " . $messesResponse['data']['message'] . "\n";
            }
        }
        
        // Test sections de messe
        if (!empty($messes)) {
            $firstMesse = $messes[0];
            $sectionsResponse = makeApiCall($baseUrl . '/messes/' . $firstMesse['id'] . '/sections', 'GET', null, $token);
            if ($sectionsResponse['code'] === 200) {
                $sections = $sectionsResponse['data']['data'] ?? [];
                echo "✅ Sections de messe '{$firstMesse['nom']}': " . count($sections) . " sections\n";
                foreach ($sections as $section) {
                    echo "   - {$section['nom']}\n";
                }
            } else {
                echo "❌ Erreur sections: " . $sectionsResponse['code'] . "\n";
            }
        }
        
    } else {
        echo "❌ Erreur de connexion: " . $loginResponse['code'] . "\n";
        if (isset($loginResponse['data']['message'])) {
            echo "   Message: " . $loginResponse['data']['message'] . "\n";
        }
    }
    
    // 4. Test des partitions
    echo "\n4️⃣ Test des partitions...\n";
    
    $partitionsResponse = makeApiCall($baseUrl . '/partitions', 'GET', null, $token ?? null);
    if ($partitionsResponse['code'] === 200) {
        $partitions = $partitionsResponse['data']['data'] ?? [];
        echo "✅ Partitions accessibles: " . count($partitions) . " partitions\n";
    } else {
        echo "❌ Erreur partitions: " . $partitionsResponse['code'] . "\n";
    }
    
    echo "\n🎉 Test terminé !\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
