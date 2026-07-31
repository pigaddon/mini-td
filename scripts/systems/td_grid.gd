extends RefCounted
class_name TdGrid

var cell_size: float = 40.0
var origin: Vector2 = Vector2(40, 80)
var cols: int = 30
var rows: int = 14
var spawn: Vector2i = Vector2i(0, 7)
var exit: Vector2i = Vector2i(29, 7)

## Tower occupation
var blocked: Array = []
## Permanent map walls (cannot build / path through)
var terrain: Array = []


func setup_from_map(data: Dictionary) -> void:
	cell_size = float(data.get("cell_size", 40.0))
	origin = data.get("origin", Vector2(40, 80)) as Vector2
	cols = int(data.get("cols", 30))
	rows = int(data.get("rows", 14))
	spawn = data.get("spawn", Vector2i(0, 7)) as Vector2i
	exit = data.get("exit", Vector2i(29, 7)) as Vector2i
	blocked.clear()
	terrain.clear()
	blocked.resize(cols)
	terrain.resize(cols)
	for x in cols:
		var col_b: Array = []
		var col_t: Array = []
		col_b.resize(rows)
		col_t.resize(rows)
		for y in rows:
			col_b[y] = false
			col_t[y] = false
		blocked[x] = col_b
		terrain[x] = col_t
	var walls: Array = data.get("walls", [])
	for w in walls:
		var cell := w as Vector2i
		if in_bounds(cell) and cell != spawn and cell != exit:
			terrain[cell.x][cell.y] = true


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows


func world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - origin
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return origin + Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size)


func is_buildable_cell(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	if cell == spawn or cell == exit:
		return false
	if is_blocked(cell):
		return false
	return true


func set_blocked(cell: Vector2i, value: bool) -> void:
	if in_bounds(cell):
		blocked[cell.x][cell.y] = value


func is_terrain(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return false
	return bool(terrain[cell.x][cell.y])


func is_blocked(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return true
	return bool(blocked[cell.x][cell.y]) or bool(terrain[cell.x][cell.y])


func rect_world() -> Rect2:
	return Rect2(origin, Vector2(cols * cell_size, rows * cell_size))
