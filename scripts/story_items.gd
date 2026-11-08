extends RefCounted
## The five personal items and the wife's letters: where they are, what they say.
## Used by the hospital (to place them) and the inventory screen (to show them).

## "pos": where the real one is. "fakes": where copies appear under the influence.
## "name"/"short": how it's listed in the inventory. "message": shown when you pick it up.
const ITEMS := [
	{"id": "drawing", "name": "Drawing", "prompt": "A child's drawing", "pos": Vector3(-6.28, 0.485, -18.62), "rot": 20.0,
		"fakes": [Vector3(6.0, 0.775, -41.0), Vector3(-7.3, 0.485, -5.0)],
		"short": "A big figure and a small one, holding hands under a yellow sun.",
		"message": "A child's drawing. A big figure and a small one, holding hands under a yellow sun. Your chest tightens. You don't know why."},
	{"id": "photo", "name": "Photo", "prompt": "A photo", "pos": Vector3(7.5, 0.78, -14.7), "rot": -15.0,
		"fakes": [Vector3(13.0, 1.15, -27.0), Vector3(-24.9, 0.63, -22.0)],
		"short": "You, your wife, and a little girl on your shoulders, laughing. Creased right across her.",
		"message": "A creased photo. You, your wife, and a little girl on your shoulders, laughing. You look at the girl for a long time."},
	{"id": "teddy", "name": "Teddy bear", "prompt": "A teddy bear", "pos": Vector3(11.4, 0.48, -60.3), "rot": -90.0,
		"fakes": [Vector3(-41.0, 0.0, -62.0), Vector3(-31.2, 0.0, -29.3)],
		"short": "Worn soft. One button eye. Smaller hands used to hold it.",
		"message": "A worn teddy bear with one button eye. You've held it before. Smaller hands used to hold it too."},
	{"id": "bracelet", "name": "Bracelet", "prompt": "A bracelet", "pos": Vector3(21.0, 0.775, -43.2), "rot": 0.0,
		"fakes": [Vector3(-1.2, 0.0, -48.0), Vector3(4.2, 1.15, -7.6)],
		"short": "Plastic beads on elastic, spelling D-A-D. Far too small for your wrist.",
		"message": "Plastic beads on elastic. The letters spell D-A-D. It's far too small for your wrist."},
	{"id": "ring", "name": "Wedding ring", "prompt": "A ring", "pos": Vector3(-14.45, 0.93, -24.25), "rot": 0.0,
		"fakes": [Vector3(-17.95, 0.6, -20.55), Vector3(6.0, 0.775, -36.0)],
		"short": "Yours. You don't remember taking it off. You wear it again now.",
		"message": "Your wedding ring. You don't remember taking it off. You put it back on. It still fits."},
]

## The wife's letters. They get shorter and colder. "years_after": years after
## Config.YEAR_HE_THINKS it was written (-1 = Config.YEAR_NOW).
const LETTERS := [
	{"id": "letter_1", "month": "March", "years_after": 0, "pos": Vector3(-17.95, 0.6, -20.55),
		"text": "My love,\n\nThe house is so quiet. Some nights I still set the table for three, and then I just sit there.\n\nI'm not angry. I just need you to come back to me. Get well. I'll be here.\n\nAll my love,\nC."},
	{"id": "letter_2", "month": "November", "years_after": 1, "pos": Vector3(5.6, 1.15, -7.4),
		"text": "Hi,\n\nThe doctor says you have good days and bad days. I came once, but they said you didn't know who I was.\n\nPlease get better.\n\nC."},
	{"id": "letter_3", "month": "June", "years_after": 2, "pos": Vector3(9.6, 1.31, -20.0),
		"text": "I don't know if you read these. Write back if you can.\n\nC."},
	{"id": "letter_4", "month": "January", "years_after": -1, "pos": Vector3(6.3, 0.775, -41.2),
		"text": "I need to tell you something when I visit. Please be clean.\n\nC."},
]


static func letter_date(letter: Dictionary) -> String:
	var after: int = letter["years_after"]
	var year: int = Config.YEAR_NOW if after < 0 else Config.YEAR_HE_THINKS + after
	return "%s %d" % [letter["month"], year]


static func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it["id"] == id:
			return it
	return {}


static func letter(id: String) -> Dictionary:
	for l in LETTERS:
		if l["id"] == id:
			return l
	return {}
