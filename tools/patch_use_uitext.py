# -*- coding: utf-8 -*-
from pathlib import Path
import re

ROOT = Path(r"c:\Users\WIN10\Desktop\godot")

# --- main.gd ---
main = ROOT / "scripts" / "main.gd"
text = main.read_text(encoding="utf-8")

repls = [
    (
        r'hud_timer\.text = "[^"]*" % maxf\(0\.0, wave_timer\)',
        'hud_timer.text = ("%s: %.1fs (%s)" % [UiText.t("timer"), maxf(0.0, wave_timer), UiText.t("early_hint")])',
    ),
    (
        r'hud_hint\.text = "[^"]*"\n\thud_preview\.text = "[^"]*" % EnemyCatalog\.preview_text\(1\)\n\thud_timer\.text = "[^"]*" % MapRegistry\.get_map_name\(selected_map_id\)',
        'hud_hint.text = UiText.t("hint_controls")\n\thud_preview.text = "%s: %s" % [UiText.t("next_preview"), EnemyCatalog.preview_text(1)]\n\thud_timer.text = "%s: %s" % [UiText.t("map"), MapRegistry.get_map_name(selected_map_id)]',
    ),
    (
        r'hud_hint\.text = "[^"]*"\n\t\treturn\n\tvar cell: Vector2i = grid\.world_to_cell\(pos\)',
        'hud_hint.text = UiText.t("locked")\n\t\treturn\n\tvar cell: Vector2i = grid.world_to_cell(pos)',
    ),
    (
        r'hud_hint\.text = "[^"]*" % cost\n\t\treturn\n\tif towers\.get_child_count\(\)',
        'hud_hint.text = UiText.t("no_gold") % cost\n\t\treturn\n\tif towers.get_child_count()',
    ),
    (
        r'hud_hint\.text = "[^"]*" % Settings\.get_max_towers\(\)',
        'hud_hint.text = UiText.t("tower_cap") % Settings.get_max_towers()',
    ),
    (
        r'hud_hint\.text = "[^"]*"\n\t\treturn\n\n\tgold -= cost',
        'hud_hint.text = UiText.t("bad_cell")\n\t\treturn\n\n\tgold -= cost',
    ),
    (
        r'hud_hint\.text = "[^"]*" % \[TowerCatalog\.by_id\(selected_tower_id\)\["name"\], cost\]',
        'hud_hint.text = UiText.t("placed") % [TowerCatalog.by_id(selected_tower_id)["name"], cost]',
    ),
    (
        r'upgrade_button\.text = "[^"]*" % selected_tower\.upgrade_cost\(\)',
        'upgrade_button.text = UiText.t("upgrade") % selected_tower.upgrade_cost()',
    ),
    (
        r'upgrade_button\.text = "[^"]*"\n\tsell_button\.text = "[^"]*" % selected_tower\.sell_value\(\)',
        'upgrade_button.text = UiText.t("max_lv")\n\tsell_button.text = UiText.t("sell") % selected_tower.sell_value()',
    ),
    (
        r'hud_hint\.text = "[^"]*"\n\t_refresh_info_panel\(\)\n\t_update_hud\(\)\n\n\nfunc _sell_selected',
        'hud_hint.text = UiText.t("upgraded")\n\t_refresh_info_panel()\n\t_update_hud()\n\n\nfunc _sell_selected',
    ),
    (
        r'hud_hint\.text = "[^"]*" % refund',
        'hud_hint.text = UiText.t("sold") % refund',
    ),
    (
        r'hud_hint\.text = "[^"]*" % \[early_bonus, wave\]\n\telse:\n\t\thud_hint\.text = "[^"]*" % wave',
        'hud_hint.text = UiText.t("early_wave") % [early_bonus, wave]\n\telse:\n\t\thud_hint.text = UiText.t("wave_in") % wave',
    ),
    (
        r'hud_preview\.text = "[^"]*" % EnemyCatalog\.preview_text\(wave\)',
        'hud_preview.text = "%s: %s" % [UiText.t("now_wave"), EnemyCatalog.preview_text(wave)]',
    ),
    (
        r'hud_preview\.text = "[^"]*" % EnemyCatalog\.preview_text\(wave \+ 1\)\n\t\thud_hint\.text = "[^"]*"',
        'hud_preview.text = "%s: %s" % [UiText.t("next_preview"), EnemyCatalog.preview_text(wave + 1)]\n\t\thud_hint.text = UiText.t("can_early")',
    ),
    (
        r'hud_preview\.text = "[^"]*" % EnemyCatalog\.preview_text\(wave \+ 1\)\n\thud_hint\.text = "[^"]*"',
        'hud_preview.text = "%s: %s" % [UiText.t("next_preview"), EnemyCatalog.preview_text(wave + 1)]\n\thud_hint.text = UiText.t("cleared")',
    ),
    (
        r'overlay_label\.text = "[^"]*" % \[\n\t\t\twave, Settings\.difficulty_label\(\), MapRegistry\.get_map_name\(selected_map_id\)\n\t\t\]',
        'overlay_label.text = UiText.t("win") % [\n\t\t\twave, Settings.difficulty_label(), MapRegistry.get_map_name(selected_map_id)\n\t\t]',
    ),
    (
        r'overlay_label\.text = "[^"]*" % \[\n\t\t\twave, str\(goal\) if goal > 0 else "[^"]*"\n\t\t\]',
        'overlay_label.text = UiText.t("lose") % [\n\t\t\twave, str(goal) if goal > 0 else UiText.t("inf")\n\t\t]',
    ),
    (
        r'pause_button\.text = "[^"]*" if get_tree\(\)\.paused else "[^"]*"\n\thud_hint\.text = "[^"]*" if get_tree\(\)\.paused else "[^"]*"',
        'pause_button.text = UiText.t("resume") if get_tree().paused else UiText.t("pause")\n\thud_hint.text = UiText.t("paused") if get_tree().paused else UiText.t("running")',
    ),
    (
        r'speed_button\.text = "[^"]*" % speed_steps\[speed_index\]',
        'speed_button.text = UiText.t("speed") % speed_steps[speed_index]',
    ),
    (
        r'hud_gold\.text = "[^"]*" % gold\n\thud_lives\.text = "[^"]*" % lives\n\tvar goal := Settings\.wave_goal\n\thud_wave\.text = "[^"]*" % \[wave, str\(goal\) if goal > 0 else "[^"]*"\]\n\thud_towers\.text = "[^"]*" % \[towers\.get_child_count\(\), Settings\.get_max_towers\(\)\]\n\tstart_button\.text = "[^"]*"',
        'hud_gold.text = UiText.t("gold_fmt") % gold\n\thud_lives.text = UiText.t("lives_fmt") % lives\n\tvar goal := Settings.wave_goal\n\thud_wave.text = UiText.t("wave_fmt") % [wave, str(goal) if goal > 0 else UiText.t("inf")]\n\thud_towers.text = UiText.t("towers_fmt") % [towers.get_child_count(), Settings.get_max_towers()]\n\tstart_button.text = UiText.t("start_btn")',
    ),
    (
        r'btn\.text = "%s\\n%d[^"]*" % \[def\["name"\], int\(def\["cost"\]\)\]',
        'btn.text = UiText.t("tower_btn") % [def["name"], int(def["cost"])]',
    ),
    (
        r'title\.text = "[^"]*"',
        'title.text = UiText.t("title")',
    ),
    (
        r'map_label\.text = "[^"]*"',
        'map_label.text = UiText.t("map_line")',
    ),
    (
        r'diff_label\.text = "[^"]*"',
        'diff_label.text = UiText.t("diff")',
    ),
]

