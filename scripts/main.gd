extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const TOWER_SCENE := preload("res://scenes/tower.tscn")

var grid: TdGrid = TdGrid.new()
var gold: int = 0
var lives: int = 0
var wave: int = 0
var enemies_alive: int = 0
var spawning: bool = false
var game_over: bool = false
var match_started: bool = false

var selected_tower_id: String = "basic"
var selected_map_id: String = "cross_field"
var preview_tower: Tower
var selected_tower: Tower
var ground_path: PackedVector2Array = PackedVector2Array()
var air_path: PackedVector2Array = PackedVector2Array()

var wave_timer: float = 0.0
var wave_timer_max: float = 10.0
var awaiting_next_wave: bool = false
var speed_index: int = 0
var speed_steps: Array[float] = [1.0, 2.0, 3.0]

@onready var towers: Node2D = $Towers
@onready var enemies: Node2D = $Enemies
@onready var path_line: Line2D = $PathVisual
@onready var grid_draw: Node2D = $GridDraw
@onready var spawn_marker: Polygon2D = $SpawnMarker
@onready var base_flag: Polygon2D = $BaseFlag
@onready var base_pole: Polygon2D = $BasePole

@onready var hud: CanvasLayer = $HUD
@onready var hud_gold: Label = $HUD/TopBar/GoldLabel
@onready var hud_lives: Label = $HUD/TopBar/LivesLabel
@onready var hud_wave: Label = $HUD/TopBar/WaveLabel
@onready var hud_towers: Label = $HUD/TopBar/TowersLabel
@onready var hud_hint: Label = $HUD/HintLabel
@onready var hud_preview: Label = $HUD/WavePreviewLabel
@onready var hud_timer: Label = $HUD/TimerLabel
@onready var start_button: Button = $HUD/StartWaveButton
@onready var pause_button: Button = $HUD/PauseButton
@onready var speed_button: Button = $HUD/SpeedButton
@onready var overlay: ColorRect = $HUD/Overlay
@onready var overlay_label: Label = $HUD/Overlay/Message
@onready var tower_bar: HBoxContainer = $HUD/TowerBar
@onready var info_panel: PanelContainer = $HUD/InfoPanel
@onready var info_label: Label = $HUD/InfoPanel/Margin/VBox/InfoLabel
@onready var upgrade_button: Button = $HUD/InfoPanel/Margin/VBox/UpgradeButton
@onready var tech_button: Button = $HUD/InfoPanel/Margin/VBox/TechButton
@onready var sell_button: Button = $HUD/InfoPanel/Margin/VBox/SellButton
@onready var difficulty_panel: PanelContainer = $HUD/DifficultyPanel


func _ready() -> void:
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	info_panel.visible = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	selected_map_id = Settings.current_map_id
	add_to_group("td_main")
	enemies.add_to_group("td_enemies")
	if not has_node("Bullets"):
		var bullets := Node2D.new()
		bullets.name = "Bullets"
		add_child(bullets)
		bullets.add_to_group("td_bullets")
	else:
		$Bullets.add_to_group("td_bullets")

	start_button.pressed.connect(_on_start_wave_pressed)
	pause_button.pressed.connect(_toggle_pause)
	speed_button.pressed.connect(_cycle_speed)
	upgrade_button.pressed.connect(_upgrade_selected)
	tech_button.pressed.connect(_buy_max_level_tech)
	sell_button.pressed.connect(_sell_selected)
	_apply_mobile_layout()
	_build_start_ui()
	_build_tower_buttons()
	_show_start_select()


