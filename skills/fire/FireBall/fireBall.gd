extends BaseSkill

@export var speed: float = 450.0
@export var lifetime: float = 3.0
@export var damage: float = 20.0
@export var spawn_offset: float = 24.0

var direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0


func _init() -> void:
	cooldown = 0.8
	mana_spend = 20.0

func _ready() -> void:
	if not is_projectile:
		go_dormant()
		return
	body_entered.connect(_on_body_entered)


func use(dir: Vector2) -> void:
	spawn_copy(dir, spawn_offset, {"direction": dir})
	start_cooldown()


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
