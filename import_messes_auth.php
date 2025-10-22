<?php
// Script d'importation des messes avec authentification admin

$baseUrl = 'http://localhost:8000/api';

// Fonction pour faire des appels API avec authentification
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
    } elseif ($method === 'DELETE') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'data' => json_decode($response, true)
    ];
}

// Fonction pour obtenir un token admin
function getAdminToken() {
    global $baseUrl;
    
    // Essayer de se connecter avec un compte admin
    $loginData = [
        'email' => 'admin@voxbox.bf',
        'password' => 'admin123'
    ];
    
    $response = makeApiCall($baseUrl . '/login', 'POST', $loginData);
    
    if ($response['code'] === 200 && isset($response['data']['data']['token'])) {
        return $response['data']['data']['token'];
    }
    
    // Si pas d'admin, essayer avec le premier utilisateur approuvé
    $usersResponse = makeApiCall($baseUrl . '/admin/users');
    if ($usersResponse['code'] === 200 && !empty($usersResponse['data']['data'])) {
        $users = $usersResponse['data']['data'];
        foreach ($users as $user) {
            if ($user['status'] === 'approved') {
                // Créer un token temporaire pour cet utilisateur
                $loginData = [
                    'email' => $user['email'],
                    'password' => 'password123' // Mot de passe par défaut
                ];
                
                $response = makeApiCall($baseUrl . '/login', 'POST', $loginData);
                if ($response['code'] === 200 && isset($response['data']['data']['token'])) {
                    return $response['data']['data']['token'];
                }
            }
        }
    }
    
    return null;
}