func _apply_mobile_layout() -> void:
	if not MapRegistry.is_mobile():
		return
	$Background.polygon = PackedVector2Array([0, 0, 1280, 0, 1280, 720, 0, 720])
	path_line.width = 18.0

	hud_gold.add_theme_font_size_override("font_size", 32)
	hud_lives.add_theme_font_size_override("font_size", 32)
	hud_wave.add_theme_font_size_override("font_size", 32)
	hud_towers.add_theme_font_size_override("font_size", 32)
	hud_preview.add_theme_font_size_override("font_size", 24)
	hud_timer.add_theme_font_size_override("font_size", 24)
	hud_hint.add_theme_font_size_override("font_size", 26)
	info_label.add_theme_font_size_override("font_size", 24)
	overlay_label.add_theme_font_size_override("font_size", 40)

	$HUD/TopBar.offset_bottom = 64.0
	$HUD/TopBar.add_theme_constant_override("separation", 28)
	hud_preview.offset_top = 66.0
	hud_preview.offset_bottom = 100.0
	hud_timer.offset_top = 100.0
	hud_timer.offset_bottom = 132.0

	start_button.offset_left = -320.0
	start_button.offset_top = 10.0
	start_button.offset_right = -14.0
	start_button.offset_bottom = 68.0
	start_button.add_theme_font_size_override("font_size", 26)

	pause_button.offset_left = -320.0
	pause_button.offset_top = 74.0
	pause_button.offset_right = -170.0
	pause_button.offset_bottom = 132.0
	pause_button.add_theme_font_size_override("font_size", 24)

	speed_button.offset_left = -164.0
	speed_button.offset_top = 74.0
	speed_button.offset_right = -14.0
	speed_button.offset_bottom = 132.0
	speed_button.add_theme_font_size_override("font_size", 24)

	tower_bar.offset_left = -520.0
	tower_bar.offset_right = 520.0
	tower_bar.offset_top = -210.0
	tower_bar.offset_bottom = -100.0
	tower_bar.add_theme_constant_override("separation", 14)

	hud_hint.offset_top = -92.0
	hud_hint.offset_bottom = -48.0
	hud_hint.offset_left = -560.0
	hud_hint.offset_right = 560.0

	info_panel.offset_left = -400.0
	info_panel.offset_top = 140.0
	info_panel.offset_right = -12.0
	info_panel.offset_bottom = 470.0
	upgrade_button.custom_minimum_size = Vector2(0, 64)
	tech_button.custom_minimum_size = Vector2(0, 64)
	sell_button.custom_minimum_size = Vector2(0, 64)
	upgrade_button.add_theme_font_size_override("font_size", 26)
	tech_button.add_theme_font_size_override("font_size", 26)
	sell_button.add_theme_font_size_override("font_size", 26)

	difficulty_panel.offset_left = -520.0
	difficulty_panel.offset_top = -300.0
	difficulty_panel.offset_right = 520.0
	difficulty_panel.offset_bottom = 300.0
	var title := difficulty_panel.get_node("Margin/VBox/Title") as Label
	if title:
		title.add_theme_font_size_override("font_size", 34)

	overlay_label.offset_left = -460.0
	overlay_label.offset_right = 460.0
	overlay_label.offset_top = -110.0
	overlay_label.offset_bottom = 110.0


func _style_box(bg: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(10)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	if border.a > 0.01:
		s.set_border_width_all(3)
		s.border_color = border
	return s


func _apply_choice_button_style(btn: Button, selected: bool) -> void:
	# ??????????????????
	var normal := _style_box(Color(0.18, 0.22, 0.28))
	var hover := _style_box(Color(0.28, 0.34, 0.42))
	var selected_bg := _style_box(Color(1.0, 0.55, 0.08), Color(1.0, 0.92, 0.35))
	var selected_hover := _style_box(Color(1.0, 0.65, 0.15), Color(1.0, 0.95, 0.45))
	if selected:
		btn.add_theme_stylebox_override("normal", selected_bg)
		btn.add_theme_stylebox_override("hover", selected_hover)
		btn.add_theme_stylebox_override("pressed", selected_bg)
		btn.add_theme_stylebox_override("focus", selected_bg)
		btn.add_theme_color_override("font_color", Color(0.1, 0.08, 0.05))
		btn.add_theme_color_override("font_hover_color", Color(0.08, 0.06, 0.02))
		btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.06, 0.02))
	else:
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", selected_bg)
		btn.add_theme_stylebox_override("focus", hover)
		btn.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.08, 0.05))