for pat, rep in repls:
    text2, n = re.subn(pat, rep, text, count=1)
    print(("OK" if n else "MISS"), pat[:50])
    text = text2

# difficulty specs names
text = text.replace(
    '{"diff": 0, "name": "???", "gold": 170',
    '{"diff": 0, "name_key": "easy", "gold": 170',
)
# handle both ??? and Easy etc
text = re.sub(
    r'\{"diff": 0, "name": "[^"]+", "gold": 170, "lives": 22, "towers": 55, "waves": 12\},',
    '{"diff": 0, "name_key": "easy", "gold": 170, "lives": 22, "towers": 55, "waves": 12},',
    text,
)
text = re.sub(
    r'\{"diff": 1, "name": "[^"]+", "gold": 140, "lives": 16, "towers": 45, "waves": 15\},',
    '{"diff": 1, "name_key": "normal", "gold": 140, "lives": 16, "towers": 45, "waves": 15},',
    text,
)
text = re.sub(
    r'\{"diff": 2, "name": "[^"]+", "gold": 110, "lives": 10, "towers": 38, "waves": 18\},',
    '{"diff": 2, "name_key": "hard", "gold": 110, "lives": 10, "towers": 38, "waves": 18},',
    text,
)
text = re.sub(
    r'btn\.text = "%s \| [^"]*" % \[\n\t\t\tspec\["name"\], spec\["gold"\], spec\["lives"\], spec\["towers"\], spec\["waves"\]\n\t\t\]',
    'btn.text = UiText.t("diff_fmt") % [\n\t\t\tUiText.t(str(spec["name_key"])), spec["gold"], spec["lives"], spec["towers"], spec["waves"]\n\t\t]',
    text,
)

