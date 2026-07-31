extends RefCounted
class_name Pathfinder


static func find_path(grid: TdGrid, ignore_blocked: bool = false) -> PackedVector2Array:
	var start: Vector2i = grid.spawn
	var goal: Vector2i = grid.exit
	if not grid.in_bounds(start) or not grid.in_bounds(goal):
		return PackedVector2Array()

	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _heuristic(start, goal)}
	var closed: Dictionary = {}

	while not open.is_empty():
		var current: Vector2i = _pop_lowest(open, f_score)
		if current == goal:
			return _reconstruct(grid, came_from, current)

		closed[current] = true
		for next in _neighbors(current):
			if not grid.in_bounds(next):
				continue
			if closed.has(next):
				continue
			if not ignore_blocked and grid.is_blocked(next) and next != goal:
				continue
			var tentative: int = int(g_score[current]) + 1
			if tentative < int(g_score.get(next, 1_000_000)):
				came_from[next] = current
				g_score[next] = tentative
				f_score[next] = tentative + _heuristic(next, goal)
				if not open.has(next):
					open.append(next)

	return PackedVector2Array()


static func has_path(grid: TdGrid) -> bool:
	return not find_path(grid, false).is_empty()


static func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1),
	]


static func _pop_lowest(open: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var best_i := 0
	var best_f: int = int(f_score.get(open[0], 1_000_000))
	for i in range(1, open.size()):
		var f: int = int(f_score.get(open[i], 1_000_000))
		if f < best_f:
			best_f = f
			best_i = i
	return open.pop_at(best_i)


static func _reconstruct(grid: TdGrid, came_from: Dictionary, current: Vector2i) -> PackedVector2Array:
	var cells: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current] as Vector2i
		cells.push_front(current)
	var points := PackedVector2Array()
	for c in cells:
		points.append(grid.cell_to_world_center(c))
	return points
