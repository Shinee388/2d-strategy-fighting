class_name BaseSkill
extends Node2D

@export var cooldown: float = 0.5

var caster: Node2D
var busy: bool = false
var lunge_velocity: Vector2 = Vector2.ZERO

var _ready_at: float = 0.0


func use(_direction: Vector2) -> void:
	pass


func can_use() -> bool:
	return not busy and Time.get_ticks_msec() / 1000.0 >= _ready_at


func start_cooldown() -> void:
	_ready_at = Time.get_ticks_msec() / 1000.0 + cooldown
