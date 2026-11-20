extends Area2D

@export var speed: float = 450.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 20.0
var caster: Node2D

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
