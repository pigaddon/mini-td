extends Node2D
class_name Tower

signal clicked(tower: Tower)

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

var tower_id: String = "basic"
var level: int = 1
var def: Dictionary = {}
var spent_gold: int = 0
var cell: Vector2i = Vector2i.ZERO

var range_radius: float = 120.0
var fire_interval: float = 0.55
var damage: float = 8.0
var armor_pierce: float = 0.0
var splash_radius: float = 0.0
var splash_ratio: float = 0.0
var slow_factor: float = 0.0
var slow_duration: float = 0.0
var poison_dps: float = 0.0
var poison_duration: float = 0.0
var crit_chance: float = 0.0
var crit_mult: float = 1.5
var vs_flying: float = 1.0
var vs_ground: float = 1.0
var can_target_flying: bool = true
var only_flying: bool = false
var hit_sfx: AudioStream
var sfx_volume_db: float = -2.0
var sfx_pitch_min: float = 0.94
var sfx_pitch_max: float = 1.06
var bullet_color: Color = Color(1, 0.9, 0.35)

var fire_timer: float = 0.0
var placed: bool = false
var is_preview: bool = false
var selected: bool = false

@onready var range_visual: Polygon2D = $RangeVisual
@onready var body: Polygon2D = $Body
@onready var base_poly: Polygon2D = $Base
@onready var muzzle: Marker2D = $Muzzle
@onready var click_area: Area2D = $ClickArea

var icon_poly: Polygon2D
var badge_label: Label
var _muzzle_len: float = 18.0


func _ready() -> void:
	add_to_group("towers")
	_ensure_icon_nodes()
	if click_area:
		click_area.input_event.connect(_on_click_area_input)


func _ensure_icon_nodes() -> void:
	icon_poly = get_node_or_null("Icon") as Polygon2D
	if icon_poly == null:
		icon_poly = Polygon2D.new()
		icon_poly.name = "Icon"
		icon_poly.z_index = 3
		add_child(icon_poly)
	badge_label = get_node_or_null("Badge") as Label
	if badge_label == null:
		badge_label = Label.new()
		badge_label.name = "Badge"
		badge_label.z_index = 4
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_label.position = Vector2(-10, -28)
		badge_label.size = Vector2(20, 16)
		add_child(badge_label)


func configure(id: String, at_cell: Vector2i, cost_paid: int) -> void:
	tower_id = id
	cell = at_cell
	spent_gold = cost_paid
	level = 1
	def = TowerCatalog.by_id(id)
	_recompute_stats()
	_apply_visual()
	_build_range_circle()


func _recompute_stats() -> void:
	def = TowerCatalog.by_id(tower_id)
	range_radius = float(def["range"])
	fire_interval = float(def["fire_interval"])
	damage = float(def["damage"])
	armor_pierce = float(def["armor_pierce"])
	splash_radius = float(def["splash_radius"])
	splash_ratio = float(def["splash_ratio"])
	slow_factor = float(def["slow_factor"])
	slow_duration = float(def["slow_duration"])
	poison_dps = float(def["poison_dps"])
	poison_duration = float(def["poison_duration"])
	crit_chance = float(def["crit_chance"])
	crit_mult = float(def["crit_mult"])
	vs_flying = float(def["vs_flying"])
	vs_ground = float(def["vs_ground"])
	can_target_flying = bool(def["can_target_flying"])
	only_flying = bool(def.get("only_flying", false))
	bullet_color = def["bullet_color"]
	var sfx_path := str(def.get("hit_sfx", ""))
	hit_sfx = load(sfx_path) if sfx_path != "" else null
	match tower_id:
		"basic":
			sfx_volume_db = -3.0
			sfx_pitch_min = 0.96
			sfx_pitch_max = 1.08
		"splash":
			sfx_volume_db = -1.0
			sfx_pitch_min = 0.88
			sfx_pitch_max = 1.02
		"slow":
			sfx_volume_db = -4.0
			sfx_pitch_min = 0.92
			sfx_pitch_max = 1.05
		"poison":
			sfx_volume_db = -3.0
			sfx_pitch_min = 0.9
			sfx_pitch_max = 1.08
		"sniper":
			sfx_volume_db = 0.0
			sfx_pitch_min = 0.9
			sfx_pitch_max = 1.0
		"antiair":
			sfx_volume_db = -2.5
			sfx_pitch_min = 1.0
			sfx_pitch_max = 1.15
		_:
			sfx_volume_db = -2.0
			sfx_pitch_min = 0.94
			sfx_pitch_max = 1.06

	var bonus: Dictionary = def.get("level_bonus", {})
	var steps := level - 1
	if steps > 0:
		damage += float(bonus.get("damage", 0.0)) * steps
		range_radius += float(bonus.get("range", 0.0)) * steps
		fire_interval = maxf(0.15, fire_interval + float(bonus.get("fire_interval", 0.0)) * steps)
		armor_pierce += float(bonus.get("armor_pierce", 0.0)) * steps
		splash_radius += float(bonus.get("splash_radius", 0.0)) * steps
		slow_factor = minf(0.85, slow_factor + float(bonus.get("slow_factor", 0.0)) * steps)
		slow_duration += float(bonus.get("slow_duration", 0.0)) * steps
		poison_dps += float(bonus.get("poison_dps", 0.0)) * steps
		poison_duration += float(bonus.get("poison_duration", 0.0)) * steps
		crit_chance = minf(0.75, crit_chance + float(bonus.get("crit_chance", 0.0)) * steps)
		vs_flying += float(bonus.get("vs_flying", 0.0)) * steps


