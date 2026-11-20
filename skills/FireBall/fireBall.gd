extends Area2D

@export var speed: float = 450.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 20.0
var caster: Node2D

var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == caster:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