func _refresh_choice_row(row: Node, selected_btn: Button) -> void:
	for c in row.get_children():
		if c is Button:
			var b := c as Button
			b.button_pressed = (b == selected_btn)
			_apply_choice_button_style(b, b.button_pressed)


func _process(delta: float) -> void:
	if game_over or not match_started or get_tree().paused:
		return
	_update_preview()
	if awaiting_next_wave and not spawning:
		wave_timer -= delta
		hud_timer.text = ("%s: %.1fs (%s)" % [UiText.t("timer"), maxf(0.0, wave_timer), UiText.t("early_hint")])
		if wave_timer <= 0.0:
			_begin_wave(false)


func _unhandled_input(event: InputEvent) -> void:
	if not match_started:
		return
	if game_over:
		if event.is_action_pressed("start_wave") or (event is InputEventMouseButton and event.pressed):
			_restart()
		return

	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		return
	if event.is_action_pressed("speed_game"):
		_cycle_speed()
		return
	if event.is_action_pressed("start_wave"):
		_on_start_wave_pressed()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_clear_tower_selection()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			var pos := get_global_mouse_position()
			var pick_r := 48.0 if MapRegistry.is_mobile() else 22.0
			if selected_tower != null and selected_tower.global_position.distance_to(pos) < pick_r:
				return
			_clear_tower_selection()
			_try_place_tower(pos)


func start_match() -> void:
	difficulty_panel.visible = false
	match_started = true
	game_over = false
	wave = 0
	enemies_alive = 0
	spawning = false
	awaiting_next_wave = true
	wave_timer = 3.0
	gold = Settings.get_starting_gold()
	lives = Settings.get_starting_lives()
	Progress.reset_match_tech()
	Settings.set_map(selected_map_id)
	_load_map(Settings.current_map_id)
	_refresh_paths()
	_spawn_preview()
	_update_hud()
	hud_hint.text = UiText.t("hint_controls")
	hud_preview.text = "%s: %s" % [UiText.t("next_preview"), EnemyCatalog.preview_text(1)]
	hud_timer.text = "%s: %s" % [UiText.t("map"), MapRegistry.get_map_name(selected_map_id)]


func _load_map(map_id: String) -> void:
	var data: Dictionary = MapRegistry.get_map(map_id)
	grid.setup_from_map(data)
	spawn_marker.position = grid.cell_to_world_center(grid.spawn)
	base_flag.position = grid.cell_to_world_center(grid.exit) + Vector2(8, -8)
	base_pole.position = grid.cell_to_world_center(grid.exit)
	_draw_grid()
	for c in towers.get_children():
		c.queue_free()
	for c in enemies.get_children():
		c.queue_free()
	if has_node("Bullets"):
		for c in $Bullets.get_children():
			c.queue_free()


