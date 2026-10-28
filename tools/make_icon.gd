extends SceneTree
## Makes icon.ico, the Windows icon, from icon.svg: drawn afresh at each size
## Windows asks for (so the small ones stay sharp, not shrunk from a big
## one), each kept as a PNG inside the .ico.
## godot --headless --path . --script tools/make_icon.gd

const SIZES := [16, 20, 24, 32, 40, 48, 64, 128, 256]


func _initialize() -> void:
	var svg := FileAccess.get_file_as_string("res://icon.svg")
	var width := float(svg.get_slice("width=\"", 1).get_slice("\"", 0))
	var images: Array[PackedByteArray] = []
	for size: int in SIZES:
		var image := Image.new()
		if image.load_svg_from_string(svg, size / width) != OK:
			printerr("Cannot draw icon.svg")
			quit(1)
			return
		if image.get_width() != size:
			image.resize(size, size, Image.INTERPOLATE_LANCZOS)
		images.append(image.save_png_to_buffer())
	# The .ico: a header, an entry for each image, then the images.
	var out := StreamPeerBuffer.new()
	out.put_u16(0)
	out.put_u16(1)
	out.put_u16(SIZES.size())
	var offset := 6 + 16 * SIZES.size()
	for i in SIZES.size():
		var size: int = SIZES[i]
		out.put_u8(size % 256)
		out.put_u8(size % 256)
		out.put_u8(0)
		out.put_u8(0)
		out.put_u16(1)
		out.put_u16(32)
		out.put_u32(images[i].size())
		out.put_u32(offset)
		offset += images[i].size()
	for png in images:
		out.put_data(png)
	var file := FileAccess.open("res://icon.ico", FileAccess.WRITE)
	file.store_buffer(out.data_array)
	print("icon.ico: %s px" % ", ".join(SIZES.map(func(s: int) -> String: return str(s))))
	quit()
