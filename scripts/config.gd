extends Node
## ALL tuning numbers in the game, in one place.
## Change values here - other scripts read them as Config.NAME.

# ---------- Display ----------
const INTERNAL_RESOLUTION := Vector2i(640, 480)   # game renders at this size, scaled up
const WINDOW_SIZE := Vector2i(1280, 960)          # starting window size on desktop
const UI_FONT_SIZE := 16
const UI_FONT_SIZE_SMALL := 12
const FOV := 70.0

# ---------- Title, content note, support ----------
const GAME_TITLE := "Getting Clean"
const CONTENT_NOTE := "This game deals with addiction, withdrawal, grief and the death of a child in a car accident."
const SUPPORT_TEXT := "If you or someone you know is struggling with addiction, help is available.\nIn the US: SAMHSA National Helpline, 1-800-662-4357 (free, confidential, 24/7).\nElsewhere: talk to a doctor or a local support line."

# ---------- Main menu ----------
const MENU_FOG_DENSITY := 0.12
const MENU_CAMERA_DRIFT := 0.25              # m/s the camera creeps down the corridor

# ---------- Game flow ----------
const START_LEVEL := "philadelphia"          # "philadelphia" or "hospital"
const LEVEL_FADE_TIME := 1.0                 # seconds to fade out/in between levels

# ---------- PS1 look (all levels) ----------
const COLOR_DEPTH := 32.0                    # colour levels per channel (fewer = coarser)
const DITHER_STRENGTH := 1.0
const VIGNETTE := 0.7
const VERTEX_SNAP := Vector2(320.0, 240.0)   # lower = more vertex jitter
const AFFINE_STRENGTH := 0.25                # PS1 texture warping (0-1)
const TEXTURE_SCALE := 0.5                   # texture repeats per metre

# ---------- Level: hospital (recovery center) ----------
const HOSPITAL_FOG_DENSITY := 0.03           # exponential fog (higher = thicker)
const HOSPITAL_FOG_COLOR := Color(0.62, 0.66, 0.6)   # pale, overcast
const HOSPITAL_AMBIENT_COLOR := Color(0.85, 0.92, 0.85)
const HOSPITAL_AMBIENT_ENERGY := 0.45
const HOSPITAL_TINT_COLOR := Color(0.9, 1.0, 0.85)   # faint clinical green
const HOSPITAL_TINT_STRENGTH := 0.25         # 0 = no tint, 1 = full
const HOSPITAL_CAMERA_FAR := 90.0
const HOSPITAL_WITHDRAWAL_RATE := 1.0
const OUTDOOR_LIGHT_ENERGY := 1.2            # "sky" lights over the courtyard and lawn
const OUTDOOR_LIGHT_RANGE := 40.0

# ---------- Level: Philadelphia at dawn ----------
const PHILLY_FOG_COLOR := Color(0.5, 0.33, 0.19)     # orange-amber haze
const PHILLY_FOG_BEGIN := 4.0                # depth fog starts (m)
const PHILLY_FOG_END := 95.0                 # depth fog reaches max (m) - "1-2 blocks"
const PHILLY_FOG_CURVE := 0.7                # <1 = thickens quickly near you
const PHILLY_FOG_MAX := 0.94                 # max fog amount (1 = towers fully hidden)
const PHILLY_FOG_SUN_SCATTER := 0.5          # glow in the fog toward the sun
const PHILLY_AMBIENT_COLOR := Color(0.75, 0.55, 0.38)
const PHILLY_AMBIENT_ENERGY := 0.3
const PHILLY_TINT_COLOR := Color(1.0, 0.75, 0.45)
const PHILLY_TINT_STRENGTH := 0.3
const PHILLY_CAMERA_FAR := 300.0
const PHILLY_WITHDRAWAL_RATE := 0.3          # withdrawal rises slower in the opening
const PHILLY_SUN_COLOR := Color(1.0, 0.62, 0.32)
const PHILLY_SUN_ENERGY := 0.7
const PHILLY_SUN_ELEVATION := 7.0            # degrees above the horizon
const PHILLY_SUN_DISC_COLOR := Color(1.0, 0.72, 0.42, 0.5)
const STREETLIGHT_COLOR := Color(1.0, 0.68, 0.32)    # sodium orange
const STREETLIGHT_ENERGY := 1.4
const STREETLIGHT_RANGE := 12.0
const STREETLIGHT_SPACING := 26.0
const HEADLIGHT_ENERGY := 2.0
const HEADLIGHT_RANGE := 18.0
const TRAIN_SPEED := 15.0
const TRAIN_FIRST_DELAY := 10.0              # seconds after start
const TRAIN_INTERVAL := 45.0
const TRAIN_CARS := 4
const TRAIN_SHAKE := 0.012                   # camera shake when a train passes overhead
const TRAIN_SHAKE_DISTANCE := 30.0
const CAR_SPEED := 9.0
const CAR_INTERVAL := 25.0
const BUS_MAX_SPEED := 8.0
const BUS_ACCELERATION := 1.2
const BUS_DEPART_DELAY := 1.5
const SIREN_FIRST_DELAY := 20.0
const SIREN_INTERVAL := 40.0
const FIGURE_VANISH_DISTANCE := 14.0         # the figure in the fog vanishes this close
const FLASHLIGHT_HINT_DELAY := 9.0

