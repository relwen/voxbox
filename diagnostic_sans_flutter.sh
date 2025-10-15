#!/bin/bash

echo "🔍 DIAGNOSTIC SANS FLUTTER - VoXY Box"
echo "====================================="
echo ""

# 1. Vérifier la structure du projet
echo "1. 📁 Structure du projet..."
echo "   - pubspec.yaml: $([ -f "pubspec.yaml" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - lib/: $([ -d "lib" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - android/: $([ -d "android" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - ios/: $([ -d "ios" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo ""

# 2. Analyser pubspec.yaml
echo "2. 📋 Analyse pubspec.yaml..."
if [ -f "pubspec.yaml" ]; then
    echo "   ✅ Fichier trouvé"
    echo "   - Nom: $(grep '^name:' pubspec.yaml | cut -d' ' -f2)"
    echo "   - Version Flutter: $(grep 'flutter:' pubspec.yaml -A 1 | grep 'sdk:' | cut -d' ' -f4)"
    echo "   - file_picker: $(grep 'file_picker:' pubspec.yaml | cut -d' ' -f2)"
    echo "   - audioplayers: $(grep 'audioplayers:' pubspec.yaml | cut -d' ' -f2)"
    echo "   - Dépendances totales: $(grep -c '^  [a-z]' pubspec.yaml)"
else
    echo "   ❌ pubspec.yaml MANQUANT"
fi
echo ""

# 3. Vérifier les fichiers Android
echo "3. 🤖 Configuration Android..."
echo "   - build.gradle: $([ -f "android/app/build.gradle" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - AndroidManifest.xml: $([ -f "android/app/src/main/AndroidManifest.xml" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - gradle-wrapper.properties: $([ -f "android/gradle/wrapper/gradle-wrapper.properties" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"

if [ -f "android/app/build.gradle" ]; then
    echo "   - compileSdk: $(grep 'compileSdk' android/app/build.gradle | cut -d' ' -f2)"
    echo "   - targetSdkVersion: $(grep 'targetSdkVersion' android/app/build.gradle | cut -d' ' -f2)"
fi

if [ -f "android/gradle/wrapper/gradle-wrapper.properties" ]; then
    echo "   - Gradle version: $(grep 'distributionUrl' android/gradle/wrapper/gradle-wrapper.properties | cut -d'-' -f2 | cut -d'-' -f1)"
fi
echo ""

# 4. Vérifier les permissions Android
echo "4. 🔐 Permissions Android..."
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    permissions=$(grep -c 'uses-permission' android/app/src/main/AndroidManifest.xml)
    echo "   - Permissions: $permissions ajoutées"
    if [ "$permissions" -gt 0 ]; then
        echo "   - Détail des permissions:"
        grep 'uses-permission' android/app/src/main/AndroidManifest.xml | sed 's/^/     /'
    fi
else
    echo "   ❌ AndroidManifest.xml MANQUANT"
fi
echo ""

# 5. Vérifier les fichiers de code
echo "5. 💻 Fichiers de code..."
echo "   - main.dart: $([ -f "lib/main.dart" ] && echo "✅ Trouvé" || echo "❌ MANQUANT")"
echo "   - models/: $([ -d "lib/models" ] && echo "✅ Trouvé ($(ls lib/models/*.dart 2>/dev/null | wc -l) fichiers)" || echo "❌ MANQUANT")"
echo "   - services/: $([ -d "lib/services" ] && echo "✅ Trouvé ($(ls lib/services/*.dart 2>/dev/null | wc -l) fichiers)" || echo "❌ MANQUANT")"
echo "   - view/: $([ -d "lib/view" ] && echo "✅ Trouvé ($(ls lib/view/*.dart 2>/dev/null | wc -l) fichiers)" || echo "❌ MANQUANT")"
echo ""

# 6. Vérifier les erreurs potentielles
echo "6. 🚨 Erreurs potentielles..."
echo "   - Cache Flutter: $([ -d ".dart_tool" ] && echo "⚠️  Présent (à nettoyer)" || echo "✅ Absent")"
echo "   - Build Android: $([ -d "android/app/build" ] && echo "⚠️  Présent (à nettoyer)" || echo "✅ Absent")"
echo "   - Build iOS: $([ -d "ios/build" ] && echo "⚠️  Présent (à nettoyer)" || echo "✅ Absent")"
echo ""

# 7. Recommandations
echo "7. 💡 Recommandations..."
echo ""

if ! command -v flutter &> /dev/null; then
    echo "   🚨 PROBLÈME PRINCIPAL: Flutter non accessible"
    echo ""
    echo "   📋 Solutions:"
    echo "   1. Redémarrez votre terminal"
    echo "   2. Vérifiez le PATH: echo \$PATH"
    echo "   3. Installez Flutter: ./install_flutter.sh"
    echo "   4. Utilisez un terminal avec Flutter configuré"
else
    echo "   ✅ Flutter accessible"
    echo ""
    echo "   🔧 Commandes à exécuter:"
    echo "   1. flutter clean"
    echo "   2. flutter pub get"
    echo "   3. flutter build apk --debug"
fi

echo ""
echo "🏁 Diagnostic terminé"
