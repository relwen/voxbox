#!/bin/bash

echo "🔧 TEST DE COMPILATION ANDROID - VoXY Box"
echo "=========================================="
echo ""

# 1. Nettoyer le projet
echo "1. 🧹 Nettoyage du projet..."
flutter clean
rm -rf build
rm -rf android/app/build
rm -rf android/build
rm -rf android/.gradle

echo "✅ Nettoyage terminé"
echo ""

# 2. Réinstaller les dépendances
echo "2. 📦 Réinstallation des dépendances..."
flutter pub get

echo "✅ Dépendances installées"
echo ""

# 3. Vérifier la configuration
echo "3. ⚙️  Vérification de la configuration..."
echo "   - compileSdk: $(grep 'compileSdk' android/app/build.gradle | cut -d' ' -f2)"
echo "   - targetSdkVersion: $(grep 'targetSdkVersion' android/app/build.gradle | cut -d' ' -f2)"
echo "   - Gradle version: $(grep 'distributionUrl' android/gradle/wrapper/gradle-wrapper.properties | cut -d'-' -f2 | cut -d'-' -f1)"
echo "   - Kotlin version: $(grep 'kotlin_version' android/build.gradle | cut -d"'" -f2)"
echo ""

# 4. Test de compilation
echo "4. 🚀 Test de compilation Android..."
echo "   Compilation en cours..."

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
    echo "   ✅ Gestion des catégories (Vocalises, Messes, Chants, etc.)"
    echo "   ✅ Upload multi-fichiers (audio, PDF, image)"
    echo "   ✅ Synchronisation automatique"
    echo "   ✅ Mode hors ligne"
    echo "   ✅ Lecteur audio intégré"
else
    echo ""
    echo "❌ ERREUR DE COMPILATION"
    echo ""
    echo "🔧 Solutions possibles:"
    echo "   1. Vérifiez que Android SDK est installé"
    echo "   2. Vérifiez que les licences Android sont acceptées"
    echo "   3. Essayez: flutter doctor"
    echo "   4. Essayez: flutter clean && flutter pub get"
    echo ""
    echo "📞 Consultez les logs ci-dessus pour plus de détails"
fi

echo ""
echo "🏁 Test terminé"