func _apply_visual() -> void:
	_ensure_icon_nodes()
	var c: Color = def["color"]
	# Solid square base so the tower is always visible.
	base_poly.polygon = PackedVector2Array([
		Vector2(-15, -15), Vector2(15, -15), Vector2(15, 15), Vector2(-15, 15)
	])
	base_poly.color = c.darkened(0.45)
	body.color = c.lightened(0.12)
	icon_poly.color = Color(c.r * 0.35 + 0.65, c.g * 0.35 + 0.65, c.b * 0.35 + 0.65, 1.0)
	_apply_tower_shape()
	var lv_scale := 1.0 + 0.08 * float(level - 1)
	base_poly.scale = Vector2(lv_scale, lv_scale)
	body.scale = Vector2(lv_scale, lv_scale)
	icon_poly.scale = Vector2(lv_scale, lv_scale)
	badge_label.add_theme_font_size_override("font_size", 12)
	badge_label.add_theme_color_override("font_color", Color(1, 1, 1))
	badge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	badge_label.add_theme_constant_override("outline_size", 4)


func _apply_tower_shape() -> void:
	# Base fixed; body aims; icon+badge stay readable.
	# Convex polygons only so Polygon2D always draws.
	match tower_id:
		"basic":
			body.polygon = PackedVector2Array([
				Vector2(-7, -9), Vector2(18, 0), Vector2(-7, 9)
			])
			icon_poly.polygon = PackedVector2Array([
				Vector2(-5, 4), Vector2(0, -6), Vector2(5, 4)
			])
			badge_label.text = "弹"
			_muzzle_len = 18.0
		"splash":
			body.polygon = PackedVector2Array([
				Vector2(-8, -12), Vector2(14, -7), Vector2(14, 7), Vector2(-8, 12)
			])
			icon_poly.polygon = PackedVector2Array([
				Vector2(-7, 0), Vector2(-2, -6), Vector2(7, -3), Vector2(7, 3), Vector2(-2, 6)
			])
			badge_label.text = "溅"
			_muzzle_len = 14.0
		"slow":
			body.polygon = PackedVector2Array([
				Vector2(-6, -8), Vector2(16, -3), Vector2(16, 3), Vector2(-6, 8)
			])
			icon_poly.polygon = PackedVector2Array([
				Vector2(0, -7), Vector2(5, 0), Vector2(0, 7), Vector2(-5, 0)
			])
			badge_label.text = "缓"
			_muzzle_len = 16.0
		"poison":
			body.polygon = PackedVector2Array([
				Vector2(-7, -8), Vector2(15, -4), Vector2(15, 4), Vector2(-7, 8)
			])
			icon_poly.polygon = PackedVector2Array([
				Vector2(0, -7), Vector2(5, -1), Vector2(3, 6), Vector2(-3, 6), Vector2(-5, -1)
			])
			badge_label.text = "毒"
			_muzzle_len = 15.0
		"sniper":
			body.polygon = PackedVector2Array([
				Vector2(-8, -4), Vector2(22, -2), Vector2(22, 2), Vector2(-8, 4)
			])
			icon_poly.polygon = PackedVector2Array([
				Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
			])
			badge_label.text = "狙"
			_muzzle_len = 22.0
		"antiair":
			body.polygon = PackedVector2Array([
				Vector2(-7, -10), Vector2(16, -5), Vector2(16, 5), Vector2(-7, 10)
			])
			icon_poly.polygon = PackedVector2Array([
				Vector2(0, -8), Vector2(7, 5), Vector2(0, 2), Vector2(-7, 5)
			])
			badge_label.text = "空"
			_muzzle_len = 16.0
		_:
			body.polygon = PackedVector2Array([
				Vector2(-7, -9), Vector2(18, 0), Vector2(-7, 9)
			])
			icon_poly.polygon = PackedVector2Array([
				Vector2(-5, 4), Vector2(0, -6), Vector2(5, 4)
			])
			badge_label.text = "?"
			_muzzle_len = 18.0


