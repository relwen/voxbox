#!/bin/bash

echo "🔧 Test de Compilation VoXY Box"
echo "==============================="

# 1. Vérifier Flutter
echo "1. Vérification Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé ou pas dans le PATH"
    echo "   Installez Flutter depuis: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter trouvé: $(flutter --version | head -n 1)"

# 2. Vérifier l'état du projet
echo "2. Vérification du projet..."
flutter doctor

# 3. Analyser le code
echo "3. Analyse du code..."
flutter analyze

# 4. Tester la compilation
echo "4. Test de compilation..."
echo "   Compilation en cours (cela peut prendre quelques minutes)..."

if flutter build apk --debug --verbose; then
    echo ""
    echo "🎉 SUCCÈS ! La compilation a réussi !"
    echo "📱 APK généré dans: build/app/outputs/flutter-apk/"
    echo ""
    echo "✅ Votre application VoXY Box est prête !"
else
    echo ""
    echo "❌ ÉCHEC de la compilation"
    echo "📋 Consultez les erreurs ci-dessus"
    echo "🔧 Essayez le script de nettoyage: ./clean_project.sh"
    echo ""
fi
