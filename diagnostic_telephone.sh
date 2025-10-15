#!/bin/bash

echo "📱 DIAGNOSTIC COMPILATION TÉLÉPHONE - VoXY Box"
echo "=============================================="
echo ""

# 1. Vérifier Flutter
echo "1. 🔍 Vérification Flutter..."
if command -v flutter &> /dev/null; then
    echo "   ✅ Flutter trouvé"
    flutter --version
    echo ""
    
    # 2. Vérifier les appareils connectés
    echo "2. 📱 Appareils connectés..."
    flutter devices
    echo ""
    
    # 3. Vérifier la configuration
    echo "3. ⚙️  Configuration du projet..."
    echo "   - compileSdk: $(grep 'compileSdk' android/app/build.gradle | cut -d' ' -f2)"
    echo "   - targetSdkVersion: $(grep 'targetSdkVersion' android/app/build.gradle | cut -d' ' -f2)"
    echo "   - minSdkVersion: $(grep 'minSdkVersion' android/app/build.gradle | cut -d' ' -f2)"
    echo ""
    
    # 4. Vérifier les permissions
    echo "4. 🔐 Vérification des permissions..."
    if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
        echo "   ✅ AndroidManifest.xml trouvé"
        echo "   - Permissions:"
        grep -n "uses-permission" android/app/src/main/AndroidManifest.xml | sed 's/^/     /'
    else
        echo "   ❌ AndroidManifest.xml manquant"
    fi
    echo ""
    
    # 5. Test de compilation
    echo "5. 🚀 Test de compilation..."
    echo "   Nettoyage en cours..."
    flutter clean
    flutter pub get
    
    echo "   Tentative de compilation..."
    if flutter run --debug; then
        echo ""
        echo "✅ COMPILATION RÉUSSIE !"
        echo "   Votre application est en cours d'exécution sur le téléphone"
    else
        echo ""
        echo "❌ ERREUR DE COMPILATION"
        echo ""
        echo "🔧 Solutions possibles:"
        echo "   1. Vérifiez que le téléphone est connecté et reconnu"
        echo "   2. Activez le mode développeur sur le téléphone"
        echo "   3. Activez le débogage USB"
        echo "   4. Vérifiez les permissions dans AndroidManifest.xml"
        echo "   5. Essayez: flutter clean && flutter pub get"
    fi
    
else
    echo "   ❌ Flutter NON TROUVÉ"
    echo ""
    echo "📋 Solutions:"
    echo "   1. Installez Flutter: ./install_flutter.sh"
    echo "   2. Redémarrez votre terminal"
    echo "   3. Vérifiez le PATH: echo \$PATH"
fi

echo ""
echo "🏁 Diagnostic terminé"
