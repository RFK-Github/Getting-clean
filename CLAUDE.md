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
- `scripts/config.gd`, `settings.gd`, `withdrawal.gd`: autoloads (Config, Settings, Withdrawal)
- `scripts/levels/`: levels built from boxes in code
- `shaders/psx.gdshader` (vertex jitter, affine), `shaders/post.gdshader` (tint, dither, effects)
- `scripts/textures.gd`, `scripts/audio.gd`: placeholder textures/sounds generated in code

## Check for errors after changes
```
& "C:\Users\Rune\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path C:\horror-spil --import
& "C:\Users\Rune\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path C:\horror-spil --quit-after 300
```