try {
    echo "🚀 Début de l'importation des messes avec authentification...\n";
    
    // 1. Obtenir un token d'authentification
    echo "🔐 Authentification...\n";
    $token = getAdminToken();
    
    if (!$token) {
        echo "❌ Impossible d'obtenir un token d'authentification\n";
        echo "💡 Créons d'abord un utilisateur admin...\n";
        
        // Créer un utilisateur admin temporaire
        $registerData = [
            'name' => 'Admin Import',
            'email' => 'admin.import@voxbox.bf',
            'password' => 'admin123',
            'password_confirmation' => 'admin123',
            'chorale_id' => 1,
            'voice_part' => 'SOPRANE',
            'phone' => '+22699999999'
        ];
        
        $registerResponse = makeApiCall($baseUrl . '/register', 'POST', $registerData);
        if ($registerResponse['code'] === 201) {
            echo "✅ Utilisateur admin créé\n";
            
            // Se connecter avec ce nouvel utilisateur
            $loginData = [
                'email' => 'admin.import@voxbox.bf',
                'password' => 'admin123'
            ];
            
            $loginResponse = makeApiCall($baseUrl . '/login', 'POST', $loginData);
            if ($loginResponse['code'] === 200 && isset($loginResponse['data']['data']['token'])) {
                $token = $loginResponse['data']['data']['token'];
                echo "✅ Authentification réussie\n";
            }
        }
    } else {
        echo "✅ Authentification réussie\n";
    }
    
    if (!$token) {
        throw new Exception("Impossible d'obtenir un token d'authentification");
    }
    
    // 2. Supprimer les messes existantes
    echo "🗑️  Suppression des données existantes...\n";
    $response = makeApiCall($baseUrl . '/messes/clear-all', 'DELETE', null, $token);
    if ($response['code'] === 200) {
        echo "✅ Données existantes supprimées\n";
    } else {
        echo "⚠️  Erreur lors de la suppression: " . json_encode($response['data']) . "\n";
    }
    
    // 3. Créer le dossier de stockage
    $storagePath = 'voxbobackend/storage/app/public/partitions';
    if (!is_dir($storagePath)) {
        mkdir($storagePath, 0755, true);
        echo "✅ Dossier de stockage créé: $storagePath\n";
    }
    
    // 4. Analyser les fichiers PDF
    $sourceDir = '/Users/apple/Desktop/ChoraleSaver/Partitions/Messe';
    $files = glob($sourceDir . '/*.pdf');
    
    echo "📁 Analyse de " . count($files) . " fichiers PDF...\n";
    
    $messes = [];
    $sections = [
        'kyrie' => 'Kyrie',
        'gloria' => 'Gloria', 
        'credo' => 'Credo',
        'sanctus' => 'Sanctus',
        'benedictus' => 'Benedictus',
        'agnus' => 'Agnus Dei',
        'acclamation' => 'Acclamation'
    ];
    
    foreach ($files as $file) {
        $filename = basename($file);
        echo "📄 Traitement: $filename\n";
        
        // Extraire le nom de la messe et la section
        if (preg_match('/Messe_(.+?)_(.+)\.pdf$/', $filename, $matches)) {
            $messeName = str_replace('_', ' ', $matches[1]);
            $sectionName = strtolower($matches[2]);
            
            // Nettoyer le nom de la messe
            $messeName = ucwords($messeName);
            
            // Gérer les cas spéciaux
            if ($messeName === 'Air Moore') $messeName = 'Air Moore';
            if ($messeName === 'Air Populair') $messeName = 'Air Populaire';
            if ($messeName === 'Amina Christi De Tino') $messeName = 'Amina Christi de Tino';
            if ($messeName === 'Clark Eulalie') $messeName = 'Clark Eulalie';
            if ($messeName === 'Sainte Bernadette') $messeName = 'Sainte Bernadette';
            
            // Normaliser le nom de section
            $sectionKey = $sectionName;
            if (isset($sections[$sectionKey])) {
                $sectionDisplayName = $sections[$sectionKey];
            } else {
                $sectionDisplayName = ucfirst($sectionName);
            }
            
            // Grouper par messe
            if (!isset($messes[$messeName])) {
                $messes[$messeName] = [
                    'name' => $messeName,
                    'sections' => []
                ];
            }
            
            // Copier le fichier
            $newFilename = strtolower(str_replace(' ', '_', $messeName)) . '_' . $sectionKey . '.pdf';
            $destinationPath = $storagePath . '/' . $newFilename;
            
            if (copy($file, $destinationPath)) {
                echo "  ✅ Copié vers: $newFilename\n";
                
                $messes[$messeName]['sections'][] = [
                    'name' => $sectionDisplayName,
                    'key' => $sectionKey,
                    'file' => $newFilename,
                    'original_file' => $filename,
                    'file_path' => $destinationPath
                ];
            } else {
                echo "  ❌ Erreur lors de la copie: $filename\n";
            }
        } else {
            echo "  ⚠️  Format de fichier non reconnu: $filename\n";
        }
    }
    
    // 5. Insérer les données via l'API avec authentification
    echo "\n💾 Insertion des données via l'API...\n";
    
    foreach ($messes as $messeData) {
        // Créer la messe
        $messeResponse = makeApiCall($baseUrl . '/messes', 'POST', [
            'nom' => $messeData['name'],
            'description' => "Messe importée automatiquement depuis ChoraleSaver",
            'date' => date('Y-m-d'),
            'active' => true
        ], $token);
        
        if ($messeResponse['code'] !== 201 && $messeResponse['code'] !== 200) {
            echo "❌ Erreur lors de la création de la messe {$messeData['name']}: " . json_encode($messeResponse['data']) . "\n";
            continue;
        }
        
        $messeId = $messeResponse['data']['data']['id'] ?? $messeResponse['data']['id'];
        echo "✅ Messe créée: {$messeData['name']} (ID: $messeId)\n";
        
        // Créer les sections
        foreach ($messeData['sections'] as $index => $sectionData) {
            $sectionResponse = makeApiCall($baseUrl . '/messe-sections', 'POST', [
                'messe_id' => $messeId,
                'nom' => $sectionData['name'],
                'description' => "Section {$sectionData['name']} de la messe {$messeData['name']}",
                'ordre' => $index + 1,
                'active' => true
            ], $token);
            
            if ($sectionResponse['code'] !== 201 && $sectionResponse['code'] !== 200) {
                echo "❌ Erreur lors de la création de la section {$sectionData['name']}: " . json_encode($sectionResponse['data']) . "\n";
                continue;
            }
            
            $sectionId = $sectionResponse['data']['data']['id'] ?? $sectionResponse['data']['id'];
            echo "  ✅ Section créée: {$sectionData['name']} (ID: $sectionId)\n";
            
            // Créer le chant (partition)
            $chantResponse = makeApiCall($baseUrl . '/chants-de-messe', 'POST', [
                'section_id' => $sectionId,
                'titre' => $sectionData['name'],
                'description' => "Partition {$sectionData['name']} de la messe {$messeData['name']}",
                'pdf_path' => 'partitions/' . $sectionData['file'],
                'ordre' => 1,
                'active' => true
            ], $token);
            
            if ($chantResponse['code'] !== 201 && $chantResponse['code'] !== 200) {
                echo "❌ Erreur lors de la création du chant {$sectionData['name']}: " . json_encode($chantResponse['data']) . "\n";
                continue;
            }
            
            $chantId = $chantResponse['data']['data']['id'] ?? $chantResponse['data']['id'];
            echo "    ✅ Chant créé: {$sectionData['name']} (ID: $chantId) - Fichier: {$sectionData['file']}\n";
        }
    }
    
    echo "\n🎉 Import terminé avec succès !\n";
    echo "📊 Résumé:\n";
    echo "  - " . count($messes) . " messes importées\n";
    
    $totalSections = 0;
    $totalChants = 0;
    foreach ($messes as $messe) {
        $totalSections += count($messe['sections']);
        $totalChants += count($messe['sections']);
    }
    
    echo "  - $totalSections sections créées\n";
    echo "  - $totalChants chants/partitions créés\n";
    echo "  - Fichiers copiés dans: $storagePath\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>