func _draw_grid() -> void:
	for c in grid_draw.get_children():
		c.queue_free()
	var rect: Rect2 = grid.rect_world()
	var bg := Polygon2D.new()
	bg.z_index = -18
	bg.color = Color(0.16, 0.22, 0.18, 1)
	bg.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	grid_draw.add_child(bg)
	for x in grid.cols + 1:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color(1, 1, 1, 0.06)
		line.z_index = -17
		var px: float = grid.origin.x + x * grid.cell_size
		line.add_point(Vector2(px, grid.origin.y))
		line.add_point(Vector2(px, grid.origin.y + grid.rows * grid.cell_size))
		grid_draw.add_child(line)
	for y in grid.rows + 1:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color(1, 1, 1, 0.06)
		line.z_index = -17
		var py: float = grid.origin.y + y * grid.cell_size
		line.add_point(Vector2(grid.origin.x, py))
		line.add_point(Vector2(grid.origin.x + grid.cols * grid.cell_size, py))
		grid_draw.add_child(line)
	# Terrain walls (not towers)
	for x in grid.cols:
		for y in grid.rows:
			if not grid.is_terrain(Vector2i(x, y)):
				continue
			var wall := Polygon2D.new()
			wall.z_index = -16
			wall.color = Color(0.12, 0.14, 0.16, 0.92)
			var p := grid.origin + Vector2(x * grid.cell_size, y * grid.cell_size)
			var s := grid.cell_size
			var pad := 2.0
			wall.polygon = PackedVector2Array([
				p + Vector2(pad, pad),
				p + Vector2(s - pad, pad),
				p + Vector2(s - pad, s - pad),
				p + Vector2(pad, s - pad),
			])
			grid_draw.add_child(wall)


func _refresh_paths() -> void:
	ground_path = Pathfinder.find_path(grid, false)
	air_path = Pathfinder.find_path(grid, true)
	path_line.clear_points()
	for p in ground_path:
		path_line.add_point(p)
	path_line.width = 10.0
	path_line.default_color = Color(0.55, 0.45, 0.3, 0.55)
	for node in enemies.get_children():
		var e := node as Enemy
		if e:
			e.repath(air_path if e.is_flying else ground_path)


func _spawn_preview() -> void:
	if preview_tower:
		preview_tower.queue_free()
	preview_tower = TOWER_SCENE.instantiate() as Tower
	add_child(preview_tower)
	preview_tower.z_index = 20
	preview_tower.configure(selected_tower_id, Vector2i.ZERO, 0)
	preview_tower.show_preview(false)


func _update_preview() -> void:
	if preview_tower == null:
		return
	var cell: Vector2i = grid.world_to_cell(get_global_mouse_position())
	preview_tower.global_position = grid.cell_to_world_center(cell)
	var cost: int = int(TowerCatalog.by_id(selected_tower_id)["cost"])
	var valid: bool = _can_place_at(cell) and gold >= cost and towers.get_child_count() < Settings.get_max_towers()
	preview_tower.show_preview(valid)


func _try_place_tower(pos: Vector2) -> void:
	if not Progress.is_tower_unlocked(selected_tower_id):
		hud_hint.text = UiText.t("locked")
		return
	var cell: Vector2i = grid.world_to_cell(pos)
	var cost: int = int(TowerCatalog.by_id(selected_tower_id)["cost"])
	if gold < cost:
		hud_hint.text = UiText.t("no_gold") % cost
		return
	if towers.get_child_count() >= Settings.get_max_towers():
		hud_hint.text = UiText.t("tower_cap") % Settings.get_max_towers()
		return
	if not _can_place_at(cell):
		hud_hint.text = UiText.t("bad_cell")
		return

	gold -= cost
	grid.set_blocked(cell, true)
	var tower := TOWER_SCENE.instantiate() as Tower
	towers.add_child(tower)
	tower.global_position = grid.cell_to_world_center(cell)
	tower.configure(selected_tower_id, cell, cost)
	tower.place()
	tower.clicked.connect(_on_tower_clicked)
	_refresh_paths()
	hud_hint.text = UiText.t("placed") % [TowerCatalog.by_id(selected_tower_id)["name"], cost]
	_update_hud()


func _can_place_at(cell: Vector2i) -> bool:
	if not grid.is_buildable_cell(cell):
		return false
	grid.set_blocked(cell, true)
	var ok: bool = Pathfinder.has_path(grid)
	grid.set_blocked(cell, false)
	return ok


func _on_tower_clicked(tower: Tower) -> void:
	if selected_tower and selected_tower != tower:
		selected_tower.set_selected(false)
	selected_tower = tower
	tower.set_selected(true)
	info_panel.visible = true
	_refresh_info_panel()