main.write_text(text, encoding="utf-8")
print("main patched")

# --- catalogs: point names to UiText keys ---
tower_cat = ROOT / "scripts" / "content" / "tower_catalog.gd"
tt = tower_cat.read_text(encoding="utf-8")
# Replace name/desc string values with UiText lookups at runtime - easier rewrite functions

tower_cat.write_text(
    """extends RefCounted
class_name TowerCatalog


static func all_ids() -> PackedStringArray:
	return PackedStringArray([\"basic\", \"splash\", \"slow\", \"sniper\", \"antiair\"])


static func by_id(id: String) -> Dictionary:
	var d := _raw(id)
	d[\"name\"] = UiText.t(str(d[\"name_key\"]))
	d[\"desc\"] = UiText.t(str(d[\"desc_key\"]))
	return d


static func _raw(id: String) -> Dictionary:
	match id:
		\"basic\":
			return {
				\"id\": \"basic\",
				\"name_key\": \"t_basic\",
				\"desc_key\": \"t_basic_d\",
				\"cost\": 15,
				\"color\": Color(0.45, 0.75, 0.5),
				\"range\": 120.0,
				\"fire_interval\": 0.55,
				\"damage\": 8.0,
				\"max_level\": 5,
				\"upgrade_costs\": [20, 35, 55, 80],
				\"can_target_flying\": false,
				\"only_flying\": false,
				\"armor_pierce\": 0.0,
				\"splash_radius\": 0.0,
				\"splash_ratio\": 0.0,
				\"slow_factor\": 0.0,
				\"slow_duration\": 0.0,
				\"poison_dps\": 0.0,
				\"poison_duration\": 0.0,
				\"crit_chance\": 0.05,
				\"crit_mult\": 1.5,
				\"vs_flying\": 0.0,
				\"vs_ground\": 1.0,
				\"hit_sfx\": \"res://assets/sfx/hit_basic.wav\",
				\"bullet_color\": Color(1.0, 0.92, 0.4),
				\"level_bonus\": {\"damage\": 3.5, \"range\": 8.0, \"fire_interval\": -0.04},
			}
		\"splash\":
			return {
				\"id\": \"splash\",
				\"name_key\": \"t_splash\",
				\"desc_key\": \"t_splash_d\",
				\"cost\": 55,
				\"color\": Color(0.95, 0.55, 0.25),
				\"range\": 130.0,
				\"fire_interval\": 0.85,
				\"damage\": 10.0,
				\"max_level\": 5,
				\"upgrade_costs\": [40, 70, 100, 140],
				\"can_target_flying\": false,
				\"only_flying\": false,
				\"armor_pierce\": 0.0,
				\"splash_radius\": 55.0,
				\"splash_ratio\": 0.55,
				\"slow_factor\": 0.0,
				\"slow_duration\": 0.0,
				\"poison_dps\": 0.0,
				\"poison_duration\": 0.0,
				\"crit_chance\": 0.0,
				\"crit_mult\": 1.0,
				\"vs_flying\": 0.0,
				\"vs_ground\": 1.0,
				\"hit_sfx\": \"res://assets/sfx/hit_heavy.wav\",
				\"bullet_color\": Color(1.0, 0.45, 0.2),
				\"level_bonus\": {\"damage\": 4.5, \"range\": 10.0, \"splash_radius\": 8.0, \"fire_interval\": -0.05},
			}
		\"slow\":
			return {
				\"id\": \"slow\",
				\"name_key\": \"t_slow\",
				\"desc_key\": \"t_slow_d\",
				\"cost\": 40,
				\"color\": Color(0.35, 0.7, 0.95),
				\"range\": 140.0,
				\"fire_interval\": 0.7,
				\"damage\": 4.0,
				\"max_level\": 5,
				\"upgrade_costs\": [30, 50, 75, 110],
				\"can_target_flying\": false,
				\"only_flying\": false,
				\"armor_pierce\": 0.0,
				\"splash_radius\": 40.0,
				\"splash_ratio\": 0.35,
				\"slow_factor\": 0.45,
				\"slow_duration\": 2.0,
				\"poison_dps\": 0.0,
				\"poison_duration\": 0.0,
				\"crit_chance\": 0.0,
				\"crit_mult\": 1.0,
				\"vs_flying\": 0.0,
				\"vs_ground\": 1.0,
				\"hit_sfx\": \"res://assets/sfx/hit_laser.wav\",
				\"bullet_color\": Color(0.4, 0.85, 1.0),
				\"level_bonus\": {\"damage\": 1.5, \"slow_factor\": 0.06, \"slow_duration\": 0.25, \"range\": 8.0},
			}
		\"sniper\":
			return {
				\"id\": \"sniper\",
				\"name_key\": \"t_sniper\",
				\"desc_key\": \"t_sniper_d\",
				\"cost\": 75,
				\"color\": Color(0.75, 0.35, 0.85),
				\"range\": 240.0,
				\"fire_interval\": 1.35,
				\"damage\": 28.0,
				\"max_level\": 5,
				\"upgrade_costs\": [55, 90, 130, 180],
				\"can_target_flying\": true,
				\"only_flying\": false,
				\"armor_pierce\": 10.0,
				\"splash_radius\": 0.0,
				\"splash_ratio\": 0.0,
				\"slow_factor\": 0.0,
				\"slow_duration\": 0.0,
				\"poison_dps\": 0.0,
				\"poison_duration\": 0.0,
				\"crit_chance\": 0.2,
				\"crit_mult\": 2.0,
				\"vs_flying\": 1.0,
				\"vs_ground\": 1.0,
				\"hit_sfx\": \"res://assets/sfx/hit_heavy.wav\",
				\"bullet_color\": Color(0.9, 0.5, 1.0),
				\"level_bonus\": {\"damage\": 10.0, \"armor_pierce\": 3.0, \"range\": 15.0, \"crit_chance\": 0.04},
			}
		\"antiair\":
			return {
				\"id\": \"antiair\",
				\"name_key\": \"t_aa\",
				\"desc_key\": \"t_aa_d\",
				\"cost\": 50,
				\"color\": Color(0.95, 0.85, 0.3),
				\"range\": 200.0,
				\"fire_interval\": 0.32,
				\"damage\": 14.0,
				\"max_level\": 5,
				\"upgrade_costs\": [35, 60, 90, 130],
				\"can_target_flying\": true,
				\"only_flying\": true,
				\"armor_pierce\": 2.0,
				\"splash_radius\": 0.0,
				\"splash_ratio\": 0.0,
				\"slow_factor\": 0.2,
				\"slow_duration\": 1.2,
				\"poison_dps\": 4.0,
				\"poison_duration\": 2.5,
				\"crit_chance\": 0.15,
				\"crit_mult\": 1.8,
				\"vs_flying\": 2.8,
				\"vs_ground\": 0.0,
				\"hit_sfx\": \"res://assets/sfx/hit_laser.wav\",
				\"bullet_color\": Color(1.0, 1.0, 0.55),
				\"level_bonus\": {\"damage\": 5.0, \"vs_flying\": 0.25, \"fire_interval\": -0.03, \"range\": 12.0},
			}
		_:
			return _raw(\"basic\")


static func sell_refund_ratio() -> float:
	return 0.6
""",
    encoding="utf-8",
)
print("tower_catalog rewritten")

