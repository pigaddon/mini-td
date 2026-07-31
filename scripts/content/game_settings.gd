extends Node
## 对局设置（Autoload: Settings）

enum Difficulty { EASY, NORMAL, HARD }

signal difficulty_changed(diff: Difficulty)
signal map_changed(map_id: String)

var difficulty: Difficulty = Difficulty.NORMAL
var current_map_id: String = "cross_field"
var wave_goal: int = 15
var endless_mode: bool = false


func set_difficulty(diff: Difficulty) -> void:
	difficulty = diff
	match diff:
		Difficulty.EASY:
			wave_goal = 12
		Difficulty.NORMAL:
			wave_goal = 15
		Difficulty.HARD:
			wave_goal = 18
	if endless_mode:
		wave_goal = -1
	difficulty_changed.emit(diff)


func set_map(map_id: String) -> void:
	current_map_id = map_id
	map_changed.emit(map_id)


func get_starting_gold() -> int:
	match difficulty:
		Difficulty.EASY:
			return 170
		Difficulty.HARD:
			return 130
		_:
			return 140


func get_starting_lives() -> int:
	match difficulty:
		Difficulty.EASY:
			return 22
		Difficulty.HARD:
			return 12
		_:
			return 16


func get_enemy_hp_mult() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.8
		Difficulty.HARD:
			return 1.25
		_:
			return 1.0


func get_enemy_armor_mult() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.7
		Difficulty.HARD:
			return 1.1
		_:
			return 1.0


func get_max_towers() -> int:
	match difficulty:
		Difficulty.EASY:
			return 55
		Difficulty.HARD:
			return 38
		_:
			return 45


func get_reward_mult() -> float:
	match difficulty:
		Difficulty.EASY:
			return 1.1
		Difficulty.HARD:
			return 0.95
		_:
			return 1.0


func is_final_wave(wave: int) -> bool:
	if endless_mode or wave_goal <= 0:
		return false
	return wave >= wave_goal


func difficulty_label() -> String:
	match difficulty:
		Difficulty.EASY:
			return UiText.t("easy")
		Difficulty.HARD:
			return UiText.t("hard")
		_:
			return UiText.t("normal")
