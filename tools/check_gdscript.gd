extends SceneTree
## Compiles every GDScript in the project and quits with 1 when one fails,
## since an export lets broken scripts through. Run it after an import, which
## brings the global class names up to date:
## godot --headless --path . --script tools/check_gdscript.gd


func _initialize() -> void:
	var paths := PackedStringArray()
	var folders := PackedStringArray(["res://"])
	while not folders.is_empty():
		var folder := folders[folders.size() - 1]
		folders.remove_at(folders.size() - 1)
		for name in DirAccess.get_directories_at(folder):
			if not name.begins_with(".") and name != "builds":
				folders.append(folder.path_join(name))
		for name in DirAccess.get_files_at(folder):
			if name.get_extension() == "gd":
				paths.append(folder.path_join(name))
	paths.sort()
	var failed := 0
	for path in paths:
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("Script does not compile: " + path)
			failed += 1
	print("%d of %d scripts compile" % [paths.size() - failed, paths.size()])
	quit(1 if failed > 0 else 0)
