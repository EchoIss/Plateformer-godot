# Petit Jeu de Plateforme (Godot 4)

Un mini jeu de plateforme au style **cartoon** : personnage avec yeux, squash & stretch exagérés (étirement au saut, écrasement à l'atterrissage, élastique au retour), inclinaison pendant la course, pièces qui tournent et vibrent puis éclatent quand on les ramasse. Déplace-toi, saute de plateforme en plateforme et ramasse les 5 pièces. Si tu tombes, tu réapparaîtras au départ.

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

## Structure

- `scenes/main.tscn` — le niveau (plateformes, pièces, zone de chute, HUD)
- `scripts/player.gd` — déplacement et saut du personnage
- `scripts/coin.gd` — collecte des pièces
- `scripts/main.gd` — score, victoire et réapparition
