<?php
// Configuration de la base de données
$host = 'localhost';
$dbname = 'voxbox_db';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "✅ Connexion à la base de données réussie\n";
    
    // 1. Vider les tables existantes
    echo "🗑️  Suppression des données existantes...\n";
    
    $pdo->exec("DELETE FROM chants_de_messe");
    $pdo->exec("DELETE FROM messe_sections");
    $pdo->exec("DELETE FROM messes");
    
    echo "✅ Données supprimées\n";
    
    // 2. Réinitialiser les auto-increment
    $pdo->exec("ALTER TABLE messes AUTO_INCREMENT = 1");
    $pdo->exec("ALTER TABLE messe_sections AUTO_INCREMENT = 1");
    $pdo->exec("ALTER TABLE chants_de_messe AUTO_INCREMENT = 1");
    
    echo "✅ Auto-increment réinitialisés\n";
    
    // 3. Créer le dossier de stockage des partitions
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
                    'original_file' => $filename
                ];
            } else {
                echo "  ❌ Erreur lors de la copie: $filename\n";
            }
        } else {
            echo "  ⚠️  Format de fichier non reconnu: $filename\n";
        }
    }
    
    // 5. Insérer les données dans la base
    echo "\n💾 Insertion des données dans la base...\n";
    
    foreach ($messes as $messeData) {
        // Insérer la messe
        $stmt = $pdo->prepare("INSERT INTO messes (nom, description, date, active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $messeData['name'],
            "Messe importée automatiquement depuis ChoraleSaver",
            date('Y-m-d'),
            1,
            date('Y-m-d H:i:s'),
            date('Y-m-d H:i:s')
        ]);
        
        $messeId = $pdo->lastInsertId();
        echo "✅ Messe créée: {$messeData['name']} (ID: $messeId)\n";
        
        // Insérer les sections
        foreach ($messeData['sections'] as $index => $sectionData) {
            $stmt = $pdo->prepare("INSERT INTO messe_sections (messe_id, nom, description, ordre, active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([
                $messeId,
                $sectionData['name'],
                "Section {$sectionData['name']} de la messe {$messeData['name']}",
                $index + 1,
                1,
                date('Y-m-d H:i:s'),
                date('Y-m-d H:i:s')
            ]);
            
            $sectionId = $pdo->lastInsertId();
            echo "  ✅ Section créée: {$sectionData['name']} (ID: $sectionId)\n";
            
            // Insérer le chant (partition)
            $stmt = $pdo->prepare("INSERT INTO chants_de_messe (section_id, titre, description, pdf_path, ordre, active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([
                $sectionId,
                $sectionData['name'],
                "Partition {$sectionData['name']} de la messe {$messeData['name']}",
                'partitions/' . $sectionData['file'],
                1,
                1,
                date('Y-m-d H:i:s'),
                date('Y-m-d H:i:s')
            ]);
            
            $chantId = $pdo->lastInsertId();
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
    
} catch (PDOException $e) {
    echo "❌ Erreur de base de données: " . $e->getMessage() . "\n";
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}
?>
