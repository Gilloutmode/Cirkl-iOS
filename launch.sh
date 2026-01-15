#!/bin/bash

# Script pour relancer Cirkl dans Xcode avec l'interface orbitale

echo "🚀 Relancement de Cirkl avec l'interface orbitale..."

# 1. Fermer Xcode si ouvert
echo "⏹ Fermeture de Xcode..."
osascript -e 'quit app "Xcode"' 2>/dev/null

# 2. Attendre un peu
sleep 2

# 3. Nettoyer les données dérivées
echo "🧹 Nettoyage des données dérivées..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Cirkl-*

# 4. Rouvrir le projet
echo "📱 Ouverture du projet..."
open /Users/gil/Cirkl/Cirkl.xcodeproj

echo ""
echo "✅ Projet ouvert !"
echo ""
echo "📋 Instructions :"
echo "1. Dans Xcode, sélectionnez 'OrbitalComplete.swift' dans la liste des fichiers"
echo "2. Appuyez sur ⌘B pour compiler"
echo "3. Appuyez sur ⌘R pour lancer sur le simulateur"
echo ""
echo "L'interface orbitale glassmorphique devrait maintenant s'afficher ! 🎉"