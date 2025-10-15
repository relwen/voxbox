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
