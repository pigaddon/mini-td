extends Node2D
class_name Enemy

signal died(enemy: Enemy, reward: int)
signal reached_end(enemy: Enemy)
signal will_split(parent: Enemy)

var enemy_id: String = "normal"
var max_hp: float = 30.0
var base_speed: float = 90.0
var reward: int = 10
var damage_to_base: int = 1
var armor: float = 0.0
var is_flying: bool = false
var resist_splash: float = 0.0
var resist_slow: float = 0.0

## 分裂怪：tier 0 最大，达到 split_max_tier 后死亡不再分裂
var split_tier: int = 0
var split_max_tier: int = 0

var hp: float
var alive: bool = true
var path_points: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var traveled: float = 0.0

var _slow_timer: float = 0.0
var _slow_factor: float = 0.0
var _poison_timer: float = 0.0
var _poison_dps: float = 0.0
var _base_color: Color = Color(0.85, 0.25, 0.22)

@onready var hp_bar: ProgressBar = $HPBar
@onready var body: Polygon2D = $Body


func _ready() -> void:
	add_to_group("enemies")


func setup(
	def: Dictionary,
	points: PackedVector2Array,
	hp_mult: float,
	reward_mult: float,
	armor_bonus: float = 0.0,
	speed_mult: float = 1.0
) -> void:
	enemy_id = str(def.get("id", "normal"))
	max_hp = float(def["hp"]) * hp_mult
	base_speed = float(def["speed"]) * speed_mult
	# 分裂怪始终无甲
	if enemy_id == "splitter":
		armor = 0.0
	else:
		armor = float(def["armor"]) + armor_bonus
	reward = int(round(float(def["reward"]) * reward_mult))
	damage_to_base = int(def["damage_to_base"])
	is_flying = bool(def["flying"])
	resist_splash = float(def["resist_splash"])
	resist_slow = float(def["resist_slow"])
	split_tier = int(def.get("split_tier", 0))
	split_max_tier = int(def.get("split_max_tier", 0))
	hp = max_hp
	path_points = points
	path_index = 0
	traveled = 0.0
	_base_color = def["color"]
	var scale_v := float(def.get("scale", 1.0)) * MapRegistry.unit_scale()
	scale = Vector2(scale_v, scale_v)
	if is_inside_tree():
		_apply_visual()
		_snap_to_path_start()


func setup_as_split_child(parent: Enemy, slot: int) -> void:
	enemy_id = parent.enemy_id
	split_tier = parent.split_tier + 1
	split_max_tier = parent.split_max_tier
	max_hp = maxf(1.0, parent.max_hp * 0.5)
	hp = max_hp
	base_speed = parent.base_speed * (1.0 + 0.03 * split_tier)
	armor = 0.0
	reward = maxi(1, int(round(float(parent.reward) * 0.5)))
	damage_to_base = 1
	is_flying = false
	resist_splash = parent.resist_splash
	resist_slow = parent.resist_slow
	_base_color = parent._base_color
	path_points = parent.path_points.duplicate()
	path_index = parent.path_index
	traveled = parent.traveled
	var scale_v := (1.2 - split_tier * 0.2) * MapRegistry.unit_scale()
	scale = Vector2(scale_v, scale_v)
	var side := -1.0 if slot == 0 else 1.0
	var along := Vector2.RIGHT
	if path_index < path_points.size() - 1:
		along = (path_points[path_index + 1] - parent.global_position).normalized()
	elif path_index > 0:
		along = (path_points[path_index] - path_points[path_index - 1]).normalized()
	if along == Vector2.ZERO:
		along = Vector2.RIGHT
	var perp := Vector2(-along.y, along.x) * side * (10.0 + split_tier * 2.0)
	global_position = parent.global_position + perp
	_apply_visual()


func can_split() -> bool:
	return enemy_id == "splitter" and split_tier < split_max_tier


func _apply_visual() -> void:
	if body == null:
		body = get_node_or_null("Body") as Polygon2D
	if hp_bar == null:
		hp_bar = get_node_or_null("HPBar") as ProgressBar
	if body:
		body.color = _base_color
		modulate = Color.WHITE
		match enemy_id:
			"flying":
				# 飞机形三角
				body.polygon = PackedVector2Array([-14, 6, 0, -16, 14, 6, 0, -2])
				body.color = Color(0.1, 1.0, 0.2)
				modulate = Color(1.15, 1.35, 1.1)
			"splitter":
				# 菱形，越大越显眼
				var s := 12.0 - split_tier * 1.5
				body.polygon = PackedVector2Array([0, -s, s * 0.75, 0, 0, s, -s * 0.75, 0])
				body.color = Color(0.95, 0.3, 0.85).lerp(Color(0.75, 0.55, 1.0), float(split_tier) / 3.0)
			"fast":
				# 细长飞镖
				body.polygon = PackedVector2Array([-12, -5, 16, 0, -12, 5, -6, 0])
			"armored":
				# 厚六边形装甲
				body.polygon = PackedVector2Array([0, -14, 12, -7, 12, 7, 0, 14, -12, 7, -12, -7])
			"swarm":
				# 小圆点虫群
				body.polygon = PackedVector2Array([
					0, -8, 6, -6, 8, 0, 6, 6, 0, 8, -6, 6, -8, 0, -6, -6
				])
			"boss":
				# 大冠形 Boss
				body.polygon = PackedVector2Array([
					-16, 10, -10, -4, -6, -14, 0, -8, 6, -14, 10, -4, 16, 10, 8, 14, -8, 14
				])
			_:
				# 普通：箭头
				body.polygon = PackedVector2Array([-10, -10, 14, 0, -10, 10])
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		match enemy_id:
			"flying":
				hp_bar.modulate = Color(0.4, 1.0, 0.5)
			"splitter":
				hp_bar.modulate = Color(1.0, 0.55, 1.0)
			"boss":
				hp_bar.modulate = Color(1.0, 0.45, 0.85)
			_:
				hp_bar.modulate = Color.WHITE
	_refresh_status_visual()