func _clear_tower_selection() -> void:
	if selected_tower:
		selected_tower.set_selected(false)
	selected_tower = null
	info_panel.visible = false


func _refresh_info_panel() -> void:
	if selected_tower == null:
		return
	info_label.text = selected_tower.info_text()
	if selected_tower.can_upgrade():
		upgrade_button.disabled = gold < selected_tower.upgrade_cost()
		upgrade_button.text = UiText.t("upgrade") % selected_tower.upgrade_cost()
	else:
		upgrade_button.disabled = true
		upgrade_button.text = UiText.t("max_lv")
	var tid := selected_tower.tower_id
	if Progress.has_max_level_tech(tid):
		tech_button.disabled = true
		tech_button.text = UiText.t("tech_done")
	else:
		var tech_cost := Progress.max_level_tech_cost(tid)
		tech_button.disabled = gold < tech_cost
		tech_button.text = UiText.t("tech") % tech_cost
	sell_button.text = UiText.t("sell") % selected_tower.sell_value()


func _upgrade_selected() -> void:
	if selected_tower == null or not selected_tower.can_upgrade():
		return
	var cost: int = selected_tower.upgrade_cost()
	if gold < cost:
		return
	gold -= cost
	selected_tower.upgrade()
	hud_hint.text = UiText.t("upgraded")
	_refresh_info_panel()
	_update_hud()


func _buy_max_level_tech() -> void:
	if selected_tower == null:
		return
	var tid := selected_tower.tower_id
	if Progress.has_max_level_tech(tid):
		return
	var cost := Progress.max_level_tech_cost(tid)
	if gold < cost:
		return
	gold -= cost
	Progress.unlock_max_level_tech(tid)
	hud_hint.text = UiText.t("tech_ok")
	_refresh_info_panel()
	_update_hud()


func _sell_selected() -> void:
	if selected_tower == null:
		return
	var refund: int = selected_tower.sell_value()
	gold += refund
	grid.set_blocked(selected_tower.cell, false)
	selected_tower.queue_free()
	selected_tower = null
	info_panel.visible = false
	_refresh_paths()
	hud_hint.text = UiText.t("sold") % refund
	_update_hud()


func _on_start_wave_pressed() -> void:
	if game_over or not match_started:
		return
	if spawning:
		return
	if not awaiting_next_wave and wave > 0:
		return
	if Settings.is_final_wave(wave) and wave > 0:
		return
	_begin_wave(true)


func _begin_wave(manual: bool) -> void:
	if game_over or spawning:
		return
	var early_bonus := 0
	if awaiting_next_wave and manual and wave_timer > 0.0 and wave > 0:
		early_bonus = int(ceil(wave_timer * 2.0))
		gold += early_bonus
	awaiting_next_wave = false
	wave += 1
	if early_bonus > 0:
		hud_hint.text = UiText.t("early_wave") % [early_bonus, wave]
	else:
		hud_hint.text = UiText.t("wave_in") % wave
	_update_hud()
	hud_preview.text = "%s: %s" % [UiText.t("now_wave"), EnemyCatalog.preview_text(wave)]
	_spawn_wave(wave)


func _spawn_wave(wave_num: int) -> void:
	spawning = true
	var plan: Array = EnemyCatalog.build_wave(wave_num)
	var hp_mult := EnemyCatalog.wave_hp_mult(wave_num) * Settings.get_enemy_hp_mult()
	var armor_bonus := EnemyCatalog.wave_armor_bonus(wave_num) * Settings.get_enemy_armor_mult()
	var speed_mult := EnemyCatalog.wave_speed_mult(wave_num)
	var reward_mult := (1.0 + wave_num * 0.02) * Settings.get_reward_mult()
	var interval := maxf(0.18, 0.62 - wave_num * 0.028)

	for item in plan:
		var id := str(item["id"])
		var count := int(item["count"])
		for i in count:
			if game_over:
				break
			_spawn_enemy(id, hp_mult, reward_mult, armor_bonus, speed_mult)
			await get_tree().create_timer(interval).timeout
	spawning = false
	if not game_over and not Settings.is_final_wave(wave):
		awaiting_next_wave = true
		wave_timer = maxf(6.0, wave_timer_max - wave_num * 0.15)
		hud_preview.text = "%s: %s" % [UiText.t("next_preview"), EnemyCatalog.preview_text(wave + 1)]
		hud_hint.text = UiText.t("can_early")
	_check_wave_clear()


