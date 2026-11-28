extends BaseSkill

@export var speed: float = 450.0
@export var lifetime: float = 3.0
@export var damage: float = 20.0
@export var spawn_offset: float = 24.0

@export_group("Growth")
@export var start_scale: float = 0.5   
@export var end_scale: float = 5     
@export var grow_time: float = 2.5    

var direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0
var _base_scale: Vector2


func _init() -> void:
	cooldown = 0.8
	mana_spend = 20.0

func _ready() -> void:
	if not is_projectile:
		$GPUParticles2D.emitting = false
		go_dormant()
		return
	body_entered.connect(_on_body_entered)
	_base_scale = scale
	scale = _base_scale * start_scale

func use(dir: Vector2) -> void:
	spawn_copy(dir, spawn_offset, {"direction": dir})
	start_cooldown()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta

	# Yavsaar tomordog
	var t := clampf(_age / grow_time, 0.0, 1.0)
	scale = _base_scale * lerpf(start_scale, end_scale, t)

	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == caster:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
