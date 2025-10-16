#!/bin/bash

echo "🚀 DÉMARRAGE BACKEND POUR MOBILE - VoXY Box"
echo "==========================================="
echo ""

# Vérifier si le backend est déjà en cours d'exécution
if lsof -i :8000 > /dev/null 2>&1; then
    echo "⚠️  Le port 8000 est déjà utilisé"
    echo "🔄 Arrêt du processus existant..."
    pkill -f "php artisan serve"
    sleep 2
fi

echo "📡 Démarrage du serveur Laravel..."
echo "   - Host: 0.0.0.0 (accessible depuis le réseau local)"
echo "   - Port: 8000"
echo "   - URL mobile: http://192.168.11.107:8000"
echo ""

# Démarrer le serveur Laravel
cd /Users/apple/Desktop/Tech/KuilingaTechnologies/ProjectHouse/voxbobackend
php artisan serve --host=0.0.0.0 --port=8000

echo ""
echo "✅ Serveur démarré !"
echo "📱 Votre application mobile peut maintenant se connecter à:"
echo "   http://192.168.11.107:8000"