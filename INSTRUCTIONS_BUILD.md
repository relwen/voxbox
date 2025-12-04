# Instructions pour générer l'App Bundle

## ✅ Configuration terminée

La clé de signature a été créée avec succès :
- **Fichier de clé** : `android/voxbox-keystore.jks`
- **Alias** : `voxbox-key`
- **Mot de passe** : `voxbox2024` (gardez-le en sécurité !)

## 📦 Générer l'App Bundle

Exécutez cette commande depuis la racine du projet (`voxbox/`) :

```bash
flutter build appbundle --release
```

Ou utilisez le script fourni :

```bash
./build_app_bundle.sh
```

## 📁 Emplacement du fichier généré

Une fois la génération terminée, le fichier `.aab` sera disponible ici :

```
build/app/outputs/bundle/release/app-release.aab
```

## 🔐 Informations importantes

⚠️ **GARDEZ VOTRE CLÉ EN SÉCURITÉ !**
- Le fichier `voxbox-keystore.jks` et `key.properties` sont dans `.gitignore`
- Si vous perdez cette clé, vous ne pourrez plus mettre à jour votre app sur le Play Store
- Faites une sauvegarde sécurisée de ces fichiers

## 📤 Uploader sur le Play Store

1. Connectez-vous à [Google Play Console](https://play.google.com/console)
2. Créez une nouvelle application ou sélectionnez une existante
3. Allez dans "Production" > "Créer une version"
4. Téléchargez le fichier `app-release.aab`
5. Remplissez les informations requises (captures d'écran, description, etc.)
6. Soumettez pour révision

## 🔄 Pour les prochaines versions

Avant chaque nouvelle version, mettez à jour le numéro de version dans `pubspec.yaml` :

```yaml
version: 1.0.1+2  # Incrémentez le numéro après le + (versionCode)
```

Puis régénérez le bundle avec la même commande.

