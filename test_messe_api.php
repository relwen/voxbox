<?php

// Test de l'API des messes
$baseURL = 'http://192.168.11.107:8000';

echo "🧪 Test de l'API des Messes\n";
echo "============================\n\n";

// Test 1: Récupérer toutes les messes
echo "1. 📋 Récupération des messes...\n";
$response = file_get_contents("$baseURL/api/messes");
$data = json_decode($response, true);

if ($data && $data['success']) {
    echo "✅ Succès! " . count($data['data']) . " messes trouvées:\n";
    foreach ($data['data'] as $messe) {
        echo "   - {$messe['nom']} (ID: {$messe['id']})\n";
        echo "     Couleur: {$messe['couleur']}\n";
        echo "     Sections: " . (isset($messe['sections']) ? count($messe['sections']) : 0) . "\n";
    }
} else {
    echo "❌ Erreur: " . ($data['message'] ?? 'Réponse invalide') . "\n";
}

echo "\n";

// Test 2: Récupérer les sections d'une messe
if (isset($data['data'][0])) {
    $messeId = $data['data'][0]['id'];
    echo "2. 📂 Récupération des sections de la messe ID $messeId...\n";
    
    $response = file_get_contents("$baseURL/api/messes/$messeId/sections");
    $sectionsData = json_decode($response, true);
    
    if ($sectionsData && $sectionsData['success']) {
        echo "✅ Succès! " . count($sectionsData['data']) . " sections trouvées:\n";
        foreach ($sectionsData['data'] as $section) {
            echo "   - {$section['nom']} (ID: {$section['id']})\n";
            echo "     Ordre: {$section['ordre']}\n";
            echo "     Chants: " . (isset($section['chants']) ? count($section['chants']) : 0) . "\n";
        }
    } else {
        echo "❌ Erreur: " . ($sectionsData['message'] ?? 'Réponse invalide') . "\n";
    }
}

echo "\n";

// Test 3: Récupérer les chants d'une section
if (isset($sectionsData['data'][0])) {
    $sectionId = $sectionsData['data'][0]['id'];
    echo "3. 🎵 Récupération des chants de la section ID $sectionId...\n";
    
    $response = file_get_contents("$baseURL/api/messe-sections/$sectionId/chants");
    $chantsData = json_decode($response, true);
    
    if ($chantsData && $chantsData['success']) {
        echo "✅ Succès! " . count($chantsData['data']) . " chants trouvés:\n";
        foreach ($chantsData['data'] as $chant) {
            echo "   - {$chant['titre']} (ID: {$chant['id']})\n";
            echo "     Audio: " . ($chant['audio_path'] ? 'Oui' : 'Non') . "\n";
            echo "     PDF: " . ($chant['pdf_path'] ? 'Oui' : 'Non') . "\n";
            echo "     Image: " . ($chant['image_path'] ? 'Oui' : 'Non') . "\n";
        }
    } else {
        echo "❌ Erreur: " . ($chantsData['message'] ?? 'Réponse invalide') . "\n";
    }
}

echo "\n";
echo "🎉 Test terminé!\n";
?>
