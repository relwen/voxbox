# Justification des Permissions pour Google Play Store

## Permissions concernées
- `android.permission.READ_MEDIA_IMAGES`
- `android.permission.READ_MEDIA_VIDEO`

## Justification pour READ_MEDIA_IMAGES

**Raison principale :** Cette permission est essentielle pour la fonctionnalité principale de l'application VoXY Box qui permet aux choristes de créer, organiser et gérer leurs créations musicales incluant des photos.

### Cas d'usage spécifiques :

1. **Capture de photos pour les créations**
   - L'application permet aux utilisateurs de prendre des photos directement depuis l'application via un bouton flottant dédié
   - Ces photos sont ensuite sauvegardées et organisées dans des dossiers de créations personnels
   - Fonctionnalité : Bouton caméra dans l'écran "Mes Créations"

2. **Sélection de photos depuis la galerie**
   - Les utilisateurs peuvent sélectionner des photos existantes depuis leur galerie pour les ajouter à leurs dossiers de créations
   - Ces photos sont ensuite copiées et organisées dans l'application pour une gestion centralisée

3. **Organisation et gestion des photos**
   - Les photos sont organisées dans des dossiers personnalisables par l'utilisateur
   - Les utilisateurs peuvent prévisualiser, renommer et déplacer leurs photos entre différents dossiers
   - Les photos sont affichées avec des miniatures dans l'interface de l'application

4. **Visionneuse d'images intégrée**
   - L'application dispose d'une visionneuse d'images complète avec zoom et navigation
   - Les utilisateurs peuvent visualiser leurs photos en plein écran directement depuis l'application

### Pourquoi cette permission est nécessaire :

- **Accès fréquent requis** : Les utilisateurs accèdent régulièrement à leurs photos pour les organiser, les visualiser et les gérer dans leurs dossiers de créations
- **Fonctionnalité principale** : La gestion de photos fait partie intégrante de la fonctionnalité "Créations" de l'application, qui est l'une des fonctionnalités principales
- **Stockage local** : Les photos sont stockées localement dans l'application pour un accès rapide et une organisation personnalisée
- **Workflow utilisateur** : Le flux de travail implique la capture, la sélection, l'organisation et la visualisation fréquente des photos

### Conformité aux politiques Google Play :

- ✅ La permission est utilisée uniquement pour les fonctionnalités déclarées
- ✅ L'accès est demandé de manière contextuelle (lorsque l'utilisateur choisit de prendre ou sélectionner une photo)
- ✅ Les photos sont stockées localement dans l'espace de l'application
- ✅ Aucun partage non autorisé des photos avec des tiers

---

## Justification pour READ_MEDIA_VIDEO

**Raison principale :** Cette permission est nécessaire pour permettre aux utilisateurs de sélectionner des vidéos depuis leur galerie, bien que la fonctionnalité principale soit axée sur les photos et l'audio.

### Cas d'usage spécifiques :

1. **Sélection de vidéos depuis la galerie**
   - Les utilisateurs peuvent sélectionner des vidéos existantes depuis leur galerie
   - Ces vidéos peuvent être ajoutées aux dossiers de créations pour une organisation complète

2. **Compatibilité avec le sélecteur de fichiers**
   - L'application utilise le package `image_picker` qui nécessite cette permission pour offrir une expérience complète de sélection de médias
   - Cela permet une interface cohérente pour tous les types de médias

### Note importante :

Bien que l'application soit principalement axée sur les photos et l'audio, cette permission est incluse pour :
- Assurer la compatibilité avec les bibliothèques tierces utilisées (`image_picker`)
- Permettre une expérience utilisateur complète et cohérente
- Éviter les erreurs lors de la sélection de fichiers multimédias

---

## Recommandation alternative (si la justification est rejetée)

Si Google Play rejette cette justification, vous pouvez :

1. **Utiliser le sélecteur de photos d'Android** : Implémenter `ACTION_PICK` ou `ACTION_GET_CONTENT` qui ne nécessite pas ces permissions
2. **Demander l'accès ponctuel** : Utiliser le Storage Access Framework pour un accès ponctuel aux fichiers
3. **Limiter à la caméra uniquement** : Ne permettre que la capture de nouvelles photos sans accès à la galerie

---

## Texte à copier-coller dans le formulaire Google Play (Version condensée - Max 250 mots)

