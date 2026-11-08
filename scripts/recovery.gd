extends Node
## Recovery meter (0-100) and the countdown until the wife visits.
##
## Recovery decides when the doctors let you leave. It is never shown as a bar on screen,
## only on the clipboard in your room. Gains: clean time, surviving episodes, items, letters
## (later: flashbacks, staff talks, activities). Loss: taking drugs.
## It can't pass RECOVERY_CAP_BEFORE_TRUTH until every flashback has been seen.
##
## Days: each time you are caught by the monster or forced back to bed, one day passes.
## When the countdown reaches 0 she visits and you weren't ready: game over.

signal day_started(day: int)
signal recovery_changed

var recovery: float = Config.RECOVERY_START
var days_left: int = Config.COUNTDOWN_DAYS
var flashbacks_seen: Array[String] = []
var letters_read: Array[String] = []
var notes: Array[String] = []        # the doctor's notes on the clipboard (newest last)
var done_on_day := {}                # talk/activity id -> the day it was last done (once per day)


func _ready() -> void:
	Withdrawal.pill_taken.connect(_on_pill)
	Withdrawal.episode_survived.connect(func(): add(Config.RECOVERY_EPISODE_SURVIVED, "Withdrawal episode, managed without medication."))
	Withdrawal.items_changed.connect(func(): add(Config.RECOVERY_ITEM, ""))


func _process(delta: float) -> void:
	if Game.current_level == "hospital" and not get_tree().paused and not Withdrawal.is_influenced():
		add(Config.RECOVERY_CLEAN_PER_MINUTE * delta / 60.0, "")


## Today's number, 1 = the first day.
func day() -> int:
	return Config.COUNTDOWN_DAYS - days_left + 1


func cap() -> float:
	if flashbacks_seen.size() < Config.FLASHBACKS_TOTAL:
		return Config.RECOVERY_CAP_BEFORE_TRUTH
	return Config.RECOVERY_MAX


func add(amount: float, note := "") -> void:
	recovery = clampf(recovery + amount, 0.0, cap())
	if note != "":
		add_note(note)
	recovery_changed.emit()


## Staff talks, group therapy and activities can each happen once per in-game day.
func can_talk(id: String) -> bool:
	return done_on_day.get(id, -1) != day()


func mark_talked(id: String) -> void:
	done_on_day[id] = day()


func add_note(text: String) -> void:
	notes.append("Day %d: %s" % [day(), text])


func read_letter(id: String) -> void:
	if id in letters_read:
		return
	letters_read.append(id)
	Withdrawal.taken_pickups.append(id)
	Withdrawal.meter = maxf(0.0, Withdrawal.meter - Config.LETTER_WITHDRAWAL_RELIEF)
	add(Config.RECOVERY_LETTER, "")


func see_flashback(id: String) -> void:
	if id in flashbacks_seen:
		return
	flashbacks_seen.append(id)
	add(Config.RECOVERY_FLASHBACK, "Talked about the past, for the first time." if flashbacks_seen.size() == 1 else "")


func _on_pill() -> void:
	add(-Config.RECOVERY_PILL_LOSS, "Positive drug test.")


## One day passes and you wake up in your bed (or it's game over).
## reason: "caught" (the monster) or "forced" (tried to push past the doctor).
func next_day(reason: String) -> void:
	days_left -= 1
	if days_left <= 0:
		Game.game_over()
		return
	if reason == "forced":
		add_note("Tried to leave against medical advice.")
	Withdrawal.meter = Config.WAKE_METER
	var first := "Two orderlies walk you back to your room. The night passes." if reason == "forced" \
		else "You wake up in your bed. The sheets are soaked with sweat."
	Game.wake_message = "%s %s" % [first, days_text()]
	Game.change_level("hospital")
	day_started.emit(day())


func days_text() -> String:
	if days_left == 1:
		return "She visits tomorrow."
	return "%d days until she visits." % days_left


## Short assessment for the clipboard - never a number.
func assessment() -> String:
	if recovery >= Config.RECOVERY_MAX:
		return "Ready for discharge."
	if recovery >= 75.0:
		return "Nearly there."
	if recovery >= Config.EXIT_CLOSER_THRESHOLD:
		return "Improving."
	if recovery >= 30.0:
		return "Some progress."
	return "Not ready."


## A hand-drawn scale on the chart: ten ticks.
func scale_text() -> String:
	var filled := int(floor(recovery / Config.RECOVERY_MAX * 10.0))
	return "[" + "/".repeat(filled) + " ".repeat(10 - filled) + "]"


func reset() -> void:
	recovery = Config.RECOVERY_START
	days_left = Config.COUNTDOWN_DAYS
	flashbacks_seen.clear()
	letters_read.clear()
	notes.clear()
	done_on_day.clear()
