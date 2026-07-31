extends RefCounted
class_name MapRegistry


static func all_map_ids() -> PackedStringArray:
	return PackedStringArray([
		"cross_field",
		"corner_dash",
		"vertical_run",
		"diagonal_siege",
		"twin_fork",
		"canyon_run",
		"river_bend",
	])


static func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile")


static func get_map(map_id: String) -> Dictionary:
	var mobile := is_mobile()
	var cols := 12 if mobile else 16
	var rows := 7 if mobile else 9
	var mid_x := int(cols / 2)
	var mid_y := int(rows / 2)
	var last_x := cols - 1
	var last_y := rows - 1

	var spawn := Vector2i(0, mid_y)
	var exit_cell := Vector2i(last_x, mid_y)
	var walls: Array[Vector2i] = []

	match map_id:
		"corner_dash":
			spawn = Vector2i(0, 0)
			exit_cell = Vector2i(last_x, last_y)
		"vertical_run":
			spawn = Vector2i(mid_x, 0)
			exit_cell = Vector2i(mid_x, last_y)
		"diagonal_siege":
			spawn = Vector2i(0, last_y)
			exit_cell = Vector2i(last_x, 0)
		"twin_fork":
			spawn = Vector2i(0, mid_y)
			exit_cell = Vector2i(last_x, mid_y)
			# Middle pillar with a gap so path must detour.
			for y in rows:
				if y == mid_y:
					continue
				walls.append(Vector2i(mid_x, y))
		"canyon_run":
			spawn = Vector2i(0, mid_y)
			exit_cell = Vector2i(last_x, mid_y)
			# Top and bottom ridges leave a center corridor.
			for x in range(2, last_x - 1):
				walls.append(Vector2i(x, 0))
				if rows > 2:
					walls.append(Vector2i(x, last_y))
				if rows >= 5:
					walls.append(Vector2i(x, 1))
					walls.append(Vector2i(x, last_y - 1))
		"river_bend":
			spawn = Vector2i(0, 1)
			exit_cell = Vector2i(last_x, last_y - 1 if last_y > 0 else 0)
			# Horizontal river wall with one bridge gap.
			var bridge := mid_x + 1
			for x in cols:
				if x == bridge:
					continue
				walls.append(Vector2i(x, mid_y))
		"cross_field", _:
			spawn = Vector2i(0, mid_y)
			exit_cell = Vector2i(last_x, mid_y)
			map_id = "cross_field"

	return _base(map_id, _name_key(map_id), spawn, exit_cell, walls, mobile, cols, rows)


static func _name_key(map_id: String) -> String:
	match map_id:
		"corner_dash":
			return "map_corner"
		"vertical_run":
			return "map_vertical"
		"diagonal_siege":
			return "map_diagonal"
		"twin_fork":
			return "map_twin"
		"canyon_run":
			return "map_canyon"
		"river_bend":
			return "map_river"
		_:
			return "map_cross"


static func get_map_name(map_id: String) -> String:
	return UiText.t(str(get_map(map_id).get("name_key", map_id)))


static func unit_scale() -> float:
	# Keep units readable relative to larger cells.
	return 2.35 if is_mobile() else 1.55


static func _base(
	id: String,
	name_key: String,
	spawn: Vector2i,
	exit_cell: Vector2i,
	walls: Array[Vector2i],
	mobile: bool,
	cols: int,
	rows: int
) -> Dictionary:
	if mobile:
		return {
			"id": id,
			"name_key": name_key,
			"cell_size": 96.0,
			"origin": Vector2(48, 110),
			"cols": cols,
			"rows": rows,
			"spawn": spawn,
			"exit": exit_cell,
			"walls": walls,
		}
	return {
		"id": id,
		"name_key": name_key,
		"cell_size": 68.0,
		"origin": Vector2(96, 68),
		"cols": cols,
		"rows": rows,
		"spawn": spawn,
		"exit": exit_cell,
		"walls": walls,
	}