func _spawn_enemy(
	id: String,
	hp_mult: float,
	reward_mult: float,
	armor_bonus: float,
	speed_mult: float
) -> void:
	var def: Dictionary = EnemyCatalog.by_id(id)
	var points := air_path if bool(def["flying"]) else ground_path
	if points.is_empty():
		_refresh_paths()
		points = air_path if bool(def["flying"]) else ground_path
	if points.is_empty():
		return
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemies.add_child(enemy)
	var extra_armor := armor_bonus
	if id == "armored":
		extra_armor += armor_bonus * 0.5
	elif id == "boss":
		extra_armor += armor_bonus * 0.8
	elif id == "splitter":
		extra_armor = 0.0
	enemy.setup(def, points, hp_mult, reward_mult, extra_armor, speed_mult)
	if enemy.armor >= 8.0:
		enemy.reward += 3 + int(enemy.armor / 6.0)
	if id == "boss":
		enemy.reward += 12 + wave * 2
	enemies_alive += 1
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy.will_split.connect(_on_enemy_will_split)


func _on_enemy_will_split(parent: Enemy) -> void:
	if game_over or parent == null:
		return
	for slot in 2:
		var child := ENEMY_SCENE.instantiate() as Enemy
		enemies.add_child(child)
		child.setup_as_split_child(parent, slot)
		enemies_alive += 1
		child.died.connect(_on_enemy_died)
		child.reached_end.connect(_on_enemy_reached_end)
		child.will_split.connect(_on_enemy_will_split)


func _on_enemy_died(_enemy: Enemy, reward: int) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	gold += reward
	_update_hud()
	if selected_tower:
		_refresh_info_panel()
	_check_wave_clear()


func _on_enemy_reached_end(enemy: Enemy) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	lives -= enemy.damage_to_base
	_update_hud()
	if lives <= 0:
		_end_game(false)
	else:
		_check_wave_clear()


func _check_wave_clear() -> void:
	if game_over or spawning:
		return
	if enemies_alive > 0:
		return
	gold += 10 + wave * 3
	_update_hud()
	if Settings.is_final_wave(wave):
		_end_game(true)
		return
	if not awaiting_next_wave:
		awaiting_next_wave = true
		wave_timer = maxf(6.0, wave_timer_max - wave * 0.15)
		hud_preview.text = "%s: %s" % [UiText.t("next_preview"), EnemyCatalog.preview_text(wave + 1)]
	hud_hint.text = UiText.t("cleared")


func _end_game(won: bool) -> void:
	game_over = true
	awaiting_next_wave = false
	overlay.visible = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	if preview_tower:
		preview_tower.visible = false
	var goal := Settings.wave_goal
	if won:
		overlay_label.text = UiText.t("win") % [
			wave, Settings.difficulty_label(), MapRegistry.get_map_name(selected_map_id)
		]
	else:
		overlay_label.text = UiText.t("lose") % [
			wave, str(goal) if goal > 0 else UiText.t("inf")
		]


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func _toggle_pause() -> void:
	if game_over or not match_started:
		return
	get_tree().paused = not get_tree().paused
	pause_button.text = UiText.t("resume") if get_tree().paused else UiText.t("pause")
	hud_hint.text = UiText.t("paused") if get_tree().paused else UiText.t("running")


