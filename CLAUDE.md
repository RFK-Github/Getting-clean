# CLAUDE.md

Godot 4 project: first-person psychological horror game about addiction, PS1 style (school project).

**Read [DESIGN.md](DESIGN.md) before making changes.** It holds the full game design and the BUILD ORDER.

## Working rules
- Build the BUILD ORDER **one step at a time** and stop after each step so the user can test and commit. Don't start the next step unless asked.
- All in-game text, menus and UI in **English**.
- Renderer: **Compatibility** (`gl_compatibility`). Must export to macOS and Web.
- **All numbers** (resolution, fog, timers, rates, countdown, stamina, points, ...) live in `scripts/config.gd`. Don't hard-code tuning values in other scripts.
- Tone: serious and human. Drugs are only shown as stylised pills.
- Character models (Mixamo) go in `assets/characters/`; code uses placeholder boxes when a model is missing.

## Layout
- `scripts/config.gd`, `settings.gd`, `withdrawal.gd`, `game.gd`, `recovery.gd`: autoloads (Config, Settings, Withdrawal, Game, Recovery)
- `Recovery`: Recovery meter (only shown on the clipboard), days until the wife visits, `next_day()`, flashbacks seen, letters read. `Game.game_over()` / `good_ending()` are placeholder screens until step 10
- `scripts/main.gd`: builds whichever level `Game.current_level` names (see `LEVELS`); `Game.change_level()` fades and reloads
- `scripts/levels/`: levels built from boxes in code, all extend `level_base.gd` (`build()`, `get_settings()`, `spawn`)
  - `philadelphia.gd`: level 1. `hospital.gd`: level 2 (map of all rooms at the top of the file)
- `scripts/props/`: reusable scripted props (vehicles, fog figure, mirror)
- `scripts/npc.gd`: non-hostile NPCs (doctor/nurse/patient/therapist), waypoints or stand/sit/lie
- `Game.show_text(title, body)`: reading panel (clipboard, schedule board, later letters)
- `scripts/episode.gd` (withdrawal episode, `flashback_point` signal for step 6) and `scripts/hallucination.gd`
  (monster). Only one runs at a time via `Withdrawal.state`; neither while `Withdrawal.is_influenced()`.
  Signals for step 5 live on Withdrawal (`episode_survived`, `pill_taken`, ...) and `hallucination.caught_player`.
- `shaders/psx.gdshader` (vertex jitter, affine), `shaders/post.gdshader` (tint, dither, effects)
- `scripts/textures.gd`, `scripts/audio.gd`: placeholder textures/sounds generated in code

## Check for errors after changes
```
& "C:\Users\Rune\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path C:\horror-spil --import
& "C:\Users\Rune\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path C:\horror-spil --quit-after 300
```
