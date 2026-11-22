# Plateformer Godot — Action-Platformer Metroidvania

Petit jeu de plateforme cartoon fait avec **Godot 4.3** : une grande carte interconnectée à explorer,
des pouvoirs à débloquer, des clés à trouver, des checkpoints et un boss final.

## Lancer le jeu

1. Ouvrir Godot 4.3 (ou plus récent).
2. Cliquer sur **Import**, puis sélectionner le fichier `project.godot` de ce dépôt.
3. Cliquer sur **Play** (F5).

## Comment jouer

| Action | Touches |
|---|---|
| Se déplacer | A/D ou ←/→ |
| Sauter / Double saut | Espace, ↑ ou W |
| Attaquer | X ou J |
| Ruée (dash) | Maj, C ou K |

## Objectifs

- **13 pièces** éparpillées dans la carte (surface, hauteurs, grotte secrète).
- **3 clés cachées** : dans le puits gauche, en haut des plateformes, et sur une corniche secrète accessible avec la ruée.
- **Débloquer la ruée** : l'orbe vert dans la grotte donne le dash (avec traînée de fantômes !).
- **Transformations** (comme dans Mombo/Kirby) : orbe cyan → **Chevalier** (attaque à l'épée),
  orbe violet → **Sorcier** (boules de feu), orbe vert → **Ruée**.
- Ouvrir la **grande porte** avec les 3 clés pour affronter le **Roi Slime** (8 PV, 2 phases, sauts et écrasements).
- La victoire s'obtient **uniquement** en battant le boss.

## Structure

```
project.godot            Config du projet + touches
scenes/                  Scènes (jeu, joueur, ennemis, boss, carte metroidvania...)
scripts/                 Logique GDScript
sounds/                  Sons générés (WAV)
tests/test_smoke.gd      Tests automatiques headless
```

## Tests headless

```bash
godot --headless --path . --import
godot --headless --path . -s tests/test_smoke.gd
```

## Progression

1. v1 : mini-plateforme ✓
2. v2 : style cartoon + animations exagérées ✓
3. v3 : ennemis, 3 niveaux, sons, double saut ✓
4. v4 : débogage (tests automatisés) ✓
5. v5 : action-platformer (attaques, boss, transformations) ✓
6. **v6 : Metroidvania — une grande carte interconnectée avec plusieurs objectifs** ✓
