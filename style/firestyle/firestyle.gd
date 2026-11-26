extends BaseSkill

@export var damage_small: float = 8.0
@export var damage_big: float = 25.0
@export var small_active_time: float = 0.15
@export var small_recovery: float = 0.1
@export var big_active_time: float = 0.25
@export var big_recovery: float = 0.4
@export var combo_window: float = 0.6
@export var reach: float = 28.0
@export var lunge_small: float = 150.0
@export var lunge_big: float = 250.0

@onready var hitbox_small: Area2D = $"hitbox1,2"
@onready var hitbox_big: Area2D = $hitbox3

var combo_step: int = 0
var _combo_deadline: float = 0.0
var _hit_bodies: Array[Node2D] = []


func _init() -> void:
	cooldown = 0.0  # recovery ni cooldown-iin uuregtei


func _ready() -> void:
	monitoring = false   # root ni uchirdaggui, zuvkhun hitbox-uud uchirna
	monitorable = false
	_set_hitbox(hitbox_small, false)
	_set_hitbox(hitbox_big, false)
	hitbox_small.body_entered.connect(_on_hit.bind(damage_small))
	hitbox_big.body_entered.connect(_on_hit.bind(damage_big))


func use(dir: Vector2) -> void:
	if Time.get_ticks_msec() / 1000.0 > _combo_deadline:
		combo_step = 0

	busy = true
	rotation = dir.angle()
	position = dir * reach
	_hit_bodies.clear()

	if combo_step < 2:
		await _swing(hitbox_small, small_active_time, small_recovery, dir * lunge_small)
		combo_step += 1
	else:
		await _swing(hitbox_big, big_active_time, big_recovery, dir * lunge_big)
		combo_step = 0

	_combo_deadline = Time.get_ticks_msec() / 1000.0 + combo_window
	busy = false


func _swing(hitbox: Area2D, active_time: float, recovery: float, lunge: Vector2) -> void:
	lunge_velocity = lunge
	_set_hitbox(hitbox, true)
	await get_tree().create_timer(active_time).timeout
	lunge_velocity = Vector2.ZERO
	_set_hitbox(hitbox, false)
	await get_tree().create_timer(recovery).timeout


func _set_hitbox(hitbox: Area2D, active: bool) -> void:
	hitbox.visible = active
	hitbox.monitoring = active


func _on_hit(body: Node2D, damage: float) -> void:
	if body == caster or body in _hit_bodies:
		return
	_hit_bodies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(damage)
