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
