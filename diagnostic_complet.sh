#!/bin/bash

echo "🔍 DIAGNOSTIC COMPLET - VoXY Box"
echo "================================="
echo ""

# 1. Vérifier l'environnement
echo "1. 🔧 Vérification de l'environnement..."
echo "   - OS: $(uname -s)"
echo "   - Architecture: $(uname -m)"
echo "   - Shell: $SHELL"
echo ""

# 2. Vérifier Flutter
echo "2. 📱 Vérification Flutter..."
if command -v flutter &> /dev/null; then
    echo "   ✅ Flutter trouvé: $(which flutter)"
    flutter --version
else
    echo "   ❌ Flutter NON TROUVÉ"
    echo "   📋 Solutions possibles:"
    echo "      - Installer Flutter: https://docs.flutter.dev/get-started/install"
    echo "      - Ajouter Flutter au PATH"
    echo "      - Utiliser un terminal avec Flutter configuré"
fi
echo ""

# 3. Vérifier Dart
echo "3. 🎯 Vérification Dart..."
if command -v dart &> /dev/null; then
    echo "   ✅ Dart trouvé: $(which dart)"
    dart --version
else
    echo "   ❌ Dart NON TROUVÉ"
fi
echo ""

# 4. Vérifier les dépendances système
echo "4. 🛠️  Vérification des dépendances..."
echo "   - Java: $(java -version 2>&1 | head -1 || echo 'NON TROUVÉ')"
echo "   - Android SDK: $([ -d "$ANDROID_HOME" ] && echo "✅ Trouvé" || echo "❌ NON TROUVÉ")"
echo "   - Xcode: $(xcode-select -p 2>/dev/null && echo "✅ Trouvé" || echo "❌ NON TROUVÉ")"
echo ""

# 5. Vérifier la structure du projet
echo "5. 📁 Vérification de la structure du projet..."
echo "   - pubspec.yaml: $([ -f "pubspec.yaml" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - lib/: $([ -d "lib" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - android/: $([ -d "android" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - ios/: $([ -d "ios" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo ""

# 6. Vérifier les fichiers de configuration
echo "6. ⚙️  Vérification des fichiers de configuration..."
echo "   - android/app/build.gradle: $([ -f "android/app/build.gradle" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - ios/Runner.xcodeproj: $([ -d "ios/Runner.xcodeproj" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo ""

# 7. Analyser pubspec.yaml
echo "7. 📋 Analyse de pubspec.yaml..."
if [ -f "pubspec.yaml" ]; then
    echo "   ✅ Fichier trouvé"
    echo "   - Nom du projet: $(grep '^name:' pubspec.yaml | cut -d' ' -f2)"
    echo "   - Version Flutter: $(grep 'flutter:' pubspec.yaml -A 1 | grep 'sdk:' | cut -d' ' -f4)"
    echo "   - Dépendances: $(grep -c '^  [a-z]' pubspec.yaml) packages"
else
    echo "   ❌ pubspec.yaml MANQUANT"
fi
echo ""

# 8. Vérifier les permissions
echo "8. 🔐 Vérification des permissions..."
echo "   - Lecture: $([ -r "pubspec.yaml" ] && echo "✅ OK" || echo "❌ PROBLÈME")"
echo "   - Écriture: $([ -w "pubspec.yaml" ] && echo "✅ OK" || echo "❌ PROBLÈME")"
echo "   - Exécution: $([ -x "." ] && echo "✅ OK" || echo "❌ PROBLÈME")"
echo ""

# 9. Recommandations
echo "9. 💡 RECOMMANDATIONS..."
echo ""

if ! command -v flutter &> /dev/null; then
    echo "   🚨 PROBLÈME PRINCIPAL: Flutter non installé"
    echo ""
    echo "   📥 INSTALLATION FLUTTER (macOS):"
    echo "   1. Télécharger Flutter SDK:"
    echo "      https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.5-stable.zip"
    echo ""
    echo "   2. Extraire et configurer:"
    echo "      cd ~/Downloads"
    echo "      unzip flutter_macos_arm64_3.24.5-stable.zip"
    echo "      sudo mv flutter /usr/local/"
    echo "      echo 'export PATH=\"/usr/local/flutter/bin:\$PATH\"' >> ~/.zshrc"
    echo "      source ~/.zshrc"
    echo ""
    echo "   3. Vérifier l'installation:"
    echo "      flutter doctor"
    echo ""
else
    echo "   ✅ Flutter est installé"
    echo "   🔧 Essayez ces commandes:"
    echo "      flutter clean"
    echo "      flutter pub get"
    echo "      flutter build apk --debug"
fi

echo ""
echo "🎯 RÉSUMÉ:"
echo "   - Si Flutter n'est pas installé: INSTALLER FLUTTER"
echo "   - Si Flutter est installé: VÉRIFIER LA CONFIGURATION"
echo "   - Si tout est OK: PROBLÈME DE DÉPENDANCES"
echo ""
echo "📞 Support: Vérifiez que Flutter est correctement installé et configuré"
