extends Node
## ALL tuning numbers in the game, in one place.
## Change values here - other scripts read them as Config.NAME.

# ---------- Display ----------
const INTERNAL_RESOLUTION := Vector2i(640, 480)   # game renders at this size, scaled up
const WINDOW_SIZE := Vector2i(1280, 960)          # starting window size on desktop
const UI_FONT_SIZE := 16
const UI_FONT_SIZE_SMALL := 12
const FOV := 70.0

# ---------- PS1 look ----------
const FOG_DENSITY := 0.16                    # dense fog (higher = thicker)
const FOG_COLOR := Color(0.05, 0.06, 0.035)
const AMBIENT_COLOR := Color(0.55, 0.6, 0.4)
const AMBIENT_ENERGY := 0.12                 # how dark it is without lamps
const TINT_COLOR := Color(0.85, 1.0, 0.5)    # green-yellow tone
const TINT_STRENGTH := 0.6                   # 0 = no tint, 1 = full
const COLOR_DEPTH := 32.0                    # colour levels per channel (fewer = coarser)
const DITHER_STRENGTH := 1.0
const VIGNETTE := 0.7
const VERTEX_SNAP := Vector2(320.0, 240.0)   # lower = more vertex jitter
const AFFINE_STRENGTH := 0.25                # PS1 texture warping (0-1)
const TEXTURE_SCALE := 0.5                   # texture repeats per metre

# ---------- Lamps ----------
const LAMP_ENERGY := 0.7
const LAMP_RANGE := 6.0
const LAMP_COLOR := Color(0.9, 1.0, 0.7)
const DORM_LAMP_ENERGY := 0.25
const LAMP_FLICKER_CHANCE := 0.06            # per frame, for flickering lamps

# ---------- Player movement ----------
const WALK_SPEED := 2.6
const SPRINT_SPEED := 4.6
const MOUSE_SENSITIVITY := 0.0025
const PLAYER_HEIGHT := 1.6
const GRAVITY := 9.8
const HEAD_BOB := 0.025
const HEAD_BOB_FREQ := 9.0
const SPRINT_BOB_MULTIPLIER := 1.6
const SPRINT_FOV_KICK := 6.0
const INTERACT_DISTANCE := 2.0

# ---------- Stamina ----------
const STAMINA_MAX := 100.0
const STAMINA_DRAIN_PER_SEC := 22.0
const STAMINA_REGEN_PER_SEC := 16.0
const STAMINA_REGEN_DELAY := 1.0             # seconds after sprinting before regen starts
const STAMINA_MIN_TO_SPRINT := 25.0          # after running empty, wait until this much is back
const WITHDRAWAL_STAMINA_PENALTY := 0.6      # share of max stamina lost at full withdrawal
const STAMINA_BAR_HIDE_DELAY := 1.5

# ---------- Flashlight ----------
const FLASHLIGHT_ENERGY := 2.2
const FLASHLIGHT_RANGE := 12.0
const FLASHLIGHT_ANGLE := 26.0

# ---------- First-person body ----------
const PLAYER_MODEL_PATH := "res://assets/characters/player.glb"   # used instead of boxes if it exists
const BODY_BACK_OFFSET := 0.1                # body sits this far behind the camera
const ARM_SWAY := 0.015                      # arm sway while walking
const ARM_LOOK_LAG := 0.0004                 # how much arms trail behind mouse movement
const LEG_SWING_DEGREES := 28.0
const SKIN_COLOR := Color(0.78, 0.6, 0.48)
const JACKET_COLOR := Color(0.32, 0.26, 0.2)
const PANTS_COLOR := Color(0.2, 0.24, 0.34)
const SHOE_COLOR := Color(0.12, 0.11, 0.1)

# ---------- Withdrawal and addiction (temporary, reworked in build step 4) ----------
const METER_MAX := 100.0
const METER_START := 20.0
const METER_RISE_PER_SEC := 0.9              # base rise per second
const ADDICTION_RISE_MULTIPLIER := 0.6       # rise = base * (1 + addiction * this)
const SYMPTOM_START := 50.0                  # above this, faint visual symptoms begin

# ---------- Pills ----------
const PILL_METER_REDUCTION := 45.0
const PILL_ADDICTION_GAIN := 1.0

# ---------- Hallucination ----------
const HALLUCINATION_THRESHOLD := 70.0
const HALLUCINATION_CHANCE_PER_SEC := 0.12   # chance per second at the threshold
const HALLUCINATION_CHANCE_AT_MAX := 0.6     # chance per second at full meter
const HALLUCINATION_COOLDOWN := 12.0
const HALLUCINATION_DURATION := 15.0         # seconds you must survive
const HALLUCINATION_DURATION_PER_ADDICTION := 4.0
const SHAKE_STRENGTH := 0.05
const MONSTER_SPAWN_DELAY := 1.5
const MONSTER_SPAWN_DISTANCE := 7.0
const MONSTER_SPEED := 2.2
const MONSTER_SPEED_PER_ADDICTION := 0.3
const MONSTER_CATCH_DISTANCE := 0.9
const CAUGHT_METER_AFTER := 45.0

# ---------- Sound ----------
const LOUD_SOUND_DB := -6.0                  # hallucination sound (bus "Loud")
const AMBIENT_HUM_DB := -22.0

# ---------- Story / HUD ----------
const ITEMS_TOTAL := 5
const MESSAGE_DURATION := 5.0
const HELP_TEXT_DURATION := 12.0
