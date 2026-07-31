extends RefCounted
class_name TowerCatalog


static func all_ids() -> PackedStringArray:
	return PackedStringArray(["basic", "splash", "slow", "poison", "sniper", "antiair"])


static func by_id(id: String) -> Dictionary:
	var d := _raw(id)
	d["name"] = UiText.t(str(d["name_key"]))
	d["desc"] = UiText.t(str(d["desc_key"]))
	return d


static func _raw(id: String) -> Dictionary:
	match id:
		"basic":
			return {
				"id": "basic",
				"name_key": "t_basic",
				"desc_key": "t_basic_d",
				"cost": 15,
				"color": Color(0.45, 0.75, 0.5),
				"range": 155.0,
				"fire_interval": 0.55,
				"damage": 8.0,
				"max_level": 5,
				"upgrade_costs": [20, 35, 55, 80],
				"can_target_flying": false,
				"only_flying": false,
				"armor_pierce": 0.0,
				"splash_radius": 0.0,
				"splash_ratio": 0.0,
				"slow_factor": 0.0,
				"slow_duration": 0.0,
				"poison_dps": 0.0,
				"poison_duration": 0.0,
				"crit_chance": 0.05,
				"crit_mult": 1.5,
				"vs_flying": 0.0,
				"vs_ground": 1.0,
				"hit_sfx": "res://assets/sfx/hit_basic.wav",
				"bullet_color": Color(1.0, 0.92, 0.4),
				"level_bonus": {"damage": 3.5, "range": 8.0, "fire_interval": -0.04},
			}
		"splash":
			return {
				"id": "splash",
				"name_key": "t_splash",
				"desc_key": "t_splash_d",
				"cost": 55,
				"color": Color(0.95, 0.55, 0.25),
				"range": 160.0,
				"fire_interval": 0.85,
				"damage": 12.0,
				"max_level": 5,
				"upgrade_costs": [40, 70, 100, 140],
				"can_target_flying": false,
				"only_flying": false,
				"armor_pierce": 2.0,
				"splash_radius": 58.0,
				"splash_ratio": 0.65,
				"slow_factor": 0.0,
				"slow_duration": 0.0,
				"poison_dps": 0.0,
				"poison_duration": 0.0,
				"crit_chance": 0.0,
				"crit_mult": 1.0,
				"vs_flying": 0.0,
				"vs_ground": 1.0,
				"hit_sfx": "res://assets/sfx/hit_splash.wav",
				"bullet_color": Color(1.0, 0.45, 0.2),
				"level_bonus": {"damage": 5.0, "range": 10.0, "splash_radius": 8.0, "fire_interval": -0.05, "armor_pierce": 1.0},
			}
		"slow":
			return {
				"id": "slow",
				"name_key": "t_slow",
				"desc_key": "t_slow_d",
				"cost": 40,
				"color": Color(0.35, 0.7, 0.95),
				"range": 150.0,
				"fire_interval": 0.7,
				"damage": 4.0,
				"max_level": 5,
				"upgrade_costs": [30, 50, 75, 110],
				"can_target_flying": false,
				"only_flying": false,
				"armor_pierce": 0.0,
				"splash_radius": 40.0,
				"splash_ratio": 0.35,
				"slow_factor": 0.45,
				"slow_duration": 2.0,
				"poison_dps": 0.0,
				"poison_duration": 0.0,
				"crit_chance": 0.0,
				"crit_mult": 1.0,
				"vs_flying": 0.0,
				"vs_ground": 1.0,
				"hit_sfx": "res://assets/sfx/hit_slow.wav",
				"bullet_color": Color(0.4, 0.85, 1.0),
				"level_bonus": {"damage": 1.5, "slow_factor": 0.06, "slow_duration": 0.25, "range": 8.0},
			}
		"poison":
			return {
				"id": "poison",
				"name_key": "t_poison",
				"desc_key": "t_poison_d",
				"cost": 48,
				"color": Color(0.45, 0.9, 0.2),
				"range": 145.0,
				"fire_interval": 0.9,
				"damage": 3.0,
				"max_level": 5,
				"upgrade_costs": [35, 55, 85, 120],
				"can_target_flying": true,
				"only_flying": false,
				"armor_pierce": 0.0,
				"splash_radius": 35.0,
				"splash_ratio": 0.45,
				"slow_factor": 0.0,
				"slow_duration": 0.0,
				"poison_dps": 8.0,
				"poison_duration": 3.5,
				"crit_chance": 0.0,
				"crit_mult": 1.0,
				"vs_flying": 1.0,
				"vs_ground": 1.0,
				"hit_sfx": "res://assets/sfx/hit_poison.wav",
				"bullet_color": Color(0.55, 1.0, 0.25),
				"level_bonus": {"poison_dps": 3.0, "poison_duration": 0.4, "damage": 1.0, "splash_radius": 5.0, "range": 8.0},
			}
		"sniper":
			return {
				"id": "sniper",
				"name_key": "t_sniper",
				"desc_key": "t_sniper_d",
				"cost": 75,
				"color": Color(0.75, 0.35, 0.85),
				"range": 240.0,
				"fire_interval": 1.35,
				"damage": 32.0,
				"max_level": 5,
				"upgrade_costs": [55, 90, 130, 180],
				"can_target_flying": true,
				"only_flying": false,
				"armor_pierce": 12.0,
				"splash_radius": 0.0,
				"splash_ratio": 0.0,
				"slow_factor": 0.0,
				"slow_duration": 0.0,
				"poison_dps": 0.0,
				"poison_duration": 0.0,
				"crit_chance": 0.2,
				"crit_mult": 2.0,
				"vs_flying": 1.0,
				"vs_ground": 1.0,
				"hit_sfx": "res://assets/sfx/hit_sniper.wav",
				"bullet_color": Color(0.9, 0.5, 1.0),
				"level_bonus": {"damage": 11.0, "armor_pierce": 3.5, "range": 15.0, "crit_chance": 0.04},
			}
		"antiair":
			return {
				"id": "antiair",
				"name_key": "t_aa",
				"desc_key": "t_aa_d",
				"cost": 50,
				"color": Color(0.95, 0.85, 0.3),
				"range": 200.0,
				"fire_interval": 0.38,
				"damage": 11.0,
				"max_level": 5,
				"upgrade_costs": [35, 60, 90, 130],
				"can_target_flying": true,
				"only_flying": true,
				"armor_pierce": 3.0,
				"splash_radius": 0.0,
				"splash_ratio": 0.0,
				"slow_factor": 0.15,
				"slow_duration": 0.9,
				"poison_dps": 0.0,
				"poison_duration": 0.0,
				"crit_chance": 0.1,
				"crit_mult": 1.6,
				"vs_flying": 1.9,
				"vs_ground": 0.0,
				"hit_sfx": "res://assets/sfx/hit_antiair.wav",
				"bullet_color": Color(1.0, 1.0, 0.55),
				"level_bonus": {"damage": 4.0, "vs_flying": 0.12, "fire_interval": -0.025, "range": 12.0, "armor_pierce": 1.0},
			}
		_:
			return _raw("basic")


static func sell_refund_ratio() -> float:
	return 0.6
