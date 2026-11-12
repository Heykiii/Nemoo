extends RefCounted
## The campaign story. One chapter per level.
## Speakers: "hero" = the character the player picked, "baron" = the villain,
## everyone else uses the id of a playable character (their costume is reused as a cameo).

const CharacterData := preload("res://scripts/core/character_data.gd")

const BARON := {
	"id": "baron", "name": "Baron Gravity", "tag": "", "kind": "baron",
	"body": Color("3b1f5e"), "pants": Color("2a1646"), "accent": Color("ff4d8d"),
	"skin": Color("f2d7c9"), "hair": Color("1a1a1a"), "shoe": Color("111111"),
}

const CHAPTERS := [
	{"title": "Rooftop Rookie", "place": "Skyline Gym - the roof",
		"intro": [
			["wizard", "Champion! Terrible news. The Golden Chalk Trophy was stolen!"],
			["hero", "Who would do such a thing?"],
			["wizard", "Baron Gravity. He hates anything that flies. His wind machines blow gusts over the whole city."],
			["wizard", "Warm up first. Hold PUMP to swing, tap RELEASE on the forward swing, and land in the gold zone."],
		],
		"outro": [
			["wizard", "Nice landing! The Baron left chalk footprints on the next roof. Follow them!"],
		]},
	{"title": "Pancake Roof", "place": "Pierre's Bakery",
		"intro": [
			["chef", "Bonjour! A man in a tall hat ran over my roof. Zis gap is too wide to walk!"],
			["hero", "Then I will fly over it."],
			["chef", "Flip like a pancake! Hold a FLIP button in the air, then hold EXTEND to land."],
		],
		"outro": [
			["chef", "Magnifique! Take a croissant. Ze Baron went toward ze night market."],
		]},
	{"title": "Silent Landing", "place": "The Night Market",
		"intro": [
			["ninja", "Shh. The Baron's guards are sleeping here. The landing circle is small."],
			["ninja", "Land quietly in the gold zone. A wobbly landing will wake them up."],
		],
		"outro": [
			["ninja", "Silent like a cat. The Baron left a note: 'Catch me if the wind lets you!'"],
		]},
	{"title": "The Twist Clue", "place": "The giant billboard",
		"intro": [
			["scientist", "Eureka! The Baron hid a clue on the back of this billboard."],
			["scientist", "To read it you must twist in the air. Hold TWIST for a half turn, then land."],
		],
		"outro": [
			["scientist", "The clue says: 'Meet me at the docks.' My calculations say: hurry!"],
		]},
	{"title": "Crane Swing", "place": "Harbor Docks",
		"intro": [
			["pirate", "Arr! The cranes here swing from bar to bar."],
			["pirate", "Let go, then tap GRAB when the next bar glows gold. Miss it and ye swim!"],
		],
		"outro": [
			["pirate", "Well done, matey! But the Baron's ship be sailing. After him!"],
		]},
	{"title": "Combo Carnival", "place": "Bobo's Circus",
		"intro": [
			["clown", "HONK! The Baron is hiding in my circus tent!"],
			["clown", "Do two tricks in a row and the big top will open. Combos make the crowd go wild!"],
		],
		"outro": [
			["clown", "HONK HONK! The tent is open. The Baron ran to the construction site!"],
		]},
	{"title": "The Big Pit", "place": "Construction Site",
		"intro": [
			["robot", "BEEP. I used to work for the Baron. He never said thank you."],
			["robot", "The bridge is gone. Swing bar to bar across the pit. Do not fall in. Beep."],
		],
		"outro": [
			["robot", "Beep boop! I am on your team now. The Baron's tower is close."],
		]},
	{"title": "Drone Danger", "place": "Tower Plaza",
		"intro": [
			["astro", "I watched the Baron's drone from space. It flies in a pattern."],
			["astro", "Avoid the pink orb. Watch how it moves and time your flight."],
		],
		"outro": [
			["astro", "Clear skies! Only the tower is left."],
		]},
	{"title": "Rooftop Hop", "place": "The Baron's Tower - lower roof",
		"intro": [
			["viking", "By Odin's beard! The next roof is high."],
			["viking", "Swing, do two tricks, and land on the platform. The wind is strong now!"],
		],
		"outro": [
			["viking", "Valhalla would be proud! The Baron is waiting at the top."],
		]},
	{"title": "Baron Gravity", "place": "The Baron's Tower - the top",
		"intro": [
			["baron", "HA HA HA! Nobody flies in MY city!"],
			["hero", "Watch me."],
			["baron", "My wind machines are at full power. You will never land!"],
			["wizard", "You can do it! Chain the bars, dodge the drone, and stick the landing!"],
		],
		"outro": [
			["baron", "Impossible... You flew right through my storm. I... I think I like flying."],
			["hero", "Come to the gym. We will teach you."],
			["wizard", "The Golden Chalk Trophy is back. And Baron Gravity joined our gym. His first backflip was a disaster."],
			["wizard", "THE END... for now. More adventures coming soon!"],
		]},
]

static func count() -> int:
	return CHAPTERS.size()

static func title(i: int) -> String:
	return CHAPTERS[clampi(i, 0, CHAPTERS.size() - 1)]["title"]

static func place(i: int) -> String:
	return CHAPTERS[clampi(i, 0, CHAPTERS.size() - 1)]["place"]

static func intro_lines(i: int) -> Array:
	return CHAPTERS[clampi(i, 0, CHAPTERS.size() - 1)]["intro"]

static func outro_lines(i: int) -> Array:
	return CHAPTERS[clampi(i, 0, CHAPTERS.size() - 1)]["outro"]

static func palette_for(who: String) -> Dictionary:
	if who == "hero":
		return CharacterData.LIST[int(SaveManager.data["character"])]
	if who == "baron":
		return BARON
	for ch in CharacterData.LIST:
		if ch["id"] == who:
			return ch
	return CharacterData.LIST[0]

static func speaker_name(who: String) -> String:
	if who == "hero":
		return String(palette_for("hero")["name"])
	if who == "baron":
		return "Baron Gravity"
	if who == "wizard":
		return "Coach Merlin"
	return String(palette_for(who)["name"])
