<?php
/**
 * Script de test de téléchargement audio - VoXY Box
 */

echo "🔍 TEST TÉLÉCHARGEMENT AUDIO - VoXY Box\n";
echo "=======================================\n\n";

// Configuration
$baseURL = 'http://192.168.11.102:8000';
$loginURL = $baseURL . '/api/login';
$vocalisesURL = $baseURL . '/api/vocalises';

echo "📡 Configuration:\n";
echo "   - Backend: $baseURL\n";
echo "   - Login: $loginURL\n";
echo "   - Vocalises: $vocalisesURL\n\n";

// Test 1: Authentification
echo "1. 🔐 Test d'authentification...\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $loginURL);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'email' => 'admin@voxy.com',
    'password' => 'admin123'
]));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode == 200) {
    $data = json_decode($response, true);
    $token = $data['token'];
    echo "✅ Authentification réussie\n";
    echo "   Token: " . substr($token, 0, 20) . "...\n";
    
    // Test 2: Récupération des vocalises
    echo "\n2. 📋 Récupération des vocalises...\n";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $vocalisesURL);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode == 200) {
        $data = json_decode($response, true);
        $vocalises = $data['data'] ?? [];
        
        echo "✅ Vocalises récupérées: " . count($vocalises) . "\n";
        
        if (!empty($vocalises)) {
            // Test 3: Téléchargement du premier fichier audio
            echo "\n3. 🎵 Test de téléchargement audio...\n";
            
            $firstVocalise = $vocalises[0];
            $vocaliseId = $firstVocalise['id'];
            $audioPath = $firstVocalise['audio_path'] ?? null;
            
            echo "   - ID: $vocaliseId\n";
            echo "   - Titre: " . $firstVocalise['title'] . "\n";
            echo "   - Chemin audio: " . ($audioPath ?? 'AUCUN') . "\n";
            
            if ($audioPath) {
                $downloadURL = $baseURL . '/api/vocalises/' . $vocaliseId . '/download-audio';
                echo "   - URL de téléchargement: $downloadURL\n";
                
                // Télécharger le fichier
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $downloadURL);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_HTTPHEADER, [
                    'Accept: application/json',
                    'Authorization: Bearer ' . $token
                ]);
                curl_setopt($ch, CURLOPT_TIMEOUT, 30);
                
                $audioData = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $error = curl_error($ch);
                curl_close($ch);
                
                if ($httpCode == 200 && !$error) {
                    echo "✅ Téléchargement réussi\n";
                    echo "   Taille: " . strlen($audioData) . " bytes\n";
                    
                    // Sauvegarder le fichier
                    $fileName = "vocalise_{$vocaliseId}.mp3";
                    $filePath = __DIR__ . "/" . $fileName;
                    
                    if (file_put_contents($filePath, $audioData)) {
                        echo "✅ Fichier sauvegardé: $filePath\n";
                        echo "   Taille: " . filesize($filePath) . " bytes\n";
                        echo "   Existe: " . (file_exists($filePath) ? 'OUI' : 'NON') . "\n";
                        
                        // Vérifier le contenu
                        if (filesize($filePath) > 0) {
                            echo "✅ Fichier audio valide\n";
                        } else {
                            echo "❌ Fichier vide\n";
                        }
                    } else {
                        echo "❌ Erreur de sauvegarde\n";
                    }
                } else {
                    echo "❌ Échec du téléchargement\n";
                    echo "   Code: $httpCode\n";
                    if ($error) {
                        echo "   Erreur: $error\n";
                    }
                }
            } else {
                echo "❌ Pas de fichier audio pour cette vocalise\n";
            }
        } else {
            echo "❌ Aucune vocalise trouvée\n";
        }
    } else {
        echo "❌ Échec de récupération des vocalises\n";
        echo "   Code: $httpCode\n";
        echo "   Réponse: $response\n";
    }
} else {
    echo "❌ Échec de l'authentification\n";
    echo "   Code: $httpCode\n";
    echo "   Réponse: $response\n";
}

echo "\n🎯 RÉSUMÉ:\n";
echo "==========\n";
echo "✅ Test terminé\n";
echo "💡 Vérifiez que les fichiers sont téléchargés correctement\n";
echo "💡 Vérifiez que les chemins locaux sont corrects\n";
?>