func _snap_to_path_start() -> void:
	if path_points.is_empty():
		return
	global_position = path_points[0]
	path_index = 0


func repath(points: PackedVector2Array) -> void:
	if is_flying or points.is_empty():
		return
	var best_i := 0
	var best_d := INF
	for i in points.size():
		var d := global_position.distance_squared_to(points[i])
		if d < best_d:
			best_d = d
			best_i = i
	path_points = points
	path_index = mini(best_i, points.size() - 1)


func _process(delta: float) -> void:
	if not alive:
		return
	_update_status(delta)
	if not alive or path_points.is_empty():
		return
	var speed := base_speed * (1.0 - clampf(_slow_factor, 0.0, 0.85))
	var remaining := speed * delta
	while remaining > 0.0 and path_index < path_points.size() - 1:
		var target := path_points[path_index + 1]
		var to_target := target - global_position
		var dist := to_target.length()
		if dist <= 0.001:
			path_index += 1
			continue
		if dist <= remaining:
			global_position = target
			traveled += dist
			remaining -= dist
			path_index += 1
			if body:
				body.rotation = to_target.angle()
		else:
			global_position += to_target.normalized() * remaining
			traveled += remaining
			remaining = 0.0
			if body:
				body.rotation = to_target.angle()
	if path_index >= path_points.size() - 1:
		alive = false
		reached_end.emit(self)
		queue_free()


func _update_status(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 0.0
	if _poison_timer > 0.0:
		_poison_timer -= delta
		take_damage(_poison_dps * delta, 4.0, false)
		if _poison_timer <= 0.0:
			_poison_dps = 0.0
		_refresh_status_visual()


func take_damage(amount: float, pierce: float = 0.0, show_flash: bool = true) -> void:
	if not alive or amount <= 0.0:
		return
	var effective_armor := maxf(0.0, armor - pierce)
	var final_dmg := amount - effective_armor
	var floor_dmg := amount * 0.2
	final_dmg = maxf(floor_dmg, final_dmg)
	if not show_flash:
		# DoT ticks are tiny per frame; keep a floor so armor can't nullify poison.
		final_dmg = maxf(amount * 0.45, amount - effective_armor * 0.2)
	if final_dmg <= 0.0:
		return
	hp -= final_dmg
	if hp_bar:
		hp_bar.value = hp
	if show_flash:
		_flash()
	if hp <= 0.0:
		alive = false
		if can_split():
			will_split.emit(self)
		died.emit(self, reward)
		queue_free()


func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = maxf(_slow_factor, factor)
	_slow_timer = maxf(_slow_timer, duration)


func apply_poison(dps: float, duration: float) -> void:
	if dps >= _poison_dps:
		_poison_dps = dps
	_poison_timer = maxf(_poison_timer, duration)
	_refresh_status_visual()


func _skin_color() -> Color:
	match enemy_id:
		"flying":
			return Color(0.1, 1.0, 0.2)
		"splitter":
			return Color(0.95, 0.3, 0.85).lerp(Color(0.75, 0.55, 1.0), float(split_tier) / 3.0)
		_:
			return _base_color


func _refresh_status_visual() -> void:
	if body == null:
		body = get_node_or_null("Body") as Polygon2D
	if body == null:
		return
	if _poison_timer > 0.0:
		# Strong toxic yellow-green, distinct from flying green.
		body.color = Color(0.7, 1.0, 0.05)
		modulate = Color(1.35, 1.5, 0.55)
		body.modulate = Color(1.15, 1.2, 0.85)
		if hp_bar:
			hp_bar.modulate = Color(0.65, 1.0, 0.15)
		return
	body.color = _skin_color()
	body.modulate = Color.WHITE
	if is_flying:
		modulate = Color(1.15, 1.35, 1.1)
	else:
		modulate = Color.WHITE
	if hp_bar:
		match enemy_id:
			"flying":
				hp_bar.modulate = Color(0.4, 1.0, 0.5)
			"splitter":
				hp_bar.modulate = Color(1.0, 0.55, 1.0)
			"boss":
				hp_bar.modulate = Color(1.0, 0.45, 0.85)
			_:
				hp_bar.modulate = Color.WHITE


func _flash() -> void:
	if body == null:
		return
	body.modulate = Color(1.6, 1.6, 1.6)
	var tween := create_tween()
	tween.tween_interval(0.08)
	tween.tween_callback(_refresh_status_visual)