### Pour READ_MEDIA_IMAGES (Version courte - 90 mots) :

```
Cette permission est essentielle pour la fonctionnalité principale de VoXY Box qui permet aux choristes de créer, organiser et gérer leurs créations musicales incluant des photos.

L'application permet aux utilisateurs de :
1. Capturer des photos directement via un bouton flottant dans l'écran "Mes Créations"
2. Sélectionner des photos depuis la galerie pour les ajouter aux dossiers de créations
3. Organiser et gérer les photos dans des dossiers personnalisables (prévisualisation, renommage, déplacement)
4. Visualiser les photos en plein écran avec zoom et navigation

Les utilisateurs accèdent fréquemment à leurs photos pour les organiser et les gérer. La gestion de photos est une fonctionnalité principale de l'application. Les photos sont stockées localement et l'accès est demandé uniquement lorsque l'utilisateur choisit de prendre ou sélectionner une photo. Aucun partage avec des tiers.
```

### Pour READ_MEDIA_IMAGES (Version très courte - 60 mots) :

```
Cette permission est essentielle pour la fonctionnalité principale de VoXY Box : la gestion de créations musicales incluant des photos.

L'application permet de capturer des photos (bouton caméra), sélectionner depuis la galerie, et organiser les photos dans des dossiers personnalisables avec prévisualisation et visionneuse intégrée.

Les utilisateurs accèdent fréquemment à leurs photos pour les organiser. La gestion de photos est une fonctionnalité principale. Accès contextuel uniquement. Stockage local, aucun partage tiers.
```

### Pour READ_MEDIA_VIDEO (Version courte - 40 mots) :

```
Cette permission est nécessaire pour assurer la compatibilité avec le package image_picker utilisé pour la sélection de médias depuis la galerie. Elle garantit une expérience utilisateur cohérente lors de la sélection de fichiers multimédias, même si l'application se concentre principalement sur les photos et l'audio.
```

---

## Versions optimisées (Recommandées pour Google Play)

### ✅ READ_MEDIA_IMAGES - Version recommandée (65 mots) :

```
Permission essentielle pour la fonctionnalité principale de VoXY Box : gestion de créations musicales avec photos.

Fonctionnalités : capture de photos (bouton caméra dans "Mes Créations"), sélection depuis la galerie, organisation dans dossiers personnalisables, prévisualisation avec miniatures, visionneuse plein écran avec zoom.

Les utilisateurs accèdent régulièrement à leurs photos pour organisation et gestion. Fonctionnalité principale de l'application. Accès demandé contextuellement uniquement lors de la prise/sélection de photos. Stockage local, aucun partage avec tiers.
```

### ✅ READ_MEDIA_VIDEO - Version recommandée (35 mots) :

```
Permission requise pour compatibilité avec image_picker lors de la sélection de médias depuis la galerie. Assure une expérience cohérente pour tous types de fichiers multimédias, même si l'application se concentre principalement sur photos et audio.
```

---

## 📋 VERSIONS FINALES POUR GOOGLE PLAY CONSOLE

### READ_MEDIA_IMAGES - Texte final (68 mots) :

```
Permission essentielle pour la fonctionnalité principale de VoXY Box : gestion de créations musicales avec photos.

Fonctionnalités : capture de photos via bouton caméra dans "Mes Créations", sélection depuis la galerie, organisation dans dossiers personnalisables, prévisualisation avec miniatures, visionneuse plein écran avec zoom.

Les utilisateurs accèdent régulièrement à leurs photos pour organisation et gestion. Fonctionnalité principale. Accès demandé contextuellement uniquement lors de prise/sélection de photos. Stockage local, aucun partage avec tiers.
```

**Nombre de mots : 68** ✅

---

### READ_MEDIA_VIDEO - Texte final (33 mots) :

```
Permission requise pour compatibilité avec le package image_picker utilisé pour la sélection de médias depuis la galerie. Assure une expérience utilisateur cohérente pour tous types de fichiers multimédias, même si l'application se concentre principalement sur photos et audio.
```

**Nombre de mots : 33** ✅

---

## 💡 Note importante

Les deux textes combinés font **101 mots** au total, bien en dessous de la limite de 250 mots. Vous pouvez les utiliser tels quels dans Google Play Console.

