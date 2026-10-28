extends SceneTree
## Writes the copyright and licence notices built into this engine to the file
## given after --, laid out like the engine's COPYRIGHT.txt:
## godot --headless --script tools/write_godot_copyright.gd -- <file>


func _initialize() -> void:
	var stanzas := PackedStringArray([Engine.get_license_text().strip_edges()])
	for component: Dictionary in Engine.get_copyright_info():
		for part: Dictionary in component["parts"]:
			stanzas.append("Files: %s\nComment: %s\nCopyright: %s\nLicense: %s" % [
				"\n ".join(part["files"]), component["name"], "\n ".join(part["copyright"]), part["license"]])
	var licenses := Engine.get_license_info()
	var names := licenses.keys()
	names.sort()
	for license_name: String in names:
		var lines := PackedStringArray(["License: " + license_name])
		for line in String(licenses[license_name]).strip_edges().split("\n"):
			lines.append(" " + line if line.strip_edges() != "" else " .")
		stanzas.append("\n".join(lines))
	var path := OS.get_cmdline_user_args()[0]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		quit(1)
		return
	file.store_string("\n\n".join(stanzas) + "\n")
	quit()
