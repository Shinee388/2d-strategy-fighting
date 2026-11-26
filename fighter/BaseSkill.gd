class_name BaseSkill
extends Area2D

@export var cooldown: float = 0.5

var caster: Node2D
var busy: bool = false
var lunge_velocity: Vector2 = Vector2.ZERO
var is_projectile: bool = false  # true bol slot-iin zagvar biш, spawn khiigdsen khuulbar

var _ready_at: float = 0.0


func use(_direction: Vector2) -> void:
	pass


func can_use() -> bool:
	return not busy and Time.get_ticks_msec() / 1000.0 >= _ready_at


func start_cooldown() -> void:
	_ready_at = Time.get_ticks_msec() / 1000.0 + cooldown


# Slot-d suusan zagvar: kharagdakhgui, kheneer uchirdaggui
func go_dormant() -> void:
	hide()
	monitoring = false
	monitorable = false
	set_physics_process(false)


# Skill-iin scene-ee khuulj Arena-d spawn khiine. props-iig _ready-s omno onoono.
func spawn_copy(dir: Vector2, offset: float, props: Dictionary = {}) -> BaseSkill:
	var copy: BaseSkill = (load(scene_file_path) as PackedScene).instantiate()
	copy.is_projectile = true
	copy.caster = caster
	for key in props:
		copy.set(key, props[key])
	caster.get_parent().add_child(copy)
	copy.global_position = caster.global_position + dir * offset
	return copy