# ---------- Sound levels (dB) ----------
const TRAFFIC_DB := -24.0
const SIREN_DB := -6.0                       # 3D sound placed far away
const TRAIN_RUMBLE_DB := 4.0                 # loud bus
const STING_DB := -4.0                       # loud bus

# ---------- Fluorescent lights (hospital) ----------
const LAMP_ENERGY := 0.9
const LAMP_RANGE := 9.0
const LAMP_COLOR := Color(0.92, 1.0, 0.92)
const LAMP_FLICKER_CHANCE := 0.06            # per frame, for flickering lamps

# ---------- NPCs ----------
const NPC_MODEL_DIR := "res://assets/characters/"   # <role>.glb replaces the boxes (doctor, nurse, patient, therapist)
const NPC_WALK_SPEED := 1.1
const NPC_WAIT_TIME := 3.0                   # seconds they pause at each waypoint
const NPC_LOOK_DISTANCE := 4.0              # NPCs turn their heads to watch you within this distance
const NAV_AGENT_RADIUS := 0.25               # navigation mesh clearance (multiple of 0.25; must fit 1.2 m doors)
const NAV_AGENT_HEIGHT := 1.5               # navigation clearance under door lintels (2.2 m)

# ---------- Mirror ----------
const MIRROR_RESOLUTION := Vector2i(160, 200)
const MIRROR_UPDATE_DISTANCE := 7.0          # only render the reflection when this close

# ---------- Daily schedule board (24h clock) ----------
const SCHEDULE := [
	[8, "Breakfast", "Common room"],
	[9, "Doctor's round", "Your room"],
	[10, "Basketball", "Courtyard"],
	[11, "Group therapy", "Therapy room"],
	[13, "Football", "Lawn"],
	[15, "Swimming", "Pool"],
	[18, "Dinner", "Common room"],
	[22, "Lights out", ""],
]

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
const HAIR_COLOR := Color(0.2, 0.15, 0.11)

# ---------- Withdrawal meter and addiction ----------
const METER_MAX := 100.0
const METER_START := 20.0
const METER_RISE_PER_SEC := 0.6              # base rise per second without drugs
const ADDICTION_RISE_MULTIPLIER := 0.6       # rise = base * (1 + addiction * this)
const SYMPTOM_START := 50.0                  # above this, faint visual symptoms begin

# ---------- Drugs (pills) ----------
# A pill takes away ALL current withdrawal (meter to 0) - but raises addiction (the ticker).
const PILL_ADDICTION_GAIN := 1.0             # each pill: withdrawal rises faster afterwards
const INFLUENCE_DURATION := 120.0            # seconds "under the influence": no episodes or hallucinations
const INFLUENCE_NUMB := 0.7                  # how grey/blurred/muffled the world gets (0-1)
const INFLUENCE_MUFFLE_HZ := 900.0           # low-pass cutoff on all sound at full influence

# ---------- Withdrawal episode (headache, grab head, knees, flashback) ----------
const EPISODE_THRESHOLD := 60.0              # an episode starts when the meter reaches this (each one costs a day)
const EPISODE_FIRST_COOLDOWN := 20.0         # seconds after a level starts
const EPISODE_COOLDOWN := 45.0               # seconds between episodes
const EPISODE_BUILD_TIME := 2.5              # headache builds, you can still move
const EPISODE_GRAB_TIME := 2.0               # grabbing and shaking the head, no control
const EPISODE_KNEEL_TIME := 2.5              # on the knees (the flashback plays here in step 6)
const EPISODE_RISE_TIME := 1.2               # getting back up
const EPISODE_METER_DROP := 20.0             # the wave passes: withdrawal drops this much
const EPISODE_SHAKE := 0.03
const KNEEL_DROP := 0.75                     # how far the camera drops on the knees (m)
const HEAD_SHAKE_ANGLE := 0.18               # radians the head swings side to side
const HEAD_SHAKE_SPEED := 14.0
const TINNITUS_DB := -16.0                   # loud bus
const HEARTBEAT_DB := -2.0

