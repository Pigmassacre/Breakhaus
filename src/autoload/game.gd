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

## The game plays itself (`--autoplay`, for testing).
var autoplay := false
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


func save() -> void:
	var cfg := ConfigFile.new()
	for key: String in settings:
		cfg.set_value("settings", key, settings[key])
	cfg.set_value("scores", "high_scores", high_scores)
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


## Files a finished run's score; its place in the table (from 0), or -1 if it didn't make it.
func add_score(score: int, level: int, combo: int) -> int:
	games_played += 1
	var entry := {"score": score, "level": level, "combo": combo, "date": Time.get_date_string_from_system()}
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