(ROOT / "scripts" / "content" / "enemy_catalog.gd").write_text(
    """extends RefCounted
class_name EnemyCatalog


static func all_ids() -> PackedStringArray:
	return PackedStringArray([\"normal\", \"fast\", \"armored\", \"flying\", \"swarm\", \"boss\"])


static func by_id(id: String) -> Dictionary:
	var d := _raw(id)
	d[\"name\"] = UiText.t(str(d[\"name_key\"]))
	return d


static func _raw(id: String) -> Dictionary:
	match id:
		\"normal\":
			return {\"id\": \"normal\", \"name_key\": \"e_normal\", \"hp\": 40.0, \"speed\": 85.0, \"armor\": 1.0, \"reward\": 8, \"damage_to_base\": 1, \"flying\": false, \"resist_splash\": 0.0, \"resist_slow\": 0.0, \"color\": Color(0.85, 0.25, 0.22), \"scale\": 1.0}
		\"fast\":
			return {\"id\": \"fast\", \"name_key\": \"e_fast\", \"hp\": 26.0, \"speed\": 155.0, \"armor\": 0.0, \"reward\": 7, \"damage_to_base\": 1, \"flying\": false, \"resist_splash\": 0.0, \"resist_slow\": 0.3, \"color\": Color(1.0, 0.7, 0.2), \"scale\": 0.85}
		\"armored\":
			return {\"id\": \"armored\", \"name_key\": \"e_armor\", \"hp\": 70.0, \"speed\": 60.0, \"armor\": 12.0, \"reward\": 14, \"damage_to_base\": 1, \"flying\": false, \"resist_splash\": 0.4, \"resist_slow\": 0.15, \"color\": Color(0.45, 0.5, 0.6), \"scale\": 1.15}
		\"flying\":
			return {\"id\": \"flying\", \"name_key\": \"e_fly\", \"hp\": 34.0, \"speed\": 120.0, \"armor\": 2.0, \"reward\": 12, \"damage_to_base\": 1, \"flying\": true, \"resist_splash\": 0.2, \"resist_slow\": 0.0, \"color\": Color(0.6, 0.85, 1.0), \"scale\": 0.95}
		\"swarm\":
			return {\"id\": \"swarm\", \"name_key\": \"e_swarm\", \"hp\": 16.0, \"speed\": 105.0, \"armor\": 0.0, \"reward\": 4, \"damage_to_base\": 1, \"flying\": false, \"resist_splash\": -0.2, \"resist_slow\": 0.0, \"color\": Color(0.55, 0.9, 0.35), \"scale\": 0.7}
		\"boss\":
			return {\"id\": \"boss\", \"name_key\": \"e_boss\", \"hp\": 320.0, \"speed\": 52.0, \"armor\": 18.0, \"reward\": 50, \"damage_to_base\": 6, \"flying\": false, \"resist_splash\": 0.25, \"resist_slow\": 0.4, \"color\": Color(0.7, 0.15, 0.55), \"scale\": 1.6}
		_:
			return _raw(\"normal\")


static func build_wave(wave: int) -> Array:
	var plan: Array = []
	var base := 5 + int(wave * 1.4)
	plan.append({\"id\": \"normal\", \"count\": base})
	if wave >= 2:
		plan.append({\"id\": \"fast\", \"count\": 3 + wave})
	if wave >= 3:
		plan.append({\"id\": \"swarm\", \"count\": 4 + int(wave * 1.5)})
	if wave >= 4:
		plan.append({\"id\": \"armored\", \"count\": 2 + int(wave / 2)})
	if wave >= 5:
		plan.append({\"id\": \"flying\", \"count\": 3 + wave})
	if wave >= 8:
		plan.append({\"id\": \"flying\", \"count\": 2 + int(wave / 2)})
	if wave >= 10:
		plan.append({\"id\": \"armored\", \"count\": 2 + int(wave / 3)})
	if wave > 0 and wave % 4 == 0:
		plan.append({\"id\": \"boss\", \"count\": 1 + int((wave - 1) / 8)})
	if wave >= 12:
		plan.append({\"id\": \"boss\", \"count\": 1})
	return plan


static func preview_text(wave: int) -> String:
	var plan: Array = build_wave(wave)
	var parts: PackedStringArray = []
	for item in plan:
		var def: Dictionary = by_id(str(item[\"id\"]))
		parts.append(\"%sx%d\" % [def[\"name\"], int(item[\"count\"])])
	return \" / \".join(parts)


static func wave_hp_mult(wave: int) -> float:
	return 1.0 + (wave - 1) * 0.22 + pow(maxi(0, wave - 5), 1.35) * 0.08


static func wave_armor_bonus(wave: int) -> float:
	return float(maxi(0, wave - 1)) * 1.2 + float(maxi(0, wave - 6)) * 1.5


static func wave_speed_mult(wave: int) -> float:
	return 1.0 + (wave - 1) * 0.035
""",
    encoding="utf-8",
)
print("enemy_catalog rewritten")