# ---------- Hallucination (monster) ----------
const HALLUCINATION_THRESHOLD := 70.0
const HALLUCINATION_CHANCE_PER_SEC := 0.12   # chance per second at the threshold
const HALLUCINATION_CHANCE_AT_MAX := 0.6     # chance per second at full meter
const HALLUCINATION_COOLDOWN := 15.0
const HALLUCINATION_DURATION := 12.0         # seconds you must survive
const HALLUCINATION_DURATION_PER_ADDICTION := 4.0
const SHAKE_STRENGTH := 0.05
const MONSTER_SPAWN_DELAY := 1.5
const MONSTER_SPAWN_DISTANCE := 7.0
const MONSTER_SPEED := 2.75                  # a little faster than walking, slower than sprinting
const MONSTER_SPEED_PER_ADDICTION := 0.3
const MONSTER_CATCH_DISTANCE := 0.9

# ---------- Sound (hospital) ----------
const LOUD_SOUND_DB := -6.0                  # hallucination sound (bus "Loud")
const AMBIENT_HUM_DB := -22.0
const MUSIC_DB := -12.0                      # hospital background music (bus "Music")
const TV_DB := -4.0
const RADIO_DB := -2.0
const WATER_DB := -8.0

# ---------- Countdown (days until the wife visits) ----------
const COUNTDOWN_DAYS := 7                    # caught or forced back to bed = one day passes; 0 = game over
const WAKE_METER := 25.0                     # withdrawal when you wake up the next morning

# ---------- Recovery meter (0-100, decides when the doctors let you leave) ----------
const RECOVERY_START := 10.0
const RECOVERY_MAX := 100.0
const RECOVERY_CAP_BEFORE_TRUTH := 90.0      # can't go higher until every flashback is seen
const FLASHBACKS_TOTAL := 3
const RECOVERY_CLEAN_PER_MINUTE := 1.5       # time in the hospital without drugs
const RECOVERY_EPISODE_SURVIVED := 10.0      # big gain
const RECOVERY_ITEM := 6.0
const RECOVERY_LETTER := 4.0
const RECOVERY_FLASHBACK := 8.0              # step 6
const RECOVERY_TALK := 2.0                   # finishing a conversation with the doctor or a nurse
const RECOVERY_GROUP := 4.0                  # attending group therapy
const RECOVERY_TALK_HONEST := 2.0            # extra for each honest answer
const RECOVERY_TALK_TRUTH := 6.0             # extra for talking about the daughter (after all flashbacks)
const NURSE_RELIEF := 15.0                   # the nurse helps with symptoms: withdrawal drops this much
const RECOVERY_ACTIVITY_SHOW_UP := 3.0       # step 8
const RECOVERY_ACTIVITY_DO_WELL := 4.0       # step 8 (extra)
const RECOVERY_PILL_LOSS := 25.0             # big loss
const EXIT_CLOSER_THRESHOLD := 60.0          # doctor: "Not yet. You're getting closer."
const FORCE_EXIT_WINDOW := 5.0               # seconds to press E again and push past the doctor

# ---------- Items and letters ----------
const ITEM_WITHDRAWAL_RELIEF := 25.0         # finding an item lowers withdrawal
const LETTER_WITHDRAWAL_RELIEF := 10.0
const ITEM_FLICKER := 0.6                    # under the influence: how often real items vanish (0-1)
const FAKE_COPIES_PER_ITEM := 1              # under the influence: decoys that turn to nothing
const ITEM_SPARKLE_COLOR := Color(1.0, 0.95, 0.75, 0.55)   # the glint above items and letters
const ITEM_SPARKLE_SPEED := 2.5