func place() -> void:
	is_preview = false
	placed = true
	_apply_unit_scale()
	modulate = Color.WHITE
	set_selected(false)


func show_preview(valid: bool) -> void:
	is_preview = true
	placed = false
	_apply_unit_scale()
	range_visual.visible = true
	modulate = Color(0.5, 1.0, 0.5, 0.7) if valid else Color(1.0, 0.4, 0.4, 0.7)


func _apply_unit_scale() -> void:
	var s := MapRegistry.unit_scale()
	scale = Vector2(s, s)
	if click_area and click_area.get_child_count() > 0:
		var shape_node := click_area.get_child(0) as CollisionShape2D
		if shape_node and shape_node.shape is CircleShape2D:
			var sh := (shape_node.shape as CircleShape2D).duplicate() as CircleShape2D
			sh.radius = 18.0 * s
			shape_node.shape = sh


func set_selected(on: bool) -> void:
	selected = on
	range_visual.visible = on or is_preview
	if placed and not on:
		range_visual.visible = false
	if not is_preview:
		modulate = Color(1.2, 1.2, 1.0) if on else Color.WHITE


func can_upgrade() -> bool:
	return level < Progress.get_tower_max_level(tower_id)


func upgrade_cost() -> int:
	if not can_upgrade():
		return 0
	var costs: Array = def.get("upgrade_costs", [])
	var idx := level - 1
	if idx >= 0 and idx < costs.size():
		return int(costs[idx])
	# ?????? 6 ??? 4?5 ??? 2 ?
	if costs.is_empty():
		return 0
	return int(round(float(costs[costs.size() - 1]) * 2.0))


func upgrade() -> int:
	if not can_upgrade():
		return 0
	var cost := upgrade_cost()
	level += 1
	spent_gold += cost
	_recompute_stats()
	_apply_visual()
	_build_range_circle()
	return cost


func sell_value() -> int:
	return int(round(spent_gold * TowerCatalog.sell_refund_ratio()))


func info_text() -> String:
	var lines := PackedStringArray()
	var max_lv := Progress.get_tower_max_level(tower_id)
	lines.append(str(def["name"]) + " " + (UiText.t("lv") % [level, max_lv]))
	lines.append(str(def["desc"]))
	lines.append(UiText.t("dmg_line") % [damage, range_radius, fire_interval])
	if only_flying:
		lines.append(UiText.t("target_air_only"))
	elif not can_target_flying:
		lines.append(UiText.t("target_ground_only"))
	else:
		lines.append(UiText.t("target_both"))
	if armor_pierce > 0.0:
		lines.append(UiText.t("pierce") % armor_pierce)
	if splash_radius > 0.0:
		lines.append(UiText.t("splash") % [splash_radius, splash_ratio * 100.0])
	if slow_factor > 0.0:
		lines.append(UiText.t("slow") % [slow_factor * 100.0, slow_duration])
	if poison_dps > 0.0:
		lines.append(UiText.t("poison") % [poison_dps, poison_duration])
	if crit_chance > 0.0:
		lines.append(UiText.t("crit") % [crit_chance * 100.0, crit_mult])
	if absf(vs_flying - 1.0) > 0.01 or absf(vs_ground - 1.0) > 0.01:
		lines.append(UiText.t("vs") % [vs_flying, vs_ground])
	return "\n".join(lines)


