class_name Challenges
## Goals to reach, each unlocking a paddle skin or a ball trail
## (Cosmetics). The game tells Game.note() what happens ("combo", 23) and
## any challenge on that event whose mark it reaches is done.

const LIST := [
	{"id": "first_floor", "name": "Going Down", "goal": "Clear a floor.", "event": "cleared", "at": 1, "paddle": "hazard"},
	{"id": "combo_20", "name": "Combo Kid", "goal": "Reach a 20 combo.", "event": "combo", "at": 20, "trail": "gold"},
	{"id": "fever", "name": "Fever Dream", "goal": "Set off Fever.", "event": "fever", "at": 1, "trail": "rainbow"},
	{"id": "sweep", "name": "Clean Freak", "goal": "Get a clean sweep.", "event": "sweep", "at": 1, "paddle": "mint"},
	{"id": "no_miss", "name": "Untouchable", "goal": "Clear a floor without missing.", "event": "clean_floor", "at": 1, "paddle": "chrome"},
	{"id": "rare", "name": "Lucky Find", "goal": "Catch a rare pickup.", "event": "rare", "at": 1, "trail": "mint"},
	{"id": "synergy", "name": "Mad Scientist", "goal": "Set off a synergy.", "event": "synergy", "at": 1, "trail": "plasma"},
	{"id": "smashes", "name": "Smash Hit", "goal": "Land 10 smashes on one floor.", "event": "smashes", "at": 10, "paddle": "neon"},
	{"id": "perks", "name": "Loaded", "goal": "Have five perks in one run.", "event": "perks", "at": 5, "trail": "fire"},
	{"id": "demolish", "name": "Demolition Crew", "goal": "Demolish the haus.", "event": "cleared", "at": 8, "paddle": "gold"},
	{"id": "boss", "name": "Boss Buster", "goal": "Beat a boss.", "event": "boss", "at": 1, "paddle": "royal"},
	{"id": "deep", "name": "Deep Dive", "goal": "Reach basement B3.", "event": "reached", "at": 10, "paddle": "obsidian"},
	{"id": "rush", "name": "Rush Hour", "goal": "Score 50,000 in Rush.", "event": "rush_score", "at": 50000, "trail": "lightning"},
	{"id": "daily", "name": "Daily Grind", "goal": "Score 10,000 in a Daily Haus.", "event": "daily_score", "at": 10000, "trail": "sunset"},
]


## The challenge that unlocks paddle skin or trail `look` ("paddle" or "trail"), or an empty one.
static func unlocking(kind: String, look: String) -> Dictionary:
	for c: Dictionary in LIST:
		if c.get(kind, "") == look:
			return c
	return {}


## What it unlocks, as words: "the Gold paddle".
static func reward(c: Dictionary) -> String:
	if c.has("paddle"):
		return "the %s paddle" % Cosmetics.PADDLES[c["paddle"]]["name"]
	return "the %s trail" % Cosmetics.TRAILS[c["trail"]]["name"]
