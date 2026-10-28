class_name Modes
## The ways to play. Classic: the haus floor by floor, down to the ground
## and on into the basements for as long as you last. Daily Haus: today's
## haus, its rows the same for everyone who plays it today, with the day's
## twist. Rush: three minutes on the clock and the wall in a hurry; a floor
## cleared or a board swept buys more time.

const CLASSIC := "classic"
const DAILY := "daily"
const RUSH := "rush"
const ALL := [CLASSIC, DAILY, RUSH]

const INFO := {
	CLASSIC: {"name": "Classic", "blurb": "Smash your way down. How deep can you go?"},
	DAILY: {"name": "Daily Haus", "blurb": "The same haus for everyone today, with a twist. New one every day."},
	RUSH: {"name": "Rush", "blurb": "Three minutes on the clock. Clear floors for extra time."},
}

## The Daily Haus's twists, one a day: a name, a line, and what changes. Multipliers on how often
## each kind of block comes ("steel", "tnt", "gold", "moss", "tough"), how often pickups drop
## ("drop"), the time between waves ("wave"), the points ("score"), and balls per serve ("balls").
const TWISTS := [
	{"name": "Lucky Day", "blurb": "Triple the pickups.", "drop": 3.0},
	{"name": "Demolition Day", "blurb": "TNT everywhere.", "tnt": 4.0},
	{"name": "Gold Rush", "blurb": "Way more gold.", "gold": 5.0},
	{"name": "Rush Hour", "blurb": "Faster wall, 1.5x points.", "wave": 0.7, "score": 1.5},
	{"name": "Triple Trouble", "blurb": "Three balls per serve.", "balls": 3},
	{"name": "Hard Hats", "blurb": "Tougher blocks, more steel, 1.5x points.", "tough": 2.0, "steel": 2.5, "score": 1.5},
	{"name": "Overgrown", "blurb": "Moss. Lots of moss.", "moss": 4.0},
]

## Rush: the clock to start with, the time a floor cleared and a sweep add, and the waves' pace.
const RUSH_TIME := 180.0
const RUSH_FLOOR_BONUS := 30.0
const RUSH_SWEEP_BONUS := 10.0
const RUSH_WAVE := 0.7


static func name_of(mode: String) -> String:
	return INFO[mode]["name"]


## Today, as the Daily Haus knows it: "2026-10-28", in the player's own time zone.
static func today() -> String:
	return Time.get_date_string_from_system()


static func daily_seed(date: String) -> int:
	return absi(hash("breakhaus " + date))


static func daily_twist(date: String) -> Dictionary:
	return TWISTS[daily_seed(date) % TWISTS.size()]