func _process(delta: float) -> void:
	if not placed or is_preview:
		return
	fire_timer -= delta
	var target := _find_target()
	if target == null:
		# ??????????????????????????????????
		fire_timer = minf(fire_timer, 0.0)
		if not selected:
			modulate = Color(0.75, 0.75, 0.8)
		return
	if not selected:
		modulate = Color.WHITE
	var aim := (target.global_position - global_position).angle()
	body.rotation = lerp_angle(body.rotation, aim, 0.4)
	muzzle.position = Vector2(_muzzle_len, 0).rotated(body.rotation)
	if fire_timer <= 0.0:
		_shoot(target)
		fire_timer = fire_interval


func _alive_enemies() -> Array:
	var result: Array = []
	var host := get_tree().get_first_node_in_group("td_enemies")
	if host != null:
		for node in host.get_children():
			var enemy := node as Enemy
			if enemy != null and enemy.alive:
				result.append(enemy)
		return result
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy2 := node as Enemy
		if enemy2 != null and enemy2.alive:
			result.append(enemy2)
	return result


func _can_engage(enemy: Enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy) or not enemy.alive:
		return false
	if only_flying and not enemy.is_flying:
		return false
	if enemy.is_flying and not can_target_flying:
		return false
	if (not enemy.is_flying) and vs_ground <= 0.0:
		return false
	if enemy.is_flying and vs_flying <= 0.0:
		return false
	return global_position.distance_squared_to(enemy.global_position) <= range_radius * range_radius


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_travel := -1.0
	for enemy in _alive_enemies():
		if not _can_engage(enemy):
			continue
		if enemy.traveled > best_travel:
			best_travel = enemy.traveled
			best = enemy
	return best


func _shoot(target: Enemy) -> void:
	if not is_instance_valid(target) or not target.alive:
		return
	# ????????????????????????????????
	_apply_hit(target, 1.0, true)
	if splash_radius > 0.0:
		var origin := target.global_position
		for enemy in _alive_enemies():
			if enemy == target or not enemy.alive:
				continue
			if origin.distance_squared_to(enemy.global_position) <= splash_radius * splash_radius:
				_apply_hit(enemy, splash_ratio, false)
	if hit_sfx:
		SFX.play_varied(hit_sfx, sfx_volume_db, sfx_pitch_min, sfx_pitch_max)

	var host := get_tree().get_first_node_in_group("td_bullets")
	if host == null:
		host = get_tree().current_scene
	if host == null:
		return
	var bullet := BULLET_SCENE.instantiate() as Bullet
	host.add_child(bullet)
	var from := global_position + Vector2(18, 0).rotated(body.rotation)
	bullet.setup_visual(from, target, bullet_color)


func _apply_hit(enemy: Enemy, ratio: float, is_direct: bool) -> void:
	if enemy == null or not is_instance_valid(enemy) or not enemy.alive:
		return
	var dmg := damage * ratio
	if randf() < crit_chance:
		dmg *= crit_mult
	if enemy.is_flying:
		dmg *= vs_flying
	else:
		dmg *= vs_ground
	if dmg <= 0.0:
		return
	if not is_direct:
		dmg *= (1.0 - enemy.resist_splash)
	enemy.take_damage(dmg, armor_pierce)
	if slow_factor > 0.0 and slow_duration > 0.0:
		enemy.apply_slow(slow_factor * (1.0 - enemy.resist_slow), slow_duration)
	if poison_dps > 0.0 and poison_duration > 0.0:
		enemy.apply_poison(poison_dps * ratio, poison_duration)


func _build_range_circle() -> void:
	var points := PackedVector2Array()
	var steps := 48
	for i in steps:
		var a := TAU * float(i) / float(steps)
		points.append(Vector2(cos(a), sin(a)) * range_radius)
	range_visual.polygon = points
	range_visual.color = Color(0.3, 0.8, 0.4, 0.15)


func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not placed or is_preview:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		get_viewport().set_input_as_handled()
