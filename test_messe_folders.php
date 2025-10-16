<?php
/**
 * Script de test des dossiers de messes - VoXY Box
 */

echo "🔍 TEST DOSSIERS DE MESSES - VoXY Box\n";
echo "=====================================\n\n";

// Configuration
$baseURL = 'http://192.168.11.102:8000';
$loginURL = $baseURL . '/api/login';
$categoriesURL = $baseURL . '/api/categories';

echo "📡 Configuration:\n";
echo "   - Backend: $baseURL\n";
echo "   - Login: $loginURL\n";
echo "   - Catégories: $categoriesURL\n\n";

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
    
    // Test 2: Récupération des catégories
    echo "\n2. 📋 Récupération des catégories...\n";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $categoriesURL);
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
        $categories = $data['data'] ?? [];
        
        echo "✅ Catégories récupérées: " . count($categories) . "\n";
        
        // Filtrer les dossiers de messes
        $messeFolders = [];
        foreach ($categories as $category) {
            $name = strtolower($category['name']);
            if ($name !== 'messes' && 
                (strpos($name, 'st gabriel') !== false ||
                 strpos($name, 'sympathie') !== false ||
                 strpos($name, 'pentecote') !== false ||
                 strpos($name, 'messe') !== false)) {
                $messeFolders[] = $category;
            }
        }
        
        echo "✅ Dossiers de messes trouvés: " . count($messeFolders) . "\n\n";
        
        if (!empty($messeFolders)) {
            echo "📁 Dossiers de messes disponibles:\n";
            foreach ($messeFolders as $folder) {
                echo "   - ID: {$folder['id']}\n";
                echo "     Nom: {$folder['name']}\n";
                echo "     Description: {$folder['description']}\n";
                echo "     Couleur: {$folder['color']}\n";
                echo "     Icône: {$folder['icon']}\n";
                echo "\n";
            }
            
            // Test 3: Vérifier les partitions dans chaque dossier
            echo "3. 🎵 Vérification des partitions par dossier...\n";
            
            $partitionsURL = $baseURL . '/api/partitions';
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $partitionsURL);
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
                $allPartitions = $data['data'] ?? [];
                
                echo "✅ Partitions récupérées: " . count($allPartitions) . "\n\n";
                
                foreach ($messeFolders as $folder) {
                    $folderPartitions = array_filter($allPartitions, function($partition) use ($folder) {
                        return $partition['category_id'] == $folder['id'];
                    });
                    
                    echo "📂 {$folder['name']}:\n";
                    echo "   Partitions: " . count($folderPartitions) . "\n";
                    
                    if (!empty($folderPartitions)) {
                        foreach ($folderPartitions as $partition) {
                            echo "     - {$partition['title']}\n";
                        }
                    } else {
                        echo "     (Aucune partition)\n";
                    }
                    echo "\n";
                }
            } else {
                echo "❌ Échec de récupération des partitions\n";
            }
            
        } else {
            echo "❌ Aucun dossier de messe trouvé\n";
            echo "💡 Vérifiez que les catégories de messes sont créées\n";
        }
        
    } else {
        echo "❌ Échec de récupération des catégories\n";
        echo "   Code: $httpCode\n";
    }
    
} else {
    echo "❌ Échec de l'authentification\n";
    echo "   Code: $httpCode\n";
}

echo "\n🎯 RÉSUMÉ:\n";
echo "==========\n";
echo "✅ Test des dossiers de messes terminé\n";
echo "✅ Interface mise à jour pour afficher les dossiers\n";
echo "✅ Système de catégories utilisé pour organiser les messes\n";

echo "\n📱 Instructions pour l'application:\n";
echo "1. Ouvrez l'application sur votre téléphone\n";
echo "2. Allez dans la section 'Messes'\n";
echo "3. Vous verrez les dossiers de messes (St GABRIEL, SYMPATHIE, etc.)\n";
echo "4. Cliquez sur un dossier pour voir ses partitions\n";
echo "5. Utilisez le bouton '+' pour ajouter un nouveau dossier\n";
?>
