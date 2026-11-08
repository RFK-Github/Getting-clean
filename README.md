# Getting Clean

A first-person psychological horror game about addiction, in a PS1 style. School project, made with Godot 4.7 (Compatibility renderer).

> **Content note:** this game deals with addiction, withdrawal, grief and the death of a child in a car accident.
> If you or someone you know is struggling with addiction, help is available. In the US: SAMHSA National Helpline, 1-800-662-4357 (free, confidential, 24/7).

You arrive at a recovery center in Philadelphia, trying to get clean for your wife before she visits. Withdrawal brings episodes, flashbacks and hallucinations. Find the things you have lost, talk to the people around you, and face what you have been running from.

## Controls
| Key | Action |
|---|---|
| WASD / arrows | Move |
| Mouse | Look |
| Shift | Sprint |
| F | Flashlight |
| E | Interact / continue |
| 1-4 | Dialogue choices |
| Esc | Pause menu (screen shake, loud-sound volume) |

## Run it
Open the folder in Godot 4.7 and press Play (main scene: `scenes/menu.tscn`).

## Export
See `CLAUDE.md` → *Export*. Presets for **macOS** and **Web** are in `export_presets.cfg`; install the Godot 4.7.2 export templates first.

## Project layout
- `DESIGN.md` – the full game design and build order
- `scripts/config.gd` – every tuning number in one place
- `scripts/levels/` – Philadelphia and the hospital, built from boxes in code
- `scripts/cutscenes/` – flashbacks and the two endings
- `scripts/activities/` – basketball, football, swimming
- `assets/characters/` – drop Mixamo `.glb` models here to replace the placeholder boxes
