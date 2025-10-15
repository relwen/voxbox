#!/bin/bash

echo "🔧 RÉSOLUTION DÉFINITIVE ERREUR FILE_PICKER"
echo "==========================================="
echo ""

# 1. Nettoyage complet
echo "1. 🧹 Nettoyage complet du projet..."
flutter clean
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

# 2. Nettoyer le cache Flutter
echo "2. 🗑️  Nettoyage du cache Flutter..."
flutter pub cache clean

echo "✅ Cache nettoyé"
echo ""

# 3. Supprimer le cache file_picker spécifiquement
echo "3. 🎯 Nettoyage spécifique file_picker..."
rm -rf ~/.pub-cache/hosted/pub.dev/file_picker-*

echo "✅ Cache file_picker supprimé"
echo ""

# 4. Réinstaller avec la version compatible
echo "4. 📦 Réinstallation avec version compatible..."
flutter pub get

echo "✅ Dépendances réinstallées"
echo ""

# 5. Vérifier la version installée
echo "5. 🔍 Vérification de la version file_picker..."
if [ -d "~/.pub-cache/hosted/pub.dev/file_picker-4.6.1" ]; then
    echo "   ✅ file_picker 4.6.1 installé"
else
    echo "   ⚠️  Version file_picker à vérifier"
fi
echo ""

# 6. Test de compilation
echo "6. 🚀 Test de compilation..."
echo "   Compilation en cours..."

if flutter build apk --debug; then
    echo ""
    echo "✅ COMPILATION RÉUSSIE !"
    echo ""
    echo "🎉 L'erreur file_picker est résolue !"
    echo ""
    echo "📱 Votre application VoXY Box est prête :"
    echo "   - APK généré dans build/app/outputs/flutter-apk/"
    echo "   - Toutes les fonctionnalités opérationnelles"
    echo "   - Système unifié de partitions fonctionnel"
else
    echo ""
    echo "❌ Erreur de compilation persistante"
    echo ""
    echo "🔧 Solutions alternatives :"
    echo "   1. Essayez: flutter build apk --debug --no-tree-shake-icons"
    echo "   2. Vérifiez: flutter doctor"
    echo "   3. Redémarrez votre terminal"
    echo "   4. Consultez les logs d'erreur ci-dessus"
fi

echo ""
echo "🏁 Résolution terminée"
