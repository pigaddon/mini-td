extends Area2D
class_name Bullet

## 纯视觉弹道：伤害已在开火时即刻结算，避免漏弹/堆积导致“塔不打”。

@export var speed: float = 900.0

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.45
var _target: Enemy = null
var _aim_pos: Vector2 = Vector2.ZERO


func setup_visual(from: Vector2, target: Enemy, color: Color) -> void:
	monitoring = false
	monitorable = false
	global_position = from
	_target = target
	_aim_pos = target.global_position if target != null and is_instance_valid(target) else from + Vector2.RIGHT * 40.0
	if has_node("Visual"):
		$Visual.color = color
	direction = (_aim_pos - from).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()


func _process(delta: float) -> void:
	if _target != null and is_instance_valid(_target) and _target.alive:
		_aim_pos = _target.global_position
		direction = (_aim_pos - global_position).normalized()
		if direction != Vector2.ZERO:
			rotation = direction.angle()
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0 or global_position.distance_to(_aim_pos) <= 14.0:
		queue_free()
