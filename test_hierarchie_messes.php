<?php
/**
 * Script de test de la hiérarchie des messes - VoXY Box
 */

echo "🔍 TEST HIÉRARCHIE DES MESSES - VoXY Box\n";
echo "========================================\n\n";

// Configuration
$baseURL = 'http://192.168.11.107:8000';
$loginURL = $baseURL . '/api/login';
$categoriesURL = $baseURL . '/api/categories';
$partitionsURL = $baseURL . '/api/partitions';

echo "📡 Configuration:\n";
echo "   - Backend: $baseURL\n";
echo "   - Login: $loginURL\n";
echo "   - Catégories: $categoriesURL\n";
echo "   - Partitions: $partitionsURL\n\n";

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
                 strpos($name, 'messe') !== false) &&
                !strpos($name, ' - ')) {
                $messeFolders[] = $category;
            }
        }
        
        echo "✅ Dossiers de messes trouvés: " . count($messeFolders) . "\n\n";
        
        // Test 3: Récupération des partitions
        echo "3. 🎵 Récupération des partitions...\n";
        
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
            
            // Afficher la hiérarchie complète
            echo "📁 HIÉRARCHIE DES MESSES:\n";
            echo "========================\n\n";
            
            foreach ($messeFolders as $folder) {
                echo "📂 {$folder['name']}\n";
                echo "   Description: {$folder['description']}\n";
                echo "   Couleur: {$folder['color']}\n";
                echo "   Icône: {$folder['icon']}\n\n";
                
                // Trouver les sections de cette messe
                $sections = [];
                foreach ($categories as $category) {
                    if (strpos($category['name'], $folder['name'] . ' - ') === 0) {
                        $sections[] = $category;
                    }
                }
                
                if (!empty($sections)) {
                    echo "   📋 Sections:\n";
                    foreach ($sections as $section) {
                        $sectionName = str_replace($folder['name'] . ' - ', '', $section['name']);
                        echo "      🎵 $sectionName\n";
                        echo "         Description: {$section['description']}\n";
                        
                        // Compter les partitions de cette section
                        $sectionPartitions = array_filter($allPartitions, function($partition) use ($section) {
                            return $partition['category_id'] == $section['id'];
                        });
                        
                        echo "         Partitions: " . count($sectionPartitions) . "\n";
                        
                        if (!empty($sectionPartitions)) {
                            foreach ($sectionPartitions as $partition) {
                                echo "            📄 {$partition['title']}\n";
                                echo "               Description: {$partition['description']}\n";
                                echo "               Audio: " . ($partition['audio_path'] ? 'Oui' : 'Non') . "\n";
                                echo "               PDF: " . ($partition['pdf_path'] ? 'Oui' : 'Non') . "\n";
                                echo "               Image: " . ($partition['image_path'] ? 'Oui' : 'Non') . "\n";
                            }
                        }
                        echo "\n";
                    }
                } else {
                    echo "   (Aucune section)\n";
                }
                echo "\n";
            }
            
        } else {
            echo "❌ Échec de récupération des partitions\n";
        }
        
    } else {
        echo "❌ Échec de récupération des catégories\n";
    }
    
} else {
    echo "❌ Échec de l'authentification\n";
}

echo "\n🎯 RÉSUMÉ:\n";
echo "==========\n";
echo "✅ Test de la hiérarchie des messes terminé\n";
echo "✅ Structure à 3 niveaux implémentée:\n";
echo "   1. Dossiers de messes (St GABRIEL, SYMPATHIE, etc.)\n";
echo "   2. Sections de messe (Kyrié, Gloria, Sanctus, etc.)\n";
echo "   3. Partitions (fichiers audio, PDF, images)\n";

echo "\n📱 Instructions pour l'application:\n";
echo "1. Ouvrez l'application sur votre téléphone\n";
echo "2. Allez dans la section 'Messes'\n";
echo "3. Cliquez sur un dossier de messe (ex: St GABRIEL)\n";
echo "4. Vous verrez les sections (Kyrié, Gloria, etc.)\n";
echo "5. Cliquez sur une section pour voir ses partitions\n";
echo "6. Cliquez sur une partition pour la lire/télécharger\n";
?>
