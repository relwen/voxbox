<?php
/**
 * Script pour vérifier les utilisateurs dans la base de données
 */

echo "👥 VÉRIFICATION DES UTILISATEURS - VoXY Box\n";
echo "===========================================\n\n";

// Se connecter à la base de données SQLite
$dbPath = '/Users/apple/Desktop/Tech/KuilingaTechnologies/ProjectHouse/voxbobackend/database/database.sqlite';

if (!file_exists($dbPath)) {
    echo "❌ Base de données non trouvée: $dbPath\n";
    exit(1);
}

try {
    $pdo = new PDO("sqlite:$dbPath");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "✅ Connexion à la base de données réussie\n\n";
    
    // Récupérer tous les utilisateurs
    $stmt = $pdo->query("SELECT id, name, email, role, status, created_at FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "📊 Nombre d'utilisateurs: " . count($users) . "\n\n";
    
    if (count($users) > 0) {
        echo "👤 Liste des utilisateurs:\n";
        echo "========================\n";
        
        foreach ($users as $user) {
            echo "ID: {$user['id']}\n";
            echo "Nom: {$user['name']}\n";
            echo "Email: {$user['email']}\n";
            echo "Rôle: {$user['role']}\n";
            echo "Statut: {$user['status']}\n";
            echo "Créé: {$user['created_at']}\n";
            echo "---\n";
        }
        
        // Vérifier s'il y a un admin
        $adminUsers = array_filter($users, function($user) {
            return $user['role'] === 'admin';
        });
        
        echo "\n🔑 Utilisateurs administrateurs: " . count($adminUsers) . "\n";
        
        if (count($adminUsers) === 0) {
            echo "⚠️  Aucun utilisateur administrateur trouvé!\n";
            echo "💡 Créez un admin avec:\n";
            echo "   php artisan tinker --execute=\"App\\Models\\User::create(['name' => 'Admin', 'email' => 'admin@voxy.com', 'password' => bcrypt('admin123'), 'role' => 'admin', 'status' => 'approved']);\"\n";
        }
        
    } else {
        echo "❌ Aucun utilisateur trouvé dans la base de données!\n";
        echo "💡 Créez un utilisateur avec:\n";
        echo "   php artisan tinker --execute=\"App\\Models\\User::create(['name' => 'Admin', 'email' => 'admin@voxy.com', 'password' => bcrypt('admin123'), 'role' => 'admin', 'status' => 'approved']);\"\n";
    }
    
} catch (PDOException $e) {
    echo "❌ Erreur de base de données: " . $e->getMessage() . "\n";
} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
}

echo "\n🎯 RÉSUMÉ:\n";
echo "==========\n";
echo "✅ Base de données accessible\n";
echo "📊 Utilisateurs trouvés: " . count($users) . "\n";
echo "🔑 Admins trouvés: " . count($adminUsers ?? []) . "\n";
?>
