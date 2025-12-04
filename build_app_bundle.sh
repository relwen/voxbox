#!/bin/bash

# Script pour générer l'App Bundle signé pour le Play Store

echo "🔧 Nettoyage du projet..."
flutter clean

echo "📦 Récupération des dépendances..."
flutter pub get

echo "🏗️  Génération de l'App Bundle signé..."
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ App Bundle généré avec succès !"
    echo ""
    echo "📁 Fichier généré :"
    echo "   build/app/outputs/bundle/release/app-release.aab"
    echo ""
    echo "📤 Vous pouvez maintenant uploader ce fichier sur le Play Store"
    echo ""
    # Ouvrir le dossier contenant le bundle
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open build/app/outputs/bundle/release/
    fi
else
    echo ""
    echo "❌ Erreur lors de la génération du bundle"
    exit 1
fi

