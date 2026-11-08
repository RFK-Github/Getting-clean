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
- `Recovery`: Recovery meter (only shown on the clipboard), days until the wife visits, `next_day()`, flashbacks seen, letters read. `Game.game_over()` / `good_ending()` play final cutscenes B / A (`scripts/cutscenes/ending_*.gd`) and show an end card
- `scenes/menu.tscn` (`scripts/menu.gd`) is the main scene; `Game.new_game()` / `Game.to_menu()` switch between it and `scenes/main.tscn`
- `scripts/main.gd`: builds whichever level `Game.current_level` names (see `LEVELS`); `Game.change_level()` fades and reloads
- `scripts/levels/`: levels built from boxes in code, all extend `level_base.gd` (`build()`, `get_settings()`, `spawn`)
  - `philadelphia.gd`: level 1. `hospital.gd`: level 2 (map of all rooms at the top of the file)
- `scripts/props/`: reusable scripted props (vehicles, fog figure, mirror)
- `scripts/cutscenes/`: in-engine cutscenes extending `cutscene_base.gd` (timeline via `at()`, `say()`, `fade()`, placeholder `figure()`s); played with `await Game.play_cutscene(script)`, which pauses the game. Flashbacks 1-3 are listed in `main.gd` `FLASHBACKS` and play at the kneeling point of episodes
- `scripts/npc.gd`: non-hostile NPCs (doctor/nurse/patient/therapist), waypoints or stand/sit/lie
- `Game.show_text(title, body)`: reading panel (clipboard, schedule board, letters)
- `scripts/dialogues.gd`: staff conversations + group therapy (choice trees, once per day via `Recovery.can_talk`); NPCs with `dialogue_id` start them; UI is `Game.start_dialogue()`
- `scripts/activities/`: basketball, football, swimming minigames extending `activity_base.gd` (`setup()`, `tick()`, `finish(did_well)`); started from spots in `hospital.gd` `_activity_spots()`, once per day
- Time-passing hints (step 9): `Config.YEAR_HE_THINKS` / `YEAR_NOW`; calendars, dated letters, chart and `HINTS` lines in `hospital.gd`; the mirror head ages with `Recovery.day()` in `player_body.gd`; mirror remarks in `props/mirror.gd`
- `scripts/story_items.gd`: the 5 items + letters (data). `scripts/inventory.gd`: Belongings screen (I / Tab), owned by `Game`
- Spooky encounters: girl apparitions = `props/fog_figure.gd` with `child = true` (spots in `hospital.gd` `GIRL_SPOTS`); phone/TV in `hospital.gd` `_update_encounters()`; the football car in `activities/football.gd`
- Interactive objects: `hospital.gd` `_interactions()` / `_toggle_spot()` (prompt can change live via `Pickup.prompt_source`)
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

## Export (macOS + Web)
Presets are in `export_presets.cfg` (macOS universal, ad-hoc signed; Web without threads so it runs on any static host).
Export templates for Godot 4.7.2 must be installed first (Editor → Manage Export Templates → Download), then:
```
& "C:\Users\Rune\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path C:\horror-spil --export-release "Web" build/web/index.html
& "C:\Users\Rune\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path C:\horror-spil --export-release "macOS" build/macos/GettingClean.zip
```
