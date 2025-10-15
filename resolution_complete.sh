#!/bin/bash

echo "🔧 RÉSOLUTION COMPLÈTE - VoXY Box"
echo "=================================="
echo ""

# 1. Nettoyage complet
echo "1. 🧹 Nettoyage complet du projet..."
rm -rf .dart_tool
rm -rf build
rm -rf android/app/build
rm -rf android/build
rm -rf android/.gradle
rm -rf ios/build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -f pubspec.lock

echo "✅ Nettoyage terminé"
echo ""

# 2. Nettoyer le cache pub
echo "2. 🗑️  Nettoyage du cache pub..."
rm -rf ~/.pub-cache/hosted/pub.dev/file_picker-*
rm -rf ~/.pub-cache/hosted/pub.dev/audioplayers-*
rm -rf ~/.pub-cache/hosted/pub.dev/just_audio-*
rm -rf ~/.pub-cache/hosted/pub.dev/audio_service-*

echo "✅ Cache pub nettoyé"
echo ""

# 3. Vérifier la configuration
echo "3. ⚙️  Vérification de la configuration..."
echo "   - file_picker: $(grep 'file_picker:' pubspec.yaml | cut -d' ' -f2)"
echo "   - audioplayers: $(grep 'audioplayers:' pubspec.yaml | cut -d' ' -f2)"
echo "   - just_audio: $(grep 'just_audio:' pubspec.yaml | cut -d' ' -f2)"
echo "   - compileSdk: $(grep 'compileSdk' android/app/build.gradle | cut -d' ' -f2)"
echo "   - targetSdkVersion: $(grep 'targetSdkVersion' android/app/build.gradle | cut -d' ' -f2)"
echo ""

# 4. Créer un script de compilation final
echo "4. 📝 Création du script de compilation final..."
cat > compile_final.sh << 'EOF'
#!/bin/bash
echo "🚀 COMPILATION FINALE VoXY Box"
echo "==============================="

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

# Nettoyer
echo "🧹 Nettoyage final..."
flutter clean

# Installer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get

# Vérifier les dépendances
echo "🔍 Vérification des dépendances..."
flutter pub deps | grep -E "(file_picker|audioplayers|just_audio)" | head -5

# Compiler
echo "🚀 Compilation Android..."
if flutter build apk --debug; then
    echo ""
    echo "✅ COMPILATION RÉUSSIE !"
    echo ""
    echo "📱 APK généré dans: build/app/outputs/flutter-apk/"
    echo "   - app-debug.apk"
    echo ""
    echo "🎉 Votre application VoXY Box est prête !"
    echo ""
    echo "📋 Fonctionnalités disponibles:"
    echo "   ✅ Système unifié de partitions"
    echo "   ✅ Upload multi-fichiers (audio, PDF, image)"
    echo "   ✅ Lecteur audio intégré"
    echo "   ✅ Synchronisation automatique"
    echo "   ✅ Mode hors ligne"
    echo ""
    echo "📱 Pour installer sur téléphone:"
    echo "   flutter run --debug"
else
    echo ""
    echo "❌ Erreur de compilation"
    echo ""
    echo "🔧 Solutions:"
    echo "   1. Vérifiez les logs d'erreur ci-dessus"
    echo "   2. Essayez: flutter build apk --debug --no-tree-shake-icons"
    echo "   3. Vérifiez: flutter doctor"
    echo "   4. Consultez GUIDE_RESOLUTION_FINAL.md"
fi
EOF

chmod +x compile_final.sh
echo "✅ Script de compilation final créé: compile_final.sh"
echo ""

# 5. Instructions finales
echo "5. 📋 Instructions finales..."
echo ""
echo "🎯 PROCHAINES ÉTAPES:"
echo ""
echo "1. 🔧 Dans un terminal avec Flutter configuré:"
echo "   ./compile_final.sh"
echo ""
echo "2. 📱 Pour tester sur téléphone:"
echo "   flutter run --debug"
echo ""
echo "3. 🚨 Si Flutter n'est pas accessible:"
echo "   - Redémarrez votre terminal"
echo "   - Vérifiez le PATH: echo \$PATH"
echo "   - Installez Flutter: ./install_flutter.sh"
echo ""
echo "✅ Résolution complète terminée !"
echo ""
echo "📞 Support: Consultez GUIDE_RESOLUTION_FINAL.md"
