extends RefCounted
## Conversations with the staff and group therapy. Each can be had once per in-game day.
## Choice keys: "honest" / "truth" (extra Recovery), "relief" (the nurse eases withdrawal),
## "requires": "truth" (only after all three flashbacks - accepting what happened).
## Run one with: await Dialogues.run("doctor")

const TALKS := {
	"doctor": {
		"name": "Dr. Adler", "base": "talk", "clean_only": true,
		"note": "Session with Dr. Adler.",
		"done": "We'll talk again tomorrow. Go and get some air.",
		"nodes": {
			"start": {"speaker": "Dr. Adler", "text": "Sit down. How are you sleeping?", "choices": [
				{"text": "Badly. I keep seeing headlights when I close my eyes.", "next": "lights", "honest": true},
				{"text": "Fine. I'm fine.", "next": "fine"},
				{"text": "When can I go home?", "next": "home"},
				{"text": "I remember now. The accident. My daughter.", "next": "truth", "requires": "truth", "truth": true}]},
			"lights": {"speaker": "Dr. Adler", "text": "Headlights. Do you know where that comes from?", "choices": [
				{"text": "No. I really don't.", "next": "lights_no"},
				{"text": "I think something happened. Something I did.", "next": "lights_yes", "honest": true}]},
			"lights_no": {"speaker": "Dr. Adler", "text": "Then we'll wait. It usually comes back when you stop running from it."},
			"lights_yes": {"speaker": "Dr. Adler", "text": "Whatever it was, you're here now, talking about it. That counts for more than you think."},
			"fine": {"speaker": "Dr. Adler", "text": "You don't have to perform for me. Nobody gets graded in here.", "choices": [
				{"text": "...Sorry. Not fine, then.", "next": "not_fine", "honest": true},
				{"text": "I said I'm fine.", "next": "closed"}]},
			"not_fine": {"speaker": "Dr. Adler", "text": "Thank you. That's more useful than 'fine'. One day at a time."},
			"closed": {"speaker": "Dr. Adler", "text": "Okay. My door is open."},
			"home": {"speaker": "Dr. Adler", "text": "When you're ready. Your wife wants what you want: for you to come home well.", "choices": [
				{"text": "I'm doing this for her.", "next": "for_her"},
				{"text": "What if I'm never ready?", "next": "never", "honest": true}]},
			"for_her": {"speaker": "Dr. Adler", "text": "Good. Just make sure some of it is for you, too. She can't carry this for you."},
			"never": {"speaker": "Dr. Adler", "text": "Everybody in this building has asked me that. Most of them were wrong."},
			"truth": {"speaker": "Dr. Adler", "text": "...That's the first time you've said it out loud. How does it feel?", "choices": [
				{"text": "Like I can finally breathe.", "next": "breathe"},
				{"text": "Like it was my fault.", "next": "fault"}]},
			"breathe": {"speaker": "Dr. Adler", "text": "Then breathe. You've been holding it for a long time."},
			"fault": {"speaker": "Dr. Adler", "text": "You were driving. That's a fact. What you do with it now is the part you still get to choose."},
		},
	},
	"nurse": {
		"name": "Nurse Bell", "base": "talk", "clean_only": false,
		"note": "Asked the nurses for help.",
		"done": "Come back if it gets bad again. I mean it.",
		"nodes": {
			"start": {"speaker": "Nurse Bell", "text": "How's the shaking today?", "choices": [
				{"text": "Bad. My hands won't stop.", "next": "breathe", "honest": true, "relief": true},
				{"text": "Can I get something for it? Anything?", "next": "nothing"},
				{"text": "I'm okay.", "next": "okay"}]},
			"breathe": {"speaker": "Nurse Bell", "text": "Here. Water first. Now breathe with me. In for four... and out for four.", "next": "breathe_2"},
			"breathe_2": {"speaker": "Nurse Bell", "text": "Better? It won't fix it. But it gets you through the next ten minutes. Then the next ten."},
			"nothing": {"speaker": "Nurse Bell", "text": "Not that. You know not that. But I can sit with you for a minute, if you want.", "choices": [
				{"text": "Okay. Thank you.", "next": "sit", "honest": true, "relief": true},
				{"text": "Forget it.", "next": "forget"}]},
			"sit": {"speaker": "", "text": "She sits with you and doesn't say anything. It helps more than you expected."},
			"forget": {"speaker": "Nurse Bell", "text": "Offer stands. I'm here until eight."},
			"okay": {"speaker": "Nurse Bell", "text": "Then I'll take your word for it. Drink some water anyway."},
		},
	},
	"group": {
		"name": "Maria", "base": "group", "clean_only": true,
		"note": "Attended group therapy.",
		"done": "Same time tomorrow. Your chair will be here.",
		"nodes": {
			"start": {"speaker": "Maria", "text": "Okay, everyone. Let's start. Who wants to go first?", "choices": [
				{"text": "I'll go.", "next": "share"},
				{"text": "I'd rather listen today.", "next": "listen"}]},
			"share": {"speaker": "Maria", "text": "Go ahead. Tell us why you're here.", "choices": [
				{"text": "For my wife. I want to be clean for her.", "next": "wife"},
				{"text": "Honestly? I don't really know.", "next": "dont_know", "honest": true},
				{"text": "Because I lost my daughter. And then I lost myself.", "next": "daughter", "requires": "truth", "truth": true}]},
			"wife": {"speaker": "Dee", "text": "That's a good reason. Make sure it's yours too, though. Mine was my mother. She died before I got clean.", "next": "wife_2"},
			"wife_2": {"speaker": "Maria", "text": "Thank you. Both of you."},
			"dont_know": {"speaker": "Maria", "text": "That's honest. 'I don't know' is a real place to start from."},
			"daughter": {"speaker": "", "text": "The circle is quiet for a long time.", "next": "daughter_2"},
			"daughter_2": {"speaker": "Marcus", "text": "...Thank you for saying that, man.", "next": "daughter_3"},
			"daughter_3": {"speaker": "Maria", "text": "That took courage. You don't have to carry it alone in here."},
			"listen": {"speaker": "Marcus", "text": "Ninety days on Thursday. First time I've made it this far. My kid called me on Sunday. Just to talk.", "next": "listen_2"},
			"listen_2": {"speaker": "Maria", "text": "Anything you'd like to say to Marcus?", "choices": [
				{"text": "That's great. Really.", "next": "listen_3", "honest": true},
				{"text": "(Nod.)", "next": "listen_3"}]},
			"listen_3": {"speaker": "Ray", "text": "Hang on to that phone call.", "next": "listen_4"},
			"listen_4": {"speaker": "Maria", "text": "Same time tomorrow, everyone."},
		},
	},
}


## Has the conversation with this id (doctor/nurse/group) and applies what it gives.
## Returns false if it can't happen right now (already today, or under the influence).
static func run(id: String) -> bool:
	var talk: Dictionary = TALKS[id]
	if not Recovery.can_talk(id):
		Withdrawal.post_message("%s: \"%s\"" % [talk["name"], talk["done"]])
		return false
	if talk["clean_only"] and Withdrawal.is_influenced():
		Withdrawal.post_message("%s: \"Come back when you're clean.\"" % talk["name"])
		return false
	var picked: Array = await Game.start_dialogue(talk["nodes"])
	var gain: float = Config.RECOVERY_GROUP if talk["base"] == "group" else Config.RECOVERY_TALK
	for c in picked:
		if c.get("honest", false):
			gain += Config.RECOVERY_TALK_HONEST
		if c.get("truth", false):
			gain += Config.RECOVERY_TALK_TRUTH
		if c.get("relief", false):
			Withdrawal.meter = maxf(0.0, Withdrawal.meter - Config.NURSE_RELIEF)
	Recovery.mark_talked(id)
	Recovery.add(gain, talk["note"])
	return true
