extends Node
## Withdrawal meter, addiction and drugs. Lives across levels and "waking up in bed".
##
## - meter rises over time without drugs (faster with more addiction).
## - take_pill(): instant relief, more addiction, and "under the influence" for a while:
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
var addiction := 0.0
var pills_taken := 0
var influence := 0.0                # seconds left under the influence
var state := ""                     # "", "episode" or "hallucination"
var rate_multiplier := 1.0          # set per level by main.gd
var found_items: Array[String] = []
var taken_pickups: Array[String] = []   # ids of pills/items already taken (don't respawn)


func _process(delta: float) -> void:
	var rate := Config.METER_RISE_PER_SEC * rate_multiplier * (1.0 + addiction * Config.ADDICTION_RISE_MULTIPLIER)
	meter = minf(Config.METER_MAX, meter + rate * delta)
	influence = maxf(0.0, influence - delta)
	Settings.set_muffle(influence_strength())


## 0..1: how strongly the drugs are working right now (fades out over the duration).
func influence_strength() -> float:
	if influence <= 0.0:
		return 0.0
	return clampf(influence / Config.INFLUENCE_DURATION * 1.5, 0.0, 1.0) * Config.INFLUENCE_NUMB


func is_influenced() -> bool:
	return influence > 0.0


func take_pill(id := "") -> void:
	meter = maxf(0.0, meter - Config.PILL_METER_REDUCTION)
	addiction += Config.PILL_ADDICTION_GAIN
	influence = Config.INFLUENCE_DURATION
	pills_taken += 1
	if id != "":
		taken_pickups.append(id)
	pill_taken.emit()


## Message for the n-th pill (a level can give its own message instead).
func pill_message() -> String:
	return PILL_MESSAGES[clampi(pills_taken - 1, 0, PILL_MESSAGES.size() - 1)]


func add_item(id: String) -> void:
	if id in found_items:
		return
	found_items.append(id)
	taken_pickups.append(id)
	items_changed.emit()


func post_message(text: String) -> void:
	message_posted.emit(text)
