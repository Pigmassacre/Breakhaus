class_name Perks
## The perks: after every floor cleared you pick one of three, and it lasts
## for the rest of the run. Most stack a few times ("max"). Each has a
## pixel icon in the pickups' style (rows of art pixels, a letter to a
## colour from its palette, "." see-through) or borrows a pickup's.

const INFO := {
	"long_fuse": {"name": "Long Fuse", "blurb": "Combos last 50% longer.", "max": 2, "color": Color("3dffb1"),
		"palette": {"k": Color("1a1420"), "w": Color("f4f4fb"), "g": Color("2fbf7a")}, "rows": [
			"..kkkk..", ".kwwwwk.", "kwwgwwwk", "kwwgwwwk", "kwwgggwk", "kwwwwwwk", ".kwwwwk.", "..kkkk.."]},
	"sweet_spot": {"name": "Sweet Spot", "blurb": "More time to land a smash.", "max": 2, "color": Color("fff23d"),
		"palette": {"r": Color("ff3d5a"), "w": Color("f4f4fb"), "y": Color("fff23d")}, "rows": [
			"..rrrr..", ".rwwwwr.", "rwrrrrwr", "rwryyrwr", "rwryyrwr", "rwrrrrwr", ".rwwwwr.", "..rrrr.."]},
	"lucky": {"name": "Lucky", "blurb": "Pickups drop 50% more often.", "max": 3, "color": Color("7dff3d"),
		"palette": {"g": Color("1f7a2a"), "G": Color("5fdc4a"), "k": Color("4a2a10")}, "rows": [
			".gg..gg.", "gGGggGGg", "gGGGGGGg", ".gGGGGg.", "gGGGGGGg", "gGGggGGg", ".gg.kgg.", "....k..."]},
	"rare_taste": {"name": "Rare Taste", "blurb": "Rare pickups turn up twice as often.", "max": 2, "color": Color("ffd23d"),
		"palette": {"y": Color("c98a10"), "Y": Color("ffd23d")}, "rows": [
			"...yy...", "...YY...", "yyyYYyyy", ".yYYYYy.", "..yYYy..", ".yYyyYy.", ".yy..yy.", "........"]},
	"big_bang": {"name": "Big Bang", "blurb": "TNT and fuses hit harder and further.", "max": 1, "color": Color("ffb03b"),
		"pickup": Pickups.Kind.BLAST},
	"safety_net": {"name": "Safety Net", "blurb": "Your first miss on every floor is free.", "max": 1, "color": Color("6ad8ff"),
		"pickup": Pickups.Kind.SHIELD},
	"heavy_ball": {"name": "Heavy Ball", "blurb": "Every hit does one more damage.", "max": 1, "color": Color("b0b0c8"),
		"palette": {"k": Color("14141c"), "d": Color("4a4a5a"), "w": Color("d0d0e0")}, "rows": [
			"..kkkk..", ".kddddk.", "kdwddddk", "kdwddddk", "kddddddk", "kddddddk", ".kddddk.", "..kkkk.."]},
	"wide_load": {"name": "Wide Load", "blurb": "A wider paddle, for good.", "max": 2, "color": Color("ff8af0"),
		"palette": {"k": Color("1a1420"), "w": Color("e8e8f0"), "p": Color("ff4fa3")}, "rows": [
			"........", ".k....k.", "kk....kk", "pwwwwwwp", "pwwwwwwp", "kk....kk", ".k....k.", "........"]},
	"quick_quake": {"name": "Quick Quake", "blurb": "Your Quake charges 40% faster.", "max": 2, "color": Color("ffb03b"),
		"palette": {"o": Color("ffb03b"), "y": Color("fff0a0")}, "rows": [
			"....oo..", "...oy...", "..oo....", ".ooyyoo.", "....oo..", "...oy...", "..oo....", "........"]},
	"slow_wall": {"name": "Slow Wall", "blurb": "The wall waits 12% longer between drops.", "max": 3, "color": Color("46d9ff"),
		"palette": {"b": Color("c0392b"), "w": Color("f4f4fb")}, "rows": [
			"bbbb.bbb", "........", "bb.bbbb.", "........", "..ww.ww.", "..ww.ww.", "..ww.ww.", "..ww.ww."]},
	"gold_digger": {"name": "Gold Digger", "blurb": "Gold and coin blocks pay double.", "max": 2, "color": Color("ffc933"),
		"palette": {"y": Color("c98a10"), "Y": Color("ffd23d")}, "rows": [
			"..yyyy..", ".yYYYYy.", "yYYyyYYy", "yYyYYYYy", "yYyYYYYy", "yYYyyYYy", ".yYYYYy.", "..yyyy.."]},
	"extra_ball": {"name": "Extra Ball", "blurb": "Every serve comes with a spare ball.", "max": 1, "color": Color("f4f4fb"),
		"palette": {"k": Color("26262e"), "w": Color("f4f4fb")}, "rows": [
			"..kk....", ".kwwk...", ".kwwk...", "..kk....", "....kk..", "...kwwk.", "...kwwk.", "....kk.."]},
	"hot_streak": {"name": "Hot Streak", "blurb": "Fever lasts four seconds longer.", "max": 2, "color": Color("ff3dff"),
		"palette": {"r": Color("ff3d6e"), "o": Color("ff8a3d"), "y": Color("ffe066")}, "rows": [
			"...r....", "..rr..r.", "..rorr..", ".roorr.r", ".royorr.", "rooyyorr", "royyyyor", ".rooyor."]},
	"long_haul": {"name": "Long Haul", "blurb": "Pickups last 30% longer.", "max": 2, "color": Color("9a7aff"),
		"palette": {"k": Color("2a1a4a"), "y": Color("ffd23d")}, "rows": [
			"kkkkkkkk", ".kyyyyk.", "..kyyk..", "...kk...", "...kk...", "..kyyk..", ".kyyyyk.", "kkkkkkkk"]},
}


static func info(id: String) -> Dictionary:
	return INFO[id]


## Up to three perks to choose from, none of them already as far as it goes in `owned` (id -> count).
static func offer(rng: RandomNumberGenerator, owned: Dictionary, count := 3) -> Array[String]:
	var open: Array[String] = []
	for id: String in INFO:
		if int(owned.get(id, 0)) < int(INFO[id]["max"]):
			open.append(id)
	var out: Array[String] = []
	while out.size() < count and not open.is_empty():
		out.append(open.pop_at(rng.randi() % open.size()))
	return out


## The perk's icon into `canvas`, its middle at `at`, `scale` screen pixels to one of its own.
static func draw_icon(canvas: CanvasItem, id: String, at: Vector2, scale: float) -> void:
	var perk: Dictionary = INFO[id]
	if perk.has("pickup"):
		Pickups.draw_icon(canvas, perk["pickup"], at, scale)
		return
	var rows: Array = perk["rows"]
	var palette: Dictionary = perk["palette"]
	var o := at - Vector2(8, rows.size()) * scale * 0.5
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				canvas.draw_rect(Rect2(o + Vector2(x, y) * scale, Vector2(scale, scale)), palette[row[x]])
