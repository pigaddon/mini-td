extends Node
## ?????????Autoload: Progress?

signal tower_unlocked(tower_id: String)
signal max_level_tech_unlocked(tower_id: String)

var _unlocked: Dictionary = {}
## ???????????????+1?
var _max_level_tech: Dictionary = {}


func _ready() -> void:
	for id in TowerCatalog.all_ids():
		_unlocked[id] = true


func is_tower_unlocked(tower_id: String) -> bool:
	return bool(_unlocked.get(tower_id, true))


func unlock_tower(tower_id: String) -> void:
	if _unlocked.get(tower_id, false):
		return
	_unlocked[tower_id] = true
	tower_unlocked.emit(tower_id)


func reset_for_debug_lock_all() -> void:
	_unlocked.clear()


func reset_match_tech() -> void:
	_max_level_tech.clear()


func has_max_level_tech(tower_id: String) -> bool:
	return bool(_max_level_tech.get(tower_id, false))


func unlock_max_level_tech(tower_id: String) -> void:
	_max_level_tech[tower_id] = true
	max_level_tech_unlocked.emit(tower_id)


## 4 ????? = upgrade_costs[3]?4?5???? = ? 6 ?
func max_level_tech_cost(tower_id: String) -> int:
	var costs: Array = TowerCatalog.by_id(tower_id).get("upgrade_costs", [])
	if costs.size() < 4:
		return 99999
	return int(costs[3]) * 6


func get_tower_max_level(tower_id: String) -> int:
	var base := int(TowerCatalog.by_id(tower_id).get("max_level", 5))
	if has_max_level_tech(tower_id):
		return base + 1
	return base