func _cycle_speed() -> void:
	if game_over or not match_started:
		return
	speed_index = (speed_index + 1) % speed_steps.size()
	Engine.time_scale = speed_steps[speed_index]
	speed_button.text = UiText.t("speed") % speed_steps[speed_index]


func _update_hud() -> void:
	hud_gold.text = UiText.t("gold_fmt") % gold
	hud_lives.text = UiText.t("lives_fmt") % lives
	var goal := Settings.wave_goal
	hud_wave.text = UiText.t("wave_fmt") % [wave, str(goal) if goal > 0 else UiText.t("inf")]
	hud_towers.text = UiText.t("towers_fmt") % [towers.get_child_count(), Settings.get_max_towers()]
	start_button.text = UiText.t("start_btn")
	if selected_tower:
		_refresh_info_panel()


func _tower_mark(id: String) -> String:
	match id:
		"basic":
			return "?"
		"splash":
			return "?"
		"slow":
			return "?"
		"poison":
			return "?"
		"sniper":
			return "?"
		"antiair":
			return "?"
		_:
			return "?"


func _make_tower_icon_tex(id: String, color: Color) -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.09, 0.1, 0.85))
	for y in range(6, 26):
		for x in range(6, 26):
			img.set_pixel(x, y, color.darkened(0.35))
	match id:
		"basic":
			for y in range(10, 22):
				var half: int
				if y < 16:
					half = int((y - 10) * 0.6)
				else:
					half = int((22 - y) * 0.6)
				for x in range(12 - half, 22):
					img.set_pixel(clampi(x, 0, 31), y, color)
		"splash":
			for y in range(9, 23):
				for x in range(9, 20):
					img.set_pixel(x, y, color)
			for y in range(12, 20):
				for x in range(18, 27):
					img.set_pixel(x, y, color.lightened(0.15))
		"slow":
			for y in range(8, 24):
				var d: int = 8 - absi(y - 16)
				for x in range(16 - d, 16 + d + 1):
					img.set_pixel(clampi(x, 0, 31), y, color)
		"poison":
			for y in range(8, 14):
				var w: int = y - 7
				for x in range(16 - w, 16 + w + 1):
					img.set_pixel(clampi(x, 0, 31), y, color)
			for y in range(14, 24):
				for x in range(11, 22):
					var dx: int = x - 16
					var dy: int = y - 18
					if dx * dx + dy * dy <= 36:
						img.set_pixel(x, y, color)
		"sniper":
			for y in range(14, 18):
				for x in range(8, 28):
					img.set_pixel(x, y, color)
			for y in range(10, 22):
				for x in range(10, 14):
					img.set_pixel(x, y, color.darkened(0.1))
		"antiair":
			for i in range(10):
				img.set_pixel(16 - i, 10 + i, color)
				img.set_pixel(16 - i + 1, 10 + i, color)
				img.set_pixel(16 + i, 10 + i, color)
				img.set_pixel(16 + i - 1, 10 + i, color)
			for y in range(20, 24):
				for x in range(12, 21):
					img.set_pixel(x, y, color)
		_:
			for y in range(10, 22):
				for x in range(10, 22):
					img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


func _build_tower_buttons() -> void:
	for c in tower_bar.get_children():
		c.queue_free()
	for id in TowerCatalog.all_ids():
		if not Progress.is_tower_unlocked(id):
			continue
		var def: Dictionary = TowerCatalog.by_id(id)
		var btn := Button.new()
		btn.text = "%s %s\n%d?" % [_tower_mark(id), def["name"], int(def["cost"])]
		btn.icon = _make_tower_icon_tex(id, def["color"])
		btn.expand_icon = true
		var mobile := MapRegistry.is_mobile()
		if mobile:
			btn.custom_minimum_size = Vector2(168, 96)
			btn.add_theme_font_size_override("font_size", 22)
		else:
			btn.custom_minimum_size = Vector2(110, 52)
			btn.add_theme_font_size_override("font_size", 13)
		btn.toggle_mode = true
		btn.button_pressed = id == selected_tower_id
		_apply_choice_button_style(btn, btn.button_pressed)
		btn.pressed.connect(_on_tower_type_pressed.bind(id, btn))
		tower_bar.add_child(btn)


