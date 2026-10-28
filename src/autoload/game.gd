extends Node
## What lasts between games: the settings, the high scores, and getting
## from one screen to the next. Saved in user://breakhaus.cfg.

signal settings_changed

const SAVE_PATH := "user://breakhaus.cfg"
const HIGH_SCORES := 10

const DEFAULTS := {
	"music": 0.7,
	"sounds": 0.85,
	"shake": 1.0,
	"flashes": true,
	"fullscreen": false,
	"touch_gain": 1.0,
}

var settings := DEFAULTS.duplicate()
## The best runs, best first: {"score", "level" (the floor reached, from 0), "combo", "date"}.
var high_scores: Array = []
var games_played := 0
## Whether How to play has been seen (the first game shows it first).
var seen_help := false
## Runs that have reached the ground floor's end: the haus demolished.
var demolished := 0
## The mode the next game is played in (Modes), the best Rush, and today's Daily Haus:
## {"date", "best", "tries"} (a new day starts it over).
var mode := Modes.CLASSIC
var rush_best := {}
var daily := {}

## The game plays itself (`--autoplay`, for testing).
var autoplay := false
## Or launches and does nothing else (`--autoplay=lazy`): the wall wins, for testing the end.
var autoplay_lazy := false
## Every floor a single row (`--short-floors`, for testing what happens between them).
var short_floors := false
## The screen being shown (main.gd swaps them).
var main: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save()
	apply_settings()


func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key: String in DEFAULTS:
		settings[key] = cfg.get_value("settings", key, DEFAULTS[key])
	high_scores = cfg.get_value("scores", "high_scores", [])
	games_played = cfg.get_value("scores", "games_played", 0)
	demolished = cfg.get_value("scores", "demolished", 0)
	seen_help = cfg.get_value("progress", "seen_help", false)
	rush_best = cfg.get_value("scores", "rush_best", {})
	daily = cfg.get_value("scores", "daily", {})


func save() -> void:
	var cfg := ConfigFile.new()
	for key: String in settings:
		cfg.set_value("settings", key, settings[key])
	cfg.set_value("scores", "high_scores", high_scores)
	cfg.set_value("scores", "rush_best", rush_best)
	cfg.set_value("scores", "daily", daily)
	cfg.set_value("scores", "games_played", games_played)
	cfg.set_value("scores", "demolished", demolished)
	cfg.set_value("progress", "seen_help", seen_help)
	cfg.save(SAVE_PATH)


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_settings()
	save()


func apply_settings() -> void:
	Audio.set_volume(Audio.MUSIC, settings["music"])
	Audio.set_volume(Audio.SOUNDS, settings["sounds"])
	if can_fullscreen():
		var full := DisplayServer.WINDOW_MODE_FULLSCREEN
		var want: int = full if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		if (DisplayServer.window_get_mode() == full) != (want == full):
			DisplayServer.window_set_mode(want)
	settings_changed.emit()


## A window that can go full screen (not on a phone).
func can_fullscreen() -> bool:
	return not OS.has_feature("mobile")


## A game that can be quit from its menu (not in a browser, where there is nothing to quit to).
func can_quit() -> bool:
	return not OS.has_feature("web") and not OS.has_feature("ios")


func best_score() -> int:
	return high_scores[0]["score"] if not high_scores.is_empty() else 0


## The best in `mode`: Classic's table's top, the best Rush, or today's best Daily Haus.
func mode_best(which: String) -> int:
	match which:
		Modes.RUSH:
			return int(rush_best.get("score", 0))
		Modes.DAILY:
			return int(today_daily().get("best", 0))
	return best_score()


## Today's Daily Haus record, a fresh one if the last was another day.
func today_daily() -> Dictionary:
	if daily.get("date", "") != Modes.today():
		daily = {"date": Modes.today(), "best": 0, "tries": 0}
	return daily


## Files a finished run's score in `game_mode`; its place in that mode's table (from 0; Rush and the
## Daily Haus keep only the best), or -1 if it didn't make it.
func add_score(score: int, level: int, combo: int, game_mode := Modes.CLASSIC) -> int:
	# A game that played itself isn't kept.
	if autoplay or autoplay_lazy:
		return -1
	games_played += 1
	var entry := {"score": score, "level": level, "combo": combo, "date": Time.get_date_string_from_system()}
	if game_mode == Modes.RUSH:
		var beat := score > int(rush_best.get("score", 0))
		if beat:
			rush_best = entry
		save()
		return 0 if beat else -1
	if game_mode == Modes.DAILY:
		var today := today_daily()
		today["tries"] = int(today["tries"]) + 1
		var beat := score > int(today["best"])
		if beat:
			today["best"] = score
		save()
		return 0 if beat else -1
	var place := high_scores.size()
	for i in high_scores.size():
		if score > int(high_scores[i]["score"]):
			place = i
			break
	if score > 0:
		high_scores.insert(place, entry)
	if high_scores.size() > HIGH_SCORES:
		high_scores.resize(HIGH_SCORES)
	save()
	return place if place < HIGH_SCORES and score > 0 else -1


## A buzz of the phone, `ms` long (on a phone).
func buzz(ms: int) -> void:
	if OS.has_feature("mobile") and float(settings["shake"]) > 0.0:
		Input.vibrate_handheld(ms)


func _unhandled_input(event: InputEvent) -> void:
	# F11, or Alt and Enter: full screen and back.
	if event is InputEventKey and event.pressed and not event.echo and can_fullscreen():
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			set_setting("fullscreen", not settings["fullscreen"])
			get_viewport().set_input_as_handled()


func shake_amount() -> float:
	return float(settings["shake"])


func flashes() -> bool:
	return bool(settings["flashes"])


## Shows a screen: "splash", "title", "play", "options", "help" or "scores".
func goto(screen: String, args := {}) -> void:
	main.show_screen(screen, args)


static func version_text() -> String:
	var text := "Version %s" % ProjectSettings.get_setting("application/config/version", "")
	var commit := ""
	if OS.has_feature("template"):
		if FileAccess.file_exists("res://commit.txt"):
			commit = FileAccess.get_file_as_string("res://commit.txt").strip_edges()
	elif not OS.has_feature("web") and not OS.has_feature("mobile"):
		var output := []
		if OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "--short", "HEAD"], output) == 0:
			commit = String(output[0]).strip_edges()
	return text + (" (%s)" % commit if commit != "" else "")