(ROOT / "scripts" / "content" / "map_registry.gd").write_text(
    """extends RefCounted
class_name MapRegistry


static func all_map_ids() -> PackedStringArray:
	return PackedStringArray([\"cross_field\", \"corner_dash\", \"vertical_run\", \"diagonal_siege\"])


static func get_map(map_id: String) -> Dictionary:
	match map_id:
		\"corner_dash\":
			return _base(\"corner_dash\", \"map_corner\", Vector2i(0, 0), Vector2i(29, 13))
		\"vertical_run\":
			return _base(\"vertical_run\", \"map_vertical\", Vector2i(14, 0), Vector2i(14, 13))
		\"diagonal_siege\":
			return _base(\"diagonal_siege\", \"map_diagonal\", Vector2i(0, 13), Vector2i(29, 0))
		\"cross_field\", _:
			return _base(\"cross_field\", \"map_cross\", Vector2i(0, 7), Vector2i(29, 7))


static func get_map_name(map_id: String) -> String:
	return UiText.t(str(get_map(map_id).get(\"name_key\", map_id)))


static func _base(id: String, name_key: String, spawn: Vector2i, exit_cell: Vector2i) -> Dictionary:
	return {
		\"id\": id,
		\"name_key\": name_key,
		\"cell_size\": 40.0,
		\"origin\": Vector2(40, 80),
		\"cols\": 30,
		\"rows\": 14,
		\"spawn\": spawn,
		\"exit\": exit_cell,
	}
""",
    encoding="utf-8",
)
print("map_registry rewritten")

