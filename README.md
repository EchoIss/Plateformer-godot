# Petit Jeu de Plateforme (Godot 4)

Un mini jeu de plateforme au style **cartoon** avec des animations exagérées, des ennemis écrasables, 2 niveaux, des sons rétro et un double saut.

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
| Sauter | `Espace`, `W` ou `↑` |
| **Double saut** | Appuyer à nouveau sur sauter en l'air (avec vrille !) |

## Gameplay

- **Pièces** : elles tournent, flottent et éclatent quand on les ramasse. Ramasse-les toutes pour passer au niveau suivant.
- **Ennemis** : des blobs violets qui patrouillent. **Saute dessus pour les écraser** (squash cartoon garanti), mais évite de les toucher de côté ou tu réapparaîtras au départ !
- **Chute** : tomber hors de l'écran fait réapparaître au départ du niveau.
- **2 niveaux** : le niveau 2 a un ciel de coucher de soleil, 6 pièces et 3 ennemis.

## Structure

- `scenes/game.tscn` + `scripts/game.gd` — gestionnaire de jeu (niveaux, score, sons, HUD)
- `scenes/level_1.tscn`, `scenes/level_2.tscn` — les niveaux
- `scenes/player.tscn` + `scripts/player.gd` — joueur (déplacement, double saut, squash & stretch)
- `scenes/enemy.tscn` + `scripts/enemy.gd` — ennemis patrouilleurs écrasables
- `scenes/coin.tscn` + `scripts/coin.gd` — pièces collectables
- `sounds/` — les effets sonores rétro
