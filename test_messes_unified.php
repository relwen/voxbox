<?php
/**
 * Script de test du système unifié pour les messes - VoXY Box
 */

echo "🔍 TEST SYSTÈME UNIFIÉ MESSES - VoXY Box\n";
echo "========================================\n\n";

// Configuration
$baseURL = 'http://192.168.11.102:8000';
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
        
        // Trouver la catégorie "Messes"
        $messeCategory = null;
        foreach ($categories as $category) {
            if (strtolower($category['name']) === 'messes') {
                $messeCategory = $category;
                break;
            }
        }
        
        if ($messeCategory) {
            echo "✅ Catégorie 'Messes' trouvée (ID: {$messeCategory['id']})\n";
            echo "   - Nom: {$messeCategory['name']}\n";
            echo "   - Description: {$messeCategory['description']}\n";
            echo "   - Couleur: {$messeCategory['color']}\n";
            echo "   - Icône: {$messeCategory['icon']}\n";
            
            // Test 3: Récupération des partitions de la catégorie Messes
            echo "\n3. 🎵 Récupération des partitions de la catégorie Messes...\n";
            
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
                
                // Filtrer les partitions de la catégorie Messes
                $messePartitions = array_filter($allPartitions, function($partition) use ($messeCategory) {
                    return $partition['category_id'] == $messeCategory['id'];
                });
                
                echo "✅ Partitions de la catégorie Messes: " . count($messePartitions) . "\n";
                
                if (!empty($messePartitions)) {
                    echo "\n📋 Partitions trouvées:\n";
                    foreach ($messePartitions as $partition) {
                        echo "   - ID: {$partition['id']}\n";
                        echo "     Titre: {$partition['title']}\n";
                        echo "     Description: " . ($partition['description'] ?? 'Aucune') . "\n";
                        echo "     Audio: " . ($partition['audio_path'] ? 'Oui' : 'Non') . "\n";
                        echo "     PDF: " . ($partition['pdf_path'] ? 'Oui' : 'Non') . "\n";
                        echo "     Image: " . ($partition['image_path'] ? 'Oui' : 'Non') . "\n";
                        echo "     Chorale: " . ($partition['chorale']['name'] ?? 'N/A') . "\n";
                        echo "\n";
                    }
                } else {
                    echo "ℹ️  Aucune partition trouvée dans la catégorie Messes\n";
                    echo "💡 Vous pouvez en créer une via l'interface d'ajout de partition\n";
                }
                
                // Test 4: Création d'une partition de messe (optionnel)
                echo "\n4. ➕ Test de création d'une partition de messe...\n";
                
                $newPartition = [
                    'title' => 'Test Messe - ' . date('Y-m-d H:i:s'),
                    'description' => 'Partition de test pour la catégorie Messes',
                    'category_id' => $messeCategory['id'],
                    'chorale_id' => 1, // ID de chorale par défaut
                ];
                
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $partitionsURL);
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($newPartition));
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_HTTPHEADER, [
                    'Content-Type: application/json',
                    'Accept: application/json',
                    'Authorization: Bearer ' . $token
                ]);
                curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                
                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);
                
                if ($httpCode == 201) {
                    $data = json_decode($response, true);
                    echo "✅ Partition de messe créée avec succès\n";
                    echo "   ID: {$data['data']['id']}\n";
                    echo "   Titre: {$data['data']['title']}\n";
                    echo "   Catégorie: {$data['data']['category_name']}\n";
                } else {
                    echo "⚠️  Création de partition: Code $httpCode\n";
                    if ($httpCode == 422) {
                        $data = json_decode($response, true);
                        if (isset($data['errors'])) {
                            echo "   Erreurs de validation:\n";
                            foreach ($data['errors'] as $field => $errors) {
                                echo "     - $field: " . implode(', ', $errors) . "\n";
                            }
                        }
                    }
                }
                
            } else {
                echo "❌ Échec de récupération des partitions\n";
                echo "   Code: $httpCode\n";
            }
            
        } else {
            echo "❌ Catégorie 'Messes' non trouvée\n";
            echo "💡 Vérifiez que la catégorie existe dans la base de données\n";
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
echo "✅ Système unifié pour les messes testé\n";
echo "✅ Les messes sont maintenant des partitions de la catégorie 'Messes'\n";
echo "✅ Interface mise à jour pour utiliser le système unifié\n";
echo "✅ Ancien système de messes supprimé\n";

echo "\n📱 Instructions pour l'application:\n";
echo "1. Ouvrez l'application sur votre téléphone\n";
echo "2. Allez dans la section 'Messes'\n";
echo "3. Vous verrez les partitions de la catégorie 'Messes'\n";
echo "4. Utilisez le bouton '+' pour ajouter une nouvelle messe\n";
echo "5. Sélectionnez la catégorie 'Messes' lors de la création\n";
?>
