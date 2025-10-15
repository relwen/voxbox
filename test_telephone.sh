#!/bin/bash
echo "📱 TEST TÉLÉPHONE VoXY Box"
echo "=========================="

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter non trouvé"
    exit 1
fi

# Vérifier les appareils
echo "🔍 Vérification des appareils..."
devices=$(flutter devices 2>/dev/null | grep -c "connected device")
if [ "$devices" -eq 0 ]; then
    echo "❌ Aucun appareil connecté"
    echo ""
    echo "🔧 Solutions:"
    echo "   1. Connectez votre téléphone via USB"
    echo "   2. Activez le mode développeur"
    echo "   3. Activez le débogage USB"
    echo "   4. Autorisez l'ordinateur sur le téléphone"
    exit 1
fi

echo "✅ $devices appareil(s) connecté(s)"
flutter devices | grep "connected device" | sed 's/^/   /'
echo ""

# Compiler et installer
echo "🚀 Compilation et installation..."
if flutter run --debug; then
    echo ""
    echo "✅ INSTALLATION RÉUSSIE !"
    echo "📱 Votre application VoXY Box est installée sur le téléphone"
else
    echo ""
    echo "❌ Erreur d'installation"
    echo "🔧 Consultez les logs d'erreur ci-dessus"
fi
