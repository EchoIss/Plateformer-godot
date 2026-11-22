# Petit Action-Plateformer (Godot 4)

Un jeu de plateforme d'action au style **cartoon** avec animations exagérées : attaque à l'épée ou à la boule de feu, **transformations**, 3 niveaux, ennemis et un **boss final**.

## Lancer le jeu

1. Installer [Godot 4.x](https://godotengine.org/download) (version standard, pas besoin de .NET).
2. Ouvrir Godot → **Import** → sélectionner le fichier `project.godot` de ce dossier.
3. Cliquer sur **Play** (F5).

En ligne de commande :

```sh
godot --path .
```

## Contrôles

| Action | Touches |
|---|---|
| Se déplacer | `Q`/`D` ou `←`/`→` |
| Sauter / **Double saut** | `Espace`, `W` ou `↑` (×2 en l'air, avec vrille !) |
| **Attaquer** | `X` ou `J` |

## Gameplay

- **Transformations** : attrape un orbe pour te transformer (style Mombo Quest) :
  - **⚔ Chevalier** (orbe cyan, niveau 1) : coup d'épée en arc qui balaie devant toi
  - **🪄 Sorcier** (orbe violet, niveau 2) : lance des boules de feu
  - Le personnage change de couleur avec un squatch cartoon et un son magique
- **Cœurs** : tu as 3 cœurs. Un contact d'ennemi ou du boss, ou une chute, en coûte 1 (+ invincibilité temporaire). À zéro, le niveau recommence.
- **Ennemis** : saute dessus pour les écraser, ou attaque-les !
- **Niveau 3 : BOSS** — le **Roi Slime** (couronne incluse) saute vers toi et claque le sol avec des secousses d'écran. Prends garde à ses slams, saute sur sa tête (2 dégâts !) ou attaque-le (8 PV, barre de vie en bas). Sous la moitié de sa vie, il devient plus rapide et invoque des blobs !

## Structure

- `scenes/game.tscn` + `scripts/game.gd` — gestionnaire (niveaux, cœurs, transformations, boss, HUD, sons)
- `scenes/level_1.tscn`, `level_2.tscn` — niveaux ; `level_3.tscn` — arène du boss
- `scenes/player.tscn` + `scripts/player.gd` — joueur (double saut, attaques, transformations)
- `scenes/enemy.tscn` + `scripts/enemy.gd` — blobs patrouilleurs écrasables
- `scenes/boss.tscn` + `scripts/boss.gd` — le Roi Slime (2 phases, minions)
- `scenes/orb.tscn` + `scripts/orb.gd` — orbes de transformation
- `scenes/fireball.tscn` + `scripts/fireball.gd` — boules de feu du Sorcier
- `sounds/` — effets sonores rétro
- `tests/test_smoke.gd` — test de fumée headless : `godot --headless --path . -s tests/test_smoke.gd`
