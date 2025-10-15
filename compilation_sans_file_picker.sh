#!/bin/bash

echo "🚀 COMPILATION SANS FILE_PICKER - VoXY Box"
echo "=========================================="
echo ""

# 1. Nettoyer
echo "1. 🧹 Nettoyage..."
fvm flutter clean

# 2. Installer les dépendances
echo "2. 📦 Installation des dépendances..."
fvm flutter pub get

# 3. Vérifier les erreurs de linting
echo "3. 🔍 Vérification des erreurs..."
fvm flutter analyze

# 4. Compiler
echo "4. 🚀 Compilation Android..."
if fvm flutter build apk --debug; then
    echo ""
    echo "✅ COMPILATION RÉUSSIE !"
    echo ""
    echo "📱 APK généré dans: build/app/outputs/flutter-apk/"
    echo "   - app-debug.apk"
    echo ""
    echo "🎉 Application compilée avec succès !"
    echo ""
    echo "📋 Fonctionnalités disponibles:"
    echo "   ✅ Système unifié de partitions"
    echo "   ✅ Upload d'images (via image_picker)"
    echo "   ✅ Lecteur audio intégré"
    echo "   ✅ Synchronisation automatique"
    echo "   ✅ Mode hors ligne"
    echo "   ⚠️  Upload audio/PDF temporairement désactivé"
    echo ""
    echo "📱 Pour installer sur téléphone:"
    echo "   fvm flutter run --debug"
else
    echo ""
    echo "❌ Erreur de compilation"
    echo ""
    echo "🔧 Solutions:"
    echo "   1. Vérifiez les logs d'erreur ci-dessus"
    echo "   2. Essayez: fvm flutter build apk --debug --no-tree-shake-icons"
    echo "   3. Vérifiez: fvm flutter doctor"
fi
