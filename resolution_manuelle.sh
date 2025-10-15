#!/bin/bash

echo "🔧 RÉSOLUTION MANUELLE - VoXY Box"
echo "=================================="
echo ""

# 1. Nettoyage complet manuel
echo "1. 🧹 Nettoyage manuel complet..."
rm -rf .dart_tool
rm -rf build
rm -rf android/app/build
rm -rf android/build
rm -rf android/.gradle
rm -rf ios/build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -f pubspec.lock

echo "✅ Nettoyage manuel terminé"
echo ""

# 2. Nettoyer le cache pub
echo "2. 🗑️  Nettoyage du cache pub..."
rm -rf ~/.pub-cache/hosted/pub.dev/file_picker-*
rm -rf ~/.pub-cache/hosted/pub.dev/audioplayers-*
rm -rf ~/.pub-cache/hosted/pub.dev/just_audio-*

echo "✅ Cache pub nettoyé"
echo ""

# 3. Vérifier la configuration
echo "3. ⚙️  Vérification de la configuration..."
echo "   - file_picker version: $(grep 'file_picker:' pubspec.yaml | cut -d' ' -f2)"
echo "   - compileSdk: $(grep 'compileSdk' android/app/build.gradle | cut -d' ' -f2)"
echo "   - targetSdkVersion: $(grep 'targetSdkVersion' android/app/build.gradle | cut -d' ' -f2)"
echo "   - Gradle version: $(grep 'distributionUrl' android/gradle/wrapper/gradle-wrapper.properties | cut -d'-' -f2 | cut -d'-' -f1)"
echo ""

# 4. Créer un script de compilation
echo "4. 📝 Création du script de compilation..."
cat > compile_voxbox.sh << 'EOF'
#!/bin/bash
echo "🚀 COMPILATION VoXY Box"
echo "======================="

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter non trouvé"
    echo "💡 Solutions:"
    echo "   1. Redémarrez votre terminal"
    echo "   2. Vérifiez le PATH: echo \$PATH"
    echo "   3. Installez Flutter: ./install_flutter.sh"
    exit 1
fi

echo "✅ Flutter trouvé: $(flutter --version | head -1)"
echo ""

# Nettoyer et compiler
echo "🧹 Nettoyage..."
flutter clean

echo "📦 Installation des dépendances..."
flutter pub get

echo "🚀 Compilation Android..."
if flutter build apk --debug; then
    echo ""
    echo "✅ COMPILATION RÉUSSIE !"
    echo "📱 APK généré dans: build/app/outputs/flutter-apk/"
    echo ""
    echo "🎉 Votre application VoXY Box est prête !"
else
    echo ""
    echo "❌ Erreur de compilation"
    echo ""
    echo "🔧 Solutions:"
    echo "   1. Vérifiez les logs d'erreur ci-dessus"
    echo "   2. Essayez: flutter build apk --debug --no-tree-shake-icons"
    echo "   3. Vérifiez: flutter doctor"
fi
EOF

chmod +x compile_voxbox.sh
echo "✅ Script de compilation créé: compile_voxbox.sh"
echo ""

# 5. Créer un script de test sur téléphone
echo "5. 📱 Création du script de test téléphone..."
cat > test_telephone.sh << 'EOF'
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
EOF

chmod +x test_telephone.sh
echo "✅ Script de test téléphone créé: test_telephone.sh"
echo ""

# 6. Instructions finales
echo "6. 📋 Instructions finales..."
echo ""
echo "🎯 PROCHAINES ÉTAPES:"
echo ""
echo "1. 🔧 Dans un terminal avec Flutter configuré:"
echo "   ./compile_voxbox.sh"
echo ""
echo "2. 📱 Pour tester sur téléphone:"
echo "   ./test_telephone.sh"
echo ""
echo "3. 🚨 Si Flutter n'est pas accessible:"
echo "   - Redémarrez votre terminal"
echo "   - Vérifiez le PATH: echo \$PATH"
echo "   - Installez Flutter: ./install_flutter.sh"
echo ""
echo "✅ Résolution manuelle terminée !"
echo ""
echo "📞 Support: Consultez RESOLUTION_DEFINITIVE_FILE_PICKER.md"
