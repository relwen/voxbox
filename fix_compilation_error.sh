#!/bin/bash

echo "🔧 Résolution de l'erreur de compilation Flutter"
echo "================================================"

# 1. Nettoyer complètement le projet
echo "1. Nettoyage complet du projet..."
flutter clean
rm -rf .dart_tool
rm -rf build
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -f pubspec.lock

# 2. Nettoyer le cache Flutter
echo "2. Nettoyage du cache Flutter..."
flutter pub cache clean

# 3. Nettoyer le cache Gradle
echo "3. Nettoyage du cache Gradle..."
if [ -d "android" ]; then
    cd android
    ./gradlew clean 2>/dev/null || echo "Gradle clean ignoré"
    cd ..
fi

# 4. Supprimer les dossiers de build Android
echo "4. Suppression des builds Android..."
rm -rf android/app/build
rm -rf android/build
rm -rf android/.gradle

# 5. Réinstaller les dépendances avec les versions compatibles
echo "5. Réinstallation des dépendances..."
flutter pub get

# 6. Vérifier l'installation
echo "6. Vérification Flutter..."
flutter doctor

echo ""
echo "✅ Nettoyage terminé !"
echo ""
echo "🚀 Maintenant, essayez de compiler :"
echo "   flutter build apk --debug"
echo ""
echo "📋 Si l'erreur persiste, essayez :"
echo "   flutter build apk --debug --no-tree-shake-icons"
echo ""
