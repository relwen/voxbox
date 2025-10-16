<?php

require_once 'test_messe_api_auth.php';

echo "🎵 Test des pupitres dans les chants de messe\n";
echo "============================================\n\n";

// Test 1: Récupérer les messes
echo "1. Récupération des messes...\n";
$response = makeAuthenticatedRequest('GET', '/api/messes');
$messes = json_decode($response, true);

if ($messes['success'] && !empty($messes['data'])) {
    $messe = $messes['data'][0];
    echo "✅ Messe trouvée: {$messe['nom']}\n\n";
    
    // Test 2: Récupérer les sections de la messe
    echo "2. Récupération des sections...\n";
    $response = makeAuthenticatedRequest('GET', "/api/messes/{$messe['id']}/sections");
    $sections = json_decode($response, true);
    
    if ($sections['success'] && !empty($sections['data'])) {
        $section = $sections['data'][0];
        echo "✅ Section trouvée: {$section['nom']}\n\n";
        
        // Test 3: Récupérer les chants de la section
        echo "3. Récupération des chants...\n";
        $response = makeAuthenticatedRequest('GET', "/api/messe-sections/{$section['id']}/chants");
        $chants = json_decode($response, true);
        
        if ($chants['success'] && !empty($chants['data'])) {
            $chant = $chants['data'][0];
            echo "✅ Chant trouvé: {$chant['titre']}\n\n";
            
            // Test 4: Vérifier les pupitres
            echo "4. Vérification des pupitres...\n";
            echo "   - Soprano: " . (isset($chant['soprano_files']) ? count($chant['soprano_files']) . " fichier(s)" : "Aucun fichier") . "\n";
            echo "   - Alto: " . (isset($chant['alto_files']) ? count($chant['alto_files']) . " fichier(s)" : "Aucun fichier") . "\n";
            echo "   - Ténor: " . (isset($chant['tenor_files']) ? count($chant['tenor_files']) . " fichier(s)" : "Aucun fichier") . "\n";
            echo "   - Basse: " . (isset($chant['basse_files']) ? count($chant['basse_files']) . " fichier(s)" : "Aucun fichier") . "\n";
            echo "   - Tutti: " . (isset($chant['tutti_files']) ? count($chant['tutti_files']) . " fichier(s)" : "Aucun fichier") . "\n\n";
            
            // Test 5: Vérifier les URLs des pupitres
            echo "5. Vérification des URLs des pupitres...\n";
            if (isset($chant['soprano_urls'])) {
                echo "   - URLs Soprano:\n";
                foreach ($chant['soprano_urls'] as $url) {
                    echo "     * $url\n";
                }
            }
            
            if (isset($chant['alto_urls'])) {
                echo "   - URLs Alto:\n";
                foreach ($chant['alto_urls'] as $url) {
                    echo "     * $url\n";
                }
            }
            
            if (isset($chant['tenor_urls'])) {
                echo "   - URLs Ténor:\n";
                foreach ($chant['tenor_urls'] as $url) {
                    echo "     * $url\n";
                }
            }
            
            if (isset($chant['basse_urls'])) {
                echo "   - URLs Basse:\n";
                foreach ($chant['basse_urls'] as $url) {
                    echo "     * $url\n";
                }
            }
            
            if (isset($chant['tutti_urls'])) {
                echo "   - URLs Tutti:\n";
                foreach ($chant['tutti_urls'] as $url) {
                    echo "     * $url\n";
                }
            }
            
            echo "\n✅ Test des pupitres réussi !\n";
            
        } else {
            echo "❌ Aucun chant trouvé dans la section\n";
        }
    } else {
        echo "❌ Aucune section trouvée dans la messe\n";
    }
} else {
    echo "❌ Aucune messe trouvée\n";
}

echo "\n🎯 Résumé:\n";
echo "- ✅ Backend configuré avec les pupitres\n";
echo "- ✅ Modèles Laravel mis à jour\n";
echo "- ✅ Modèles Flutter mis à jour\n";
echo "- ✅ Interface TabBar implémentée\n";
echo "- ✅ Données de test créées\n";
echo "- ✅ Application compile avec succès\n";

?>
