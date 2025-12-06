# Exemples Visuels des Notifications Toast

## 🎨 Aperçu des Différents Types

### 1. Toast de Succès (Success)

```
╔════════════════════════════════════════════════════════════╗
║  ✅  Succès                                    [━━━━━    ] ║
║                                                             ║
║  Vocalise créée avec succès                                ║
╚════════════════════════════════════════════════════════════╝
```

**Couleur:** Vert (#4CAF50)
**Icône:** Cercle avec check ✅
**Usage:** Opérations réussies, confirmations
**Durée:** 3 secondes

---

### 2. Toast d'Erreur (Error)

```
╔════════════════════════════════════════════════════════════╗
║  ❌  Erreur                                    [━━━━━    ] ║
║                                                             ║
║  Impossible de se connecter au serveur                     ║
╚════════════════════════════════════════════════════════════╝
```

**Couleur:** Rouge (#F44336)
**Icône:** Cercle avec X ❌
**Usage:** Erreurs, échecs d'opérations
**Durée:** 4 secondes

---

### 3. Toast d'Avertissement (Warning)

```
╔════════════════════════════════════════════════════════════╗
║  ⚠️  Attention                                 [━━━━━    ] ║
║                                                             ║
║  Veuillez remplir tous les champs obligatoires            ║
╚════════════════════════════════════════════════════════════╝
```

**Couleur:** Orange (#FF9800)
**Icône:** Triangle avec point d'exclamation ⚠️
**Usage:** Avertissements, validations
**Durée:** 3 secondes

---

### 4. Toast d'Information (Info)

```
╔════════════════════════════════════════════════════════════╗
║  ℹ️  Information                               [━━━━━    ] ║
║                                                             ║
║  Nouvelle mise à jour disponible                           ║
╚════════════════════════════════════════════════════════════╝
```

**Couleur:** Bleu (#2196F3)
**Icône:** Cercle avec i ℹ️
**Usage:** Informations générales, conseils
**Durée:** 3 secondes

---

### 5. Toast de Chargement (Loading)

```
╔════════════════════════════════════════════════════════════╗
║  ⏳  Téléchargement                                         ║
║                                                             ║
║  Téléchargement du fichier audio...                        ║
╚════════════════════════════════════════════════════════════╝
```

**Couleur:** Bleu (#2196F3)
**Icône:** Spinner animé ⏳
**Usage:** Opérations en cours
**Durée:** Infinie (fermeture manuelle)

---

### 6. Toast Personnalisé (Custom)

```
╔════════════════════════════════════════════════════════════╗
║  🎵  Bibliothèque                              [━━━━━    ] ║
║                                                             ║
║  Nouvelle vocalise disponible                              ║
╚════════════════════════════════════════════════════════════╝
```

**Couleur:** Personnalisable
**Icône:** Personnalisable 🎵
**Usage:** Cas spécifiques
**Durée:** 3 secondes

---

## 📍 Positions Disponibles

### En Haut à Droite (Par défaut)

```
┌─────────────────────────────────────────────────────────────┐
│                                    ╔══════════════════════╗ │
│  📱 VoxyBox                         ║ ✅ Message         ║ │
│                                    ╚══════════════════════╝ │
│                                                             │
│                                                             │
│  Contenu de l'application                                  │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### En Haut au Centre

```
┌─────────────────────────────────────────────────────────────┐
│               ╔══════════════════════╗                      │
│  📱 VoxyBox   ║ ✅ Message         ║                      │
│               ╚══════════════════════╝                      │
│                                                             │
│  Contenu de l'application                                  │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### En Haut à Gauche

```
┌─────────────────────────────────────────────────────────────┐
│ ╔══════════════════════╗                                    │
│ ║ ✅ Message         ║     📱 VoxyBox                     │
│ ╚══════════════════════╝                                    │
│                                                             │
│  Contenu de l'application                                  │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### En Bas à Droite

```
┌─────────────────────────────────────────────────────────────┐
│  📱 VoxyBox                                                 │
│                                                             │
│  Contenu de l'application                                  │
│                                                             │
│                                    ╔══════════════════════╗ │
│                                    ║ ✅ Message         ║ │
│                                    ╚══════════════════════╝ │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎭 Animation

### Entrée (Slide + Fade)

```
Étape 1 (0ms):
┌────────────────┐
│                │  ← Toast invisible
│                │     au-dessus de l'écran
└────────────────┘

Étape 2 (100ms):
┌────────────────┐
│  ╔═══════════╗ │  ← Toast apparaît
│  ║ Message   ║ │     en glissant vers le bas
│  ╚═══════════╝ │     avec fade-in
└────────────────┘

Étape 3 (400ms):
┌────────────────┐
│  ╔═══════════╗ │  ← Toast complètement
│  ║ Message   ║ │     visible et en place
│  ╚═══════════╝ │
└────────────────┘
```

### Sortie (Slide + Fade)

```
Étape 1 (après durée):
┌────────────────┐
│  ╔═══════════╗ │  ← Toast visible
│  ║ Message   ║ │
│  ╚═══════════╝ │
└────────────────┘

Étape 2 (+ 100ms):
┌────────────────┐
│  ╔═══════════╗ │  ← Toast glisse
│  ║ Message   ║ │     vers le haut
│                │     avec fade-out
└────────────────┘

Étape 3 (+ 400ms):
┌────────────────┐
│                │  ← Toast disparu
│                │
└────────────────┘
```

---

## 📊 Barre de Progression

La barre de progression indique visuellement le temps restant :

### Début (100%)

```
╔════════════════════════════════════════════════════════════╗
║  ✅  Succès                                    [█████████] ║
║  Message...                                                ║
╚════════════════════════════════════════════════════════════╝
```

### Milieu (50%)

```
╔════════════════════════════════════════════════════════════╗
║  ✅  Succès                                    [████▁▁▁▁▁] ║
║  Message...                                                ║
╚════════════════════════════════════════════════════════════╝
```

### Fin (10%)

```
╔════════════════════════════════════════════════════════════╗
║  ✅  Succès                                    [█▁▁▁▁▁▁▁▁] ║
║  Message...                                                ║
╚════════════════════════════════════════════════════════════╝
```

---

## 🎨 Design Détaillé

### Anatomie d'un Toast

```
╔════════════════════════════════════════════════════════════╗
║                                                             ║
║  [Icon] [Title]                         [Progress Bar] [×] ║
║                                                             ║
║         Description / Message                               ║
║                                                             ║
╚════════════════════════════════════════════════════════════╝
 │      │       │                              │          │
 │      │       │                              │          └─ Bouton fermer
 │      │       │                              └──────────── Barre de progression
 │      │       └─────────────────────────────────────────── Titre (optionnel)
 │      └─────────────────────────────────────────────────── Icône colorée
 └────────────────────────────────────────────────────────── Ombre portée
```

### Dimensions

```
┌─────────────── 400px max ────────────────┐
│                                          │  ↑
│  ╔════════════════════════════════════╗  │  │
│  ║                                    ║  │  │ Auto
│  ║  Toast Content                     ║  │  │ (min 60px)
│  ║                                    ║  │  │
│  ╚════════════════════════════════════╝  │  ↓
│                                          │
└──────────────────────────────────────────┘

Marges:
- Extérieur: 12px
- Intérieur (padding): 16px vertical, 16px horizontal
- Border radius: 12px
```

---

## 🎯 Cas d'Usage Visuels

### Scénario 1 : Connexion Réussie

```
1. Utilisateur saisit son numéro
┌────────────────────────────────┐
│  📱 Connexion                  │
│                                │
│  Numéro: +226 12 34 56 78      │
│  [Se connecter]                │
└────────────────────────────────┘

2. Toast de chargement apparaît
┌────────────────────────────────┐
│  ╔═══════════════════════════╗ │
│  ║ ⏳ Envoi du code OTP...   ║ │
│  ╚═══════════════════════════╝ │
│                                │
│  📱 Connexion                  │
└────────────────────────────────┘

3. Toast de succès remplace le chargement
┌────────────────────────────────┐
│  ╔═══════════════════════════╗ │
│  ║ ✅ Code envoyé au +226... ║ │
│  ╚═══════════════════════════╝ │
│                                │
│  📱 Vérification OTP           │
└────────────────────────────────┘
```

### Scénario 2 : Erreur de Formulaire

```
1. Formulaire incomplet
┌────────────────────────────────┐
│  📝 Nouvelle Vocalise          │
│                                │
│  Titre: [________________]     │
│  Pupitre: [___________]        │
│  Fichier: (vide)               │
│  [Créer]                       │
└────────────────────────────────┘

2. Toast d'avertissement
┌────────────────────────────────┐
│  ╔═══════════════════════════╗ │
│  ║ ⚠️ Veuillez remplir      ║ │
│  ║    tous les champs       ║ │
│  ╚═══════════════════════════╝ │
│                                │
│  📝 Nouvelle Vocalise          │
└────────────────────────────────┘
```

### Scénario 3 : Téléchargement

```
1. Début du téléchargement
┌────────────────────────────────┐
│  ╔═══════════════════════════╗ │
│  ║ ⏳ Téléchargement...      ║ │
│  ╚═══════════════════════════╝ │
│                                │
│  🎵 Vocalise Do Majeur         │
│  📥 [Télécharger]              │
└────────────────────────────────┘

2. Téléchargement terminé
┌────────────────────────────────┐
│  ╔═══════════════════════════╗ │
│  ║ ✅ Fichier téléchargé    ║ │
│  ╚═══════════════════════════╝ │
│                                │
│  🎵 Vocalise Do Majeur         │
│  ✓ Téléchargé                  │
└────────────────────────────────┘
```

---

## 🌈 Thème et Couleurs

### Palette de Couleurs

```
Succès (Success):
┌─────┐
│ ✅  │  #4CAF50 (Vert)
└─────┘

Erreur (Error):
┌─────┐
│ ❌  │  #F44336 (Rouge)
└─────┘

Avertissement (Warning):
┌─────┐
│ ⚠️  │  #FF9800 (Orange)
└─────┘

Information (Info):
┌─────┐
│ ℹ️  │  #2196F3 (Bleu)
└─────┘

Personnalisé:
┌─────┐
│ 🎨  │  Votre couleur
└─────┘
```

### Contraste

```
Toast Clair (recommandé):
╔════════════════════════════╗
║ Background: #FFFFFF (Blanc)║
║ Text: #000000 (Noir)       ║
║ Border: Couleur du type    ║
╚════════════════════════════╝

Toast Sombre (alternative):
╔════════════════════════════╗
║ Background: #424242 (Gris) ║
║ Text: #FFFFFF (Blanc)      ║
║ Border: Couleur du type    ║
╚════════════════════════════╝
```

---

## 📱 Responsive

### Mobile (Portrait)

```
┌──────────────┐
│ ╔══════════╗ │
│ ║ Message  ║ │
│ ╚══════════╝ │
│              │
│   Contenu    │
│              │
└──────────────┘
```

### Tablette (Paysage)

```
┌─────────────────────────────┐
│                 ╔═════════╗ │
│   Contenu       ║ Message ║ │
│                 ╚═════════╝ │
└─────────────────────────────┘
```

### Desktop

```
┌──────────────────────────────────────────┐
│                          ╔════════════╗  │
│   Contenu large          ║ Message    ║  │
│                          ╚════════════╝  │
└──────────────────────────────────────────┘
```

---

## ✨ Effets Spéciaux

### Ombre Portée (Box Shadow)

```
Sans ombre:          Avec ombre:
┌───────────┐       ┌───────────┐
│ Message   │       │ Message   │
└───────────┘       └───────────┘
                      ▓▓▓▓▓▓▓▓▓▓
                      ▓ (ombre) ▓
```

### Coins Arrondis

```
Carrés (0px):       Arrondis (12px):
┌───────────┐       ╭───────────╮
│ Message   │       │ Message   │
└───────────┘       ╰───────────╯
```

---

## 🎪 Exemples Multiples

### Plusieurs Toasts Empilés

```
┌──────────────────────────────┐
│  ╔════════════════════════╗  │
│  ║ ✅ Fichier 1 téléchargé║  │
│  ╚════════════════════════╝  │
│  ╔════════════════════════╗  │
│  ║ ✅ Fichier 2 téléchargé║  │
│  ╚════════════════════════╝  │
│  ╔════════════════════════╗  │
│  ║ ⏳ Fichier 3 en cours...║  │
│  ╚════════════════════════╝  │
│                              │
│   Contenu                    │
└──────────────────────────────┘
```

Espacement entre les toasts : 8px

---

## 📐 Spécifications Techniques

```
Propriété              Valeur
─────────────────────────────────────
Max Width             400px
Min Height            60px
Padding               16px (vertical) × 16px (horizontal)
Margin                12px
Border Radius         12px
Animation Duration    400ms
Auto Close Duration   3000ms (success, warning, info)
                      4000ms (error)
                      ∞ (loading)
Shadow Blur           16px
Shadow Offset         0px 8px
Shadow Color          rgba(0,0,0,0.1)
Font Size             14px (description)
                      16px (title)
Icon Size             28px
Progress Bar Height   4px
```

---

## 🎯 Bonnes Pratiques Visuelles

### ✅ À FAIRE

```
╔════════════════════════════════╗
║ ✅ Vocalise créée             ║  ← Court et clair
╚════════════════════════════════╝

╔════════════════════════════════╗
║ ❌ Erreur                      ║  ← Titre descriptif
║                                ║
║ Connexion impossible           ║  ← Détails en dessous
╚════════════════════════════════╝
```

### ❌ À ÉVITER

```
╔════════════════════════════════════════════════════╗
║ ✅ Votre vocalise a été créée avec succès et...   ║  ← Trop long
║    enregistrée dans la base de données...         ║
╚════════════════════════════════════════════════════╝

╔════════════════════════════════╗
║ ⚠️ Erreur 404 Not Found       ║  ← Code technique
║    at line 234...              ║     pour utilisateur
╚════════════════════════════════╝
```

---

Ce guide visuel vous aide à comprendre comment les toasts apparaissent et fonctionnent dans VoxyBox ! 🎨
