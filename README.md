# Plateformer Godot — Action-Platformer Metroidvania

Jeu de plateforme cartoon fait avec **Godot 4.3** : un grand monde interconnecté de 5 régions
(~20 minutes de jeu), des pouvoirs à débloquer, 6 clés, des cœurs, des checkpoints,
des élites, 3 boss et une vraie fin.

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
| Saut mural | glisser le long d'un mur puis sauter vers le mur |

## Les 5 régions

1. **Prairie de l'Aube** — le départ, premières pièces et checkpoints.
2. **Forêt des Mille Terrasses** — une grimpée de plateformes en étages.
3. **Le Gouffre** — les grottes en dessous, pilier et précipices.
4. **Ruines Oubliées** — la cheminée murale (saut mural obligatoire) et le couloir de ruée.
5. **Salle du Trône** — la grande porte et le Roi Slime.

## Objectifs

- **42 pièces** éparpillées partout (surface, terrasses, grotte, cheminée).
- **6 clés cachées** : sur la terrasse haute, dans le Gouffre, au sommet de la cheminée,
  sur la corniche secrète (ruée obligatoire), etc.
- **4 orbes de pouvoir** : **Chevalier** (attaque à l'épée), **Sorcier** (boules de feu),
  **Ruée** (dash avec traînée de fantômes), **Saut mural**.
- **3 cœurs supplémentaires** augmentent la vie max (4 puis 5 puis 6 PV).
- **12 ennemis + 3 élites** (plus gros, violets, 5 PV).
- **3 boss** : Chef Gobou (Gouffre, 6 PV), Gardienne Kaverna (Ruines, 10 PV),
  et le **Roi Slime** (Trône, 12 PV, 2 phases). La victoire s'obtient **uniquement**
  en battant le boss final derrière la grande porte (6 clés requises).
- Les **checkpoints** (drapeaux) sauvegardent la position en cas de chute.

## Structure

```
project.godot            Config du projet + touches
scenes/                  Scènes (jeu, joueur, ennemis, boss, monde metroidvania...)
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
3. v3 : ennemis, niveaux, sons, double saut ✓
4. v4 : débogage (tests automatisés) ✓
5. v5 : action-platformer (attaques, boss, transformations) ✓
6. v6 : Metroidvania — grande carte, clés, checkpoints, dash ✓
7. **v7 : monde étendu — 5 régions, saut mural, 3 boss, élites, cœurs, ~20 min de jeu** ✓
