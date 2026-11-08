extends Node
## TEMPORARY (reworked in build step 4). Withdrawal meter, addiction and found items. Survives "waking up in bed".

signal message_posted(text: String)
signal items_changed

var meter: float = Config.METER_START
var addiction := 0.0
var pills_taken := 0
var found_items: Array[String] = []
var rate_multiplier := 1.0  # set per level by main.gd


func _process(delta: float) -> void:
	var rate := Config.METER_RISE_PER_SEC * rate_multiplier * (1.0 + addiction * Config.ADDICTION_RISE_MULTIPLIER)
	meter = minf(Config.METER_MAX, meter + rate * delta)


func take_pill() -> void:
	meter = maxf(0.0, meter - Config.PILL_METER_REDUCTION)
	addiction += Config.PILL_ADDICTION_GAIN
	pills_taken += 1


func add_item(id: String) -> void:
	if id in found_items:
		return
	found_items.append(id)
	items_changed.emit()


func post_message(text: String) -> void:
	message_posted.emit(text)
