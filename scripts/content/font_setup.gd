extends Node
## Apply Chinese-capable fallback font at startup.


func _ready() -> void:
	var mobile := MapRegistry.is_mobile()
	ThemeDB.fallback_font_size = 30 if mobile else 16
	var candidates: PackedStringArray = [
		"res://assets/fonts/NotoSansSC-Regular.otf",
		"res://assets/fonts/msyh.ttc",
	]
	match OS.get_name():
		"Windows":
			candidates.append("C:/Windows/Fonts/msyh.ttc")
			candidates.append("C:/Windows/Fonts/msyhbd.ttc")
		"Android":
			candidates.append("/system/fonts/NotoSansCJK-Regular.ttc")
			candidates.append("/system/fonts/NotoSansSC-Regular.otf")
			candidates.append("/system/fonts/DroidSansFallback.ttf")
		"macOS":
			candidates.append("/System/Library/Fonts/PingFang.ttc")
			candidates.append("/System/Library/Fonts/STHeiti Light.ttc")
	for path in candidates:
		if path.begins_with("res://"):
			if not ResourceLoader.exists(path):
				continue
		elif not FileAccess.file_exists(path):
			continue
		var font := FontFile.new()
		var err := font.load_dynamic_font(path)
		if err != OK:
			continue
		font.multichannel_signed_distance_field = true
		ThemeDB.fallback_font = font
		ThemeDB.fallback_font_size = 30 if mobile else 16
		return
	push_warning("No Chinese font found; UI text may not display correctly.")