# ---------- Activities (once per in-game day each) ----------
const ACTIVITY_RELIEF := 10.0                # withdrawal drops this much just for showing up
const ACTIVITY_RELIEF_GOOD := 8.0            # ...and this much more for doing well
# Basketball: free throws
const BASKETBALL_SHOTS := 5
const BASKETBALL_GOOD := 3                   # makes needed to "do well"
const SHOT_CHARGE_TIME := 1.1                # seconds for the power bar to fill (it bounces back)
const SHOT_SWEET_MIN := 0.62                 # power window that goes in
const SHOT_SWEET_MAX := 0.8
const AIM_TOLERANCE := 0.18                  # how far off-centre the aim can be and still go in
const AIM_DRIFT_BASE := 0.15                 # aim wobble with no withdrawal
const AIM_DRIFT_WITHDRAWAL := 0.6            # extra wobble at full withdrawal
const AIM_MOUSE := 0.004                     # how much the mouse steadies the aim
# Football: penalties
const PENALTIES := 5
const PENALTY_GOOD := 3
const PENALTY_CHARGE_TIME := 1.0
const PENALTY_POWER_MIN := 0.3               # softer than this: the keeper always saves
const PENALTY_POWER_MAX := 0.9               # harder than this: over the bar
const KEEPER_REACH := 1.4                    # metres either side of where the keeper dives
const PENALTY_AIM_MOUSE := 0.006
# Swimming: alternate left/right in rhythm
const SWIM_DISTANCE := 38.4                  # two lengths of the pool
const SWIM_TIME_LIMIT := 70.0
const SWIM_BEAT := 0.65                      # seconds between strokes
const SWIM_WINDOW := 0.22                    # how close to the beat a stroke must be
const SWIM_STROKE_PUSH := 0.9                # speed gained per good stroke (m/s)
const SWIM_DRAG := 1.2
const SWIM_SINK_PER_MISS := 0.3
const SWIM_GOOD_ACCURACY := 0.7              # share of good strokes to "do well"

# ---------- Cutscenes / flashbacks ----------
# (Each scene's own timeline - when lines appear, camera moves - lives in its script in scripts/cutscenes/.)
const CUTSCENE_FADE_TIME := 1.0              # fade in/out of a cutscene
const CUTSCENE_SKIP_AFTER := 1.5             # seconds before E can skip
const FLASHBACK_DRIVE_SPEED := 16.0          # flashback 1: how fast the world passes the car (m/s)
const FLASHBACK_ONCOMING_SPEED := 30.0       # flashback 1: the other car
const CUTSCENE_ENGINE_DB := -16.0
const CUTSCENE_SCREAM_DB := -2.0             # loud bus
const CUTSCENE_RAIN_DB := -14.0
const CUTSCENE_TRAIN_DB := -2.0              # loud bus

# ---------- Spooky encounters ----------
# A small girl (the daughter) appears at the end of a corridor and is gone when you come close.
const GIRL_MIN_METER := 35.0                 # withdrawal needed before she appears
const GIRL_FIRST_DELAY := 25.0               # seconds after waking
const GIRL_INTERVAL := 70.0                  # seconds between appearances
const GIRL_VANISH_DISTANCE := 7.0
const GIRL_LIFETIME := 45.0                  # she's gone after this long if you never come close
const GIRL_DRESS_COLOR := Color(0.9, 0.75, 0.3)   # the same yellow as in the car
# The reception phone rings. Nobody else hears it.
const PHONE_MIN_METER := 45.0
const PHONE_FIRST_DELAY := 60.0
const PHONE_INTERVAL := 150.0
const PHONE_RING_TIME := 15.0
const PHONE_DB := -6.0
# The TV in the common room turns itself on (once per day, when you walk in).
const TV_SELF_MIN_METER := 45.0
# Football: on this kick a car comes out of the back of the goal at you, then vanishes.
const FOOTBALL_CAR_KICK := 3
const FOOTBALL_CAR_SPEED := 18.0

# ---------- Time-passing hints ----------
const YEAR_HE_THINKS := 2019                 # the year he believes it is (he thinks it's been weeks)
const YEAR_NOW := 2024                       # the real year (calendars, the last letter)
const HINT_LINES_FROM_DAY := 2               # staff/patients start recognising him from this day
const AGE_FULL_AFTER_WAKES := 4              # mirror: fully grey and bearded after waking up this many times
const HAIR_COLOR_OLD := Color(0.55, 0.53, 0.5)

# ---------- Story / HUD ----------
const ITEMS_TOTAL := 5
const LETTERS_TOTAL := 4
const MESSAGE_DURATION := 5.0
const HELP_TEXT_DURATION := 12.0