gs = ROOT / "scripts" / "content" / "game_settings.gd"
gt = gs.read_text(encoding="utf-8")
gt = re.sub(
    r'func difficulty_label\(\) -> String:\n(?:\t.*\n)+',
    'func difficulty_label() -> String:\n\tmatch difficulty:\n\t\tDifficulty.EASY:\n\t\t\treturn UiText.t("easy")\n\t\tDifficulty.HARD:\n\t\t\treturn UiText.t("hard")\n\t\t_:\n\t\t\treturn UiText.t("normal")\n',
    gt,
)
gs.write_text(gt, encoding="utf-8")
print("game_settings patched")

# tower info_text use UiText
tower = ROOT / "scripts" / "tower.gd"
tt = tower.read_text(encoding="utf-8")
tt = re.sub(
    r"func info_text\(\) -> String:\n(?:\t.*\n)+?\n\nfunc _process",
    """func info_text() -> String:
	var lines := PackedStringArray()
	lines.append(str(def["name"]) + " " + (UiText.t("lv") % [level, int(def.get("max_level", 5))]))
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
	return "\\n".join(lines)  # noqa: written as GDScript \\n escape


func _process""",
    tt,
)
tower.write_text(tt, encoding="utf-8")
print("tower.gd patched")

# class cache
cache = ROOT / ".godot" / "global_script_class_cache.cfg"
if cache.exists():
    ct = cache.read_text(encoding="utf-8")
    if "UiText" not in ct:
        ct = ct.replace(
            '"path": "res://scripts/content/tower_catalog.gd"\n}]',
            '"path": "res://scripts/content/tower_catalog.gd"\n}, {\n"base": &"RefCounted",\n"class": &"UiText",\n"icon": "",\n"is_abstract": false,\n"is_tool": false,\n"language": &"GDScript",\n"path": "res://scripts/content/ui_text.gd"\n}]',
        )
        cache.write_text(ct, encoding="utf-8")
        print("class cache updated")
print("ALL DONE")
