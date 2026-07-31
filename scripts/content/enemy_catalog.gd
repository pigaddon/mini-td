extends RefCounted
class_name EnemyCatalog


static func all_ids() -> PackedStringArray:
	return PackedStringArray(["normal", "fast", "armored", "flying", "swarm", "splitter", "boss"])


static func by_id(id: String) -> Dictionary:
	var d := _raw(id)
	d["name"] = UiText.t(str(d["name_key"]))
	return d


static func _raw(id: String) -> Dictionary:
	match id:
		"normal":
			return {"id": "normal", "name_key": "e_normal", "hp": 45.0, "speed": 85.0, "armor": 1.0, "reward": 8, "damage_to_base": 1, "flying": false, "resist_splash": 0.0, "resist_slow": 0.0, "color": Color(0.85, 0.25, 0.22), "scale": 1.0}
		"fast":
			return {"id": "fast", "name_key": "e_fast", "hp": 30.0, "speed": 155.0, "armor": 0.0, "reward": 7, "damage_to_base": 1, "flying": false, "resist_splash": 0.0, "resist_slow": 0.3, "color": Color(1.0, 0.7, 0.2), "scale": 0.85}
		"armored":
			return {"id": "armored", "name_key": "e_armor", "hp": 85.0, "speed": 60.0, "armor": 14.0, "reward": 14, "damage_to_base": 1, "flying": false, "resist_splash": 0.4, "resist_slow": 0.15, "color": Color(0.45, 0.5, 0.6), "scale": 1.15}
		"flying":
			return {"id": "flying", "name_key": "e_fly", "hp": 42.0, "speed": 120.0, "armor": 3.0, "reward": 12, "damage_to_base": 1, "flying": true, "resist_splash": 0.2, "resist_slow": 0.0, "color": Color(0.15, 1.0, 0.25), "scale": 1.05}
		"swarm":
			return {"id": "swarm", "name_key": "e_swarm", "hp": 18.0, "speed": 105.0, "armor": 0.0, "reward": 4, "damage_to_base": 1, "flying": false, "resist_splash": -0.2, "resist_slow": 0.0, "color": Color(0.95, 0.55, 0.15), "scale": 0.7}
		"splitter":
			# 无甲、中速。本体 80 → 2×40 → 4×20 → 8×10，末级才真正死。
			# 全链总血量 320；略怕溅射；奖金逐级减半。
			return {
				"id": "splitter",
				"name_key": "e_split",
				"hp": 95.0,
				"speed": 88.0,
				"armor": 0.0,
				"reward": 8,
				"damage_to_base": 1,
				"flying": false,
				"resist_splash": -0.15,
				"resist_slow": 0.0,
				"color": Color(0.95, 0.3, 0.85),
				"scale": 1.2,
				"split_tier": 0,
				"split_max_tier": 3,
			}
		"boss":
			return {"id": "boss", "name_key": "e_boss", "hp": 480.0, "speed": 52.0, "armor": 22.0, "reward": 55, "damage_to_base": 6, "flying": false, "resist_splash": 0.25, "resist_slow": 0.4, "color": Color(0.7, 0.15, 0.55), "scale": 1.6}
		_:
			return _raw("normal")


static func build_wave(wave: int) -> Array:
	var plan: Array = []
	var base := 5 + int(wave * 1.2)
	plan.append({"id": "normal", "count": base})
	if wave >= 2:
		plan.append({"id": "fast", "count": 2 + wave})
	if wave >= 3:
		plan.append({"id": "swarm", "count": 3 + int(wave * 1.2)})
	if wave >= 4:
		plan.append({"id": "armored", "count": 1 + int(wave / 2)})
	if wave >= 5:
		plan.append({"id": "flying", "count": 2 + wave})
	if wave >= 6:
		plan.append({"id": "splitter", "count": 1 + int((wave - 5) / 3)})
	if wave >= 8:
		plan.append({"id": "flying", "count": 1 + int(wave / 2)})
	if wave >= 10:
		plan.append({"id": "armored", "count": 1 + int(wave / 3)})
	if wave >= 11:
		plan.append({"id": "splitter", "count": 1 + int(wave / 5)})
	if wave > 0 and wave % 5 == 0:
		plan.append({"id": "boss", "count": 1 + int((wave - 1) / 10)})
	if wave >= 14:
		plan.append({"id": "boss", "count": 1})
	return plan


static func preview_text(wave: int) -> String:
	var plan: Array = build_wave(wave)
	var parts: PackedStringArray = []
	for item in plan:
		var def: Dictionary = by_id(str(item["id"]))
		parts.append("%sx%d" % [def["name"], int(item["count"])])
	return " / ".join(parts)


static func wave_hp_mult(wave: int) -> float:
	# Early gentle; mid/late steeper so upgraded towers matter.
	var m := 1.0 + (wave - 1) * 0.135 + pow(maxi(0, wave - 5), 1.3) * 0.068
	if wave > 10:
		m *= 1.0 + float(wave - 10) * 0.05
	if wave > 15:
		m *= 1.12
	return m


static func wave_armor_bonus(wave: int) -> float:
	# No flat armor on waves 1-2 so basic towers stay relevant.
	var m := (
		float(maxi(0, wave - 2)) * 0.75
		+ float(maxi(0, wave - 8)) * 1.4
		+ float(maxi(0, wave - 12)) * 1.25
	)
	if wave > 15:
		m *= 1.15
	return m


static func wave_speed_mult(wave: int) -> float:
	var m := 1.0 + (wave - 1) * 0.028
	if wave > 12:
		m *= 1.0 + float(wave - 12) * 0.02
	if wave > 15:
		m *= 1.08
	return m
