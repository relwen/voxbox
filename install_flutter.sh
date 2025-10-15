#!/bin/bash

echo "🚀 INSTALLATION AUTOMATIQUE FLUTTER - VoXY Box"
echo "=============================================="
echo ""

# Vérifier si Flutter est déjà installé
if command -v flutter &> /dev/null; then
    echo "✅ Flutter est déjà installé !"
    flutter --version
    echo ""
    echo "🔧 Vérification de la configuration..."
    flutter doctor
    exit 0
fi

echo "📥 Téléchargement de Flutter SDK..."
cd ~/Downloads

# Télécharger Flutter
echo "   - Téléchargement en cours..."
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.5-stable.zip

if [ ! -f "flutter_macos_arm64_3.24.5-stable.zip" ]; then
    echo "❌ Erreur: Impossible de télécharger Flutter"
    exit 1
fi

echo "✅ Téléchargement terminé"
echo ""

echo "📦 Extraction de Flutter..."
unzip -q flutter_macos_arm64_3.24.5-stable.zip

if [ ! -d "flutter" ]; then
    echo "❌ Erreur: Impossible d'extraire Flutter"
    exit 1
fi

echo "✅ Extraction terminée"
echo ""

echo "🔧 Installation de Flutter..."
sudo mv flutter /usr/local/

if [ ! -d "/usr/local/flutter" ]; then
    echo "❌ Erreur: Impossible d'installer Flutter"
    exit 1
fi

echo "✅ Installation terminée"
echo ""

echo "⚙️  Configuration du PATH..."
# Ajouter Flutter au PATH
echo 'export PATH="/usr/local/flutter/bin:$PATH"' >> ~/.zshrc

# Recharger la configuration
source ~/.zshrc

echo "✅ PATH configuré"
echo ""

echo "🔍 Vérification de l'installation..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter installé avec succès !"
    echo ""
    flutter --version
    echo ""
    echo "🏥 Diagnostic Flutter..."
    flutter doctor
    echo ""
    echo "🎯 Test de compilation VoXY Box..."
    cd /Users/apple/Desktop/Tech/KuilingaTechnologies/ProjectHouse/voxbox
    flutter clean
    flutter pub get
    echo ""
    echo "🚀 Tentative de compilation..."
    flutter build apk --debug
    echo ""
    echo "🎉 INSTALLATION TERMINÉE !"
    echo ""
    echo "📋 Prochaines étapes :"
    echo "   1. Vérifiez que 'flutter doctor' ne montre pas d'erreurs"
    echo "   2. Si Android SDK manque, installez Android Studio"
    echo "   3. Votre application VoXY Box devrait maintenant compiler !"
else
    echo "❌ Erreur: Flutter n'est pas accessible"
    echo ""
    echo "🔧 Solutions :"
    echo "   1. Redémarrez votre terminal"
    echo "   2. Vérifiez le PATH: echo \$PATH"
    echo "   3. Rechargez la configuration: source ~/.zshrc"
fi

echo ""
echo "📞 Support: Consultez GUIDE_INSTALLATION_FLUTTER.md pour plus d'aide"