func _on_tower_type_pressed(id: String, btn: Button) -> void:
	selected_tower_id = id
	_refresh_choice_row(tower_bar, btn)
	_spawn_preview()
	hud_hint.text = "%s - %s" % [TowerCatalog.by_id(id)["name"], TowerCatalog.by_id(id)["desc"]]


func _show_start_select() -> void:
	match_started = false
	difficulty_panel.visible = true
	overlay.visible = false


func _build_start_ui() -> void:
	var box := difficulty_panel.get_node("Margin/VBox") as VBoxContainer
	for c in box.get_children():
		if c.name != "Title":
			c.queue_free()
	var title := box.get_node("Title") as Label
	title.text = UiText.t("title")
	var mobile := MapRegistry.is_mobile()
	var btn_h := 72.0 if mobile else 36.0
	var font_sz := 26 if mobile else 16

	var map_label := Label.new()
	map_label.text = UiText.t("map_line")
	map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_label.add_theme_font_size_override("font_size", font_sz)
	box.add_child(map_label)

	var map_row := GridContainer.new()
	map_row.columns = 3 if mobile else 4
	map_row.add_theme_constant_override("h_separation", 14 if mobile else 8)
	map_row.add_theme_constant_override("v_separation", 10 if mobile else 6)
	box.add_child(map_row)

	for map_id in MapRegistry.all_map_ids():
		var mbtn := Button.new()
		mbtn.toggle_mode = true
		mbtn.text = MapRegistry.get_map_name(map_id)
		mbtn.custom_minimum_size = Vector2(0, btn_h)
		mbtn.add_theme_font_size_override("font_size", font_sz)
		mbtn.button_pressed = map_id == selected_map_id
		_apply_choice_button_style(mbtn, mbtn.button_pressed)
		mbtn.pressed.connect(_on_map_chosen.bind(map_id, mbtn, map_row))
		map_row.add_child(mbtn)

	var diff_label := Label.new()
	diff_label.text = UiText.t("diff")
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", font_sz)
	box.add_child(diff_label)

	var specs := [
		{"diff": 0, "name_key": "easy", "gold": 170, "lives": 22, "towers": 55, "waves": 12},
		{"diff": 1, "name_key": "normal", "gold": 140, "lives": 16, "towers": 45, "waves": 15},
		{"diff": 2, "name_key": "hard", "gold": 130, "lives": 12, "towers": 38, "waves": 18},
	]
	for spec in specs:
		var btn := Button.new()
		btn.text = UiText.t("diff_fmt") % [
			UiText.t(str(spec["name_key"])), spec["gold"], spec["lives"], spec["towers"], spec["waves"]
		]
		btn.custom_minimum_size = Vector2(0, btn_h)
		btn.add_theme_font_size_override("font_size", font_sz)
		_apply_choice_button_style(btn, false)
		btn.pressed.connect(_on_diff_chosen.bind(int(spec["diff"]), btn, box))
		box.add_child(btn)


func _on_map_chosen(map_id: String, btn: Button, row: Node) -> void:
	selected_map_id = map_id
	_refresh_choice_row(row, btn)


func _on_diff_chosen(diff_value: int, btn: Button = null, box: VBoxContainer = null) -> void:
	if btn != null and box != null:
		for c in box.get_children():
			if c is Button and not (c as Button).toggle_mode:
				_apply_choice_button_style(c as Button, c == btn)
	Settings.set_difficulty(diff_value as Settings.Difficulty)
	start_match()
