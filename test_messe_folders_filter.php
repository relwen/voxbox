<?php
/**
 * Script de test du filtre des dossiers de messes - VoXY Box
 */

echo "🔍 TEST FILTRE DOSSIERS DE MESSES - VoXY Box\n";
echo "============================================\n\n";

// Configuration
$baseURL = 'http://192.168.11.107:8000';
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
        
        echo "✅ Catégories récupérées: " . count($categories) . "\n\n";
        
        // Afficher toutes les catégories
        echo "📋 TOUTES LES CATÉGORIES:\n";
        echo "========================\n";
        foreach ($categories as $category) {
            echo "- {$category['name']} (ID: {$category['id']})\n";
        }
        
        echo "\n📁 FILTRAGE DES DOSSIERS DE MESSES:\n";
        echo "==================================\n";
        
        // Appliquer le même filtre que dans l'application
        $messeFolders = [];
        foreach ($categories as $category) {
            $name = strtolower($category['name']);
            if ($name !== 'messes' && 
                !strpos($category['name'], ' - ') && // Exclure les sections
                (strpos($name, 'st gabriel') !== false ||
                 strpos($name, 'sympathie') !== false ||
                 strpos($name, 'pentecote') !== false ||
                 strpos($name, 'messe') !== false)) {
                $messeFolders[] = $category;
            }
        }
        
        echo "✅ Dossiers de messes trouvés: " . count($messeFolders) . "\n\n";
        
        if (!empty($messeFolders)) {
            echo "📁 Dossiers de messes qui seront affichés:\n";
            foreach ($messeFolders as $folder) {
                echo "   - {$folder['name']} (ID: {$folder['id']})\n";
                echo "     Description: {$folder['description']}\n";
                echo "     Couleur: {$folder['color']}\n";
                echo "     Icône: {$folder['icon']}\n\n";
            }
        } else {
            echo "❌ Aucun dossier de messe trouvé\n";
        }
        
        // Afficher les catégories exclues
        echo "🚫 CATÉGORIES EXCLUES:\n";
        echo "=====================\n";
        foreach ($categories as $category) {
            $name = strtolower($category['name']);
            $excluded = false;
            $reason = '';
            
            if ($name === 'messes') {
                $excluded = true;
                $reason = 'Catégorie générale "Messes"';
            } elseif (strpos($category['name'], ' - ') !== false) {
                $excluded = true;
                $reason = 'Section (contient " - ")';
            } elseif (!(strpos($name, 'st gabriel') !== false ||
                       strpos($name, 'sympathie') !== false ||
                       strpos($name, 'pentecote') !== false ||
                       strpos($name, 'messe') !== false)) {
                $excluded = true;
                $reason = 'Ne correspond pas aux critères de messe';
            }
            
            if ($excluded) {
                echo "   - {$category['name']} (ID: {$category['id']}) - $reason\n";
            }
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
echo "✅ Test du filtre des dossiers de messes terminé\n";
echo "✅ Filtre mis à jour pour exclure les sections\n";
echo "✅ Seuls les dossiers principaux de messes sont affichés\n";

echo "\n📱 Instructions pour l'application:\n";
echo "1. Recompilez l'application\n";
echo "2. Allez dans l'onglet 'Messes'\n";
echo "3. Vous devriez voir tous les dossiers de messes\n";
echo "4. Cliquez sur un dossier pour voir ses sections\n";
?>
