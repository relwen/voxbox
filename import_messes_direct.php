<?php
// Script d'importation directe des messes via Laravel

// Inclure l'autoloader de Laravel
require_once __DIR__ . '/voxbobackend/vendor/autoload.php';

// Charger l'application Laravel
$app = require_once __DIR__ . '/voxbobackend/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

// Utiliser les modèles Laravel
use App\Models\Messe;
use App\Models\MesseSection;
use App\Models\ChantDeMesse;

try {
    echo "🚀 Début de l'importation directe des messes...\n";
    
    // 1. Supprimer les données existantes
    echo "🗑️  Suppression des données existantes...\n";
    
    ChantDeMesse::truncate();
    MesseSection::truncate();
    Messe::truncate();
    
    echo "✅ Données existantes supprimées\n";
    
    // 2. Créer le dossier de stockage
    $storagePath = __DIR__ . '/voxbobackend/storage/app/public/partitions';
    if (!is_dir($storagePath)) {
        mkdir($storagePath, 0755, true);
        echo "✅ Dossier de stockage créé: $storagePath\n";
    }
    
    // 3. Analyser les fichiers PDF
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
    
    // 4. Insérer les données directement dans la base
    echo "\n💾 Insertion des données dans la base...\n";
    
    foreach ($messes as $messeData) {
        // Créer la messe
        $messe = Messe::create([
            'nom' => $messeData['name'],
            'description' => "Messe importée automatiquement depuis ChoraleSaver",
            'date' => date('Y-m-d'),
            'active' => true
        ]);
        
        echo "✅ Messe créée: {$messeData['name']} (ID: {$messe->id})\n";
        
        // Créer les sections
        foreach ($messeData['sections'] as $index => $sectionData) {
            $section = MesseSection::create([
                'messe_id' => $messe->id,
                'nom' => $sectionData['name'],
                'description' => "Section {$sectionData['name']} de la messe {$messeData['name']}",
                'ordre' => $index + 1,
                'active' => true
            ]);
            
            echo "  ✅ Section créée: {$sectionData['name']} (ID: {$section->id})\n";
            
            // Créer le chant (partition)
            $chant = ChantDeMesse::create([
                'section_id' => $section->id,
                'titre' => $sectionData['name'],
                'description' => "Partition {$sectionData['name']} de la messe {$messeData['name']}",
                'pdf_path' => 'partitions/' . $sectionData['file'],
                'ordre' => 1,
                'active' => true
            ]);
            
            echo "    ✅ Chant créé: {$sectionData['name']} (ID: {$chant->id}) - Fichier: {$sectionData['file']}\n";
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
    
    // 5. Vérifier l'importation
    echo "\n🔍 Vérification de l'importation...\n";
    $messeCount = Messe::count();
    $sectionCount = MesseSection::count();
    $chantCount = ChantDeMesse::count();
    
    echo "  - Messes en base: $messeCount\n";
    echo "  - Sections en base: $sectionCount\n";
    echo "  - Chants en base: $chantCount\n";
    
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    echo "Stack trace: " . $e->getTraceAsString() . "\n";
}
?>
