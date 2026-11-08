# Real sound clips

Every sound in the game is generated in code as a placeholder. Drop a real recording in this
folder with one of these names (`.ogg`, `.wav` or `.mp3`) and the game uses it instead -
no code changes needed. Godot imports it when you open the project.

| File name | Used for |
|---|---|
| `child_laugh` | The daughter laughing in flashback 1, and the girl apparitions in the hospital and Philadelphia |
| `child_scream` | The daughter screaming just before the crash |
| `woman_scream` | The wife screaming "LOOK OUT!" in flashback 1 |

Keep clips short (1-3 seconds), mono is fine, and make sure they don't loop
(in Godot: select the file, Import tab, Loop off, Reimport).

## Where to get free clips
Use clips you are allowed to use in a school project, and note the source and licence:
- **freesound.org** - filter the search by licence "Creative Commons 0" (no attribution needed).
  Search e.g. "child laugh", "girl giggle", "woman scream", "child scream".
- **pixabay.com/sound-effects** - free under the Pixabay licence.
- Or record your own.

Write down where each file came from (for the credits), e.g. in this file:

| File | Source | Licence |
|---|---|---|
| `child_laugh.wav` | "Four Years Old child laughing" by morgantj, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Four_Years_Old_child_laughing.ogg (cut: 0.25-1.75 s + 2.95-4.05 s, mono) | **CC BY 3.0** - credit required: "Four Years Old child laughing" by morgantj, CC BY 3.0 |
| `woman_scream.wav` | "Female Scream 1" by Nocturnal_Vanguard (AuraVoice), OpenGameArt: https://opengameart.org/node/147410 (cut: 0.5-1.4 s, mono) | CC0 |
| `child_scream.wav` | "Female high-pitched scream SFX" (Screams of horror, 4 pitches) by WuxiaScrub, OpenGameArt: https://opengameart.org/node/131040 (the highest of the four, mono) | CC0 |

The untouched originals are in `_src/`.
