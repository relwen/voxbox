#!/bin/bash

echo "🧹 Nettoyage du projet VoXY Box"
echo "================================"

# 1. Nettoyer Flutter
echo "1. Nettoyage Flutter..."
flutter clean

# 2. Supprimer les dossiers de cache
echo "2. Suppression des caches..."
rm -rf .dart_tool
rm -rf build
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

# 3. Supprimer le fichier de verrouillage des dépendances
echo "3. Suppression du fichier de verrouillage..."
rm -f pubspec.lock

# 4. Nettoyer le cache Gradle (Android)
echo "4. Nettoyage Gradle..."
if [ -d "android" ]; then
    cd android
    ./gradlew clean 2>/dev/null || echo "Gradle clean ignoré (pas de Gradle)"
    cd ..
fi

# 5. Nettoyer les pods iOS (si sur macOS)
echo "5. Nettoyage iOS..."
if [ -d "ios" ] && [[ "$OSTYPE" == "darwin"* ]]; then
    cd ios
    rm -rf Pods
    rm -f Podfile.lock
    cd ..
fi

# 6. Réinstaller les dépendances
echo "6. Réinstallation des dépendances..."
flutter pub get

# 7. Vérifier l'installation
echo "7. Vérification Flutter..."
flutter doctor

echo ""
echo "✅ Nettoyage terminé !"
echo "🚀 Vous pouvez maintenant essayer de compiler :"
echo "   flutter build apk --debug"
echo ""
