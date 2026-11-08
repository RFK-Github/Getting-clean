# Character models

Placeholder boxes are used until real models are added here.

## Player (first-person body)
- File: `player.glb` (path set in `scripts/config.gd` → `PLAYER_MODEL_PATH`).
- Export from Mixamo as FBX, convert/import into Godot and save as `.glb`, scale 1 unit = 1 metre, feet at y=0.
- The model is rotated 180° automatically (Mixamo faces +Z, Godot forward is -Z).
- Animations in its `AnimationPlayer` named: `idle`, `walk`, `run`.
  Later steps will also use: `grab_head`, `kneel`.
- Tip: hide or shrink the head mesh/bone so it doesn't block the camera.

## NPCs (later steps)
Doctors, nurses, patients, the wife: same idea, one `.glb` each.
