extends Node
## Withdrawal meter, the "in your system" meter and drugs. Lives across levels and days.
##
## - meter (withdrawal) rises over time - the more is in your system, the faster.
## - in_system fills when you take a pill and slowly drains away.
## - take_pill(): withdrawal to 0, in_system up, and "under the influence" for a while:
##   no episodes or hallucinations, the world goes grey and muffled.
## - state says what is happening right now ("", "episode", "hallucination"), so only
##   one thing happens at a time.

signal message_posted(text: String)
signal items_changed
signal pill_taken
signal episode_started
signal episode_survived      # step 5: big Recovery gain
signal hallucination_survived

const PILL_MESSAGES := [
	"You swallow them before you can think. The shaking stops. You hate how easy that was.",
	"It works. It always works. That's the problem.",
	"The noise in your head goes quiet. So does everything else.",
	"You tell yourself it's the last time. You've said that before.",
]

var meter: float = Config.METER_START
var in_system := 0.0                # 0..Config.SYSTEM_MAX: drugs still in his body
var pills_taken := 0
var influence := 0.0                # seconds left under the influence
var state := ""                     # "", "episode" or "hallucination"
var rate_multiplier := 1.0          # set per level by main.gd
var hold := false                   # true while doing an activity: withdrawal doesn't rise
                                    # (talking and reading pause the whole game, so it stands still then too)
var found_items: Array[String] = []
var taken_pickups: Array[String] = []   # ids of items/letters already taken (never come back)
var taken_pills: Array[String] = []     # ids of pill bottles taken today (they come back the next day)


func _process(delta: float) -> void:
	if not hold:
		meter = minf(Config.METER_MAX, meter + _rate() * delta)
	in_system = maxf(0.0, in_system - Config.SYSTEM_DRAIN_PER_SEC * delta)
	influence = maxf(0.0, influence - delta)
	Settings.set_muffle(influence_strength())


func _rate() -> float:
	return Config.METER_RISE_PER_SEC * rate_multiplier * (1.0 + system_level() * Config.SYSTEM_RISE_MULTIPLIER)


## 0..1: how full the "in your system" meter is.
func system_level() -> float:
	return in_system / Config.SYSTEM_MAX


## 0..1: how strongly the drugs are working right now (fades out over the duration).
func influence_strength() -> float:
	if influence <= 0.0:
		return 0.0
	return clampf(influence / Config.INFLUENCE_DURATION * 1.5, 0.0, 1.0) * Config.INFLUENCE_NUMB


func is_influenced() -> bool:
	return influence > 0.0


func take_pill(id := "") -> void:
	meter = 0.0   # all of it, at once. That's the trap.
	in_system = minf(Config.SYSTEM_MAX, in_system + Config.PILL_SYSTEM_GAIN)
	influence = Config.INFLUENCE_DURATION
	pills_taken += 1
	if id != "":
		taken_pills.append(id)
	pill_taken.emit()


## Message for the n-th pill (a level can give its own message instead).
func pill_message() -> String:
	return PILL_MESSAGES[clampi(pills_taken - 1, 0, PILL_MESSAGES.size() - 1)]


## A personal item was found: it lowers withdrawal (and Recovery listens to items_changed).
func add_item(id: String) -> void:
	if id in found_items:
		return
	found_items.append(id)
	taken_pickups.append(id)
	meter = maxf(0.0, meter - Config.ITEM_WITHDRAWAL_RELIEF)
	items_changed.emit()


## Start over (after an ending).
func reset() -> void:
	meter = Config.METER_START
	in_system = 0.0
	pills_taken = 0
	influence = 0.0
	state = ""
	hold = false
	found_items.clear()
	taken_pickups.clear()
	taken_pills.clear()
	items_changed.emit()


func post_message(text: String) -> void:
	message_posted.emit(text)
