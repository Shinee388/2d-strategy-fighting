extends Node2D

@export var damage_small: float = 8.0
@export var damage_big: float = 25.0
@export var small_active_time: float = 0.15
@export var small_recovery: float = 0.1
@export var big_active_time: float = 0.25
@export var big_recovery: float = 0.4
@export var combo_window: float = 0.6
@export var reach: float = 28.0
@export var lunge_small: float = 150.0   # jijig tsokhilt: ~22 px urgui
@export var lunge_big: float = 250.0     # tom tsokhilt: ~62 px urgui
@onready var hitbox_small: Area2D = $"hitbox1,2"
@onready var hitbox_big: Area2D = $hitbox3

var caster: Node2D
var combo_step: int = 0
var busy: bool = false

var _combo_deadline: float = 0.0
var _hit_bodies: Array[Node2D] = []


func _ready() -> void:
	if caster == null:
		caster = get_parent()
	_set_hitbox(hitbox_small, false)
	_set_hitbox(hitbox_big, false)
	hitbox_small.body_entered.connect(_on_hit.bind(damage_small))
	hitbox_big.body_entered.connect(_on_hit.bind(damage_big))


func attack(direction: Vector2) -> void:
	if busy:
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now > _combo_deadline:
		combo_step = 0  # daraalaagui bol 1,2-oos dakhin ekhelne

	busy = true
	rotation = direction.angle()
	position = direction * reach
	_hit_bodies.clear()

	if combo_step < 2:
		await _swing(hitbox_small, small_active_time, small_recovery, direction * lunge_small)
		combo_step += 1
	else:
		await _swing(hitbox_big, big_active_time, big_recovery, direction * lunge_big)
		combo_step = 0

	_combo_deadline = Time.get_ticks_msec() / 1000.0 + combo_window
	busy = false


func _swing(hitbox: Area2D, active_time: float, recovery: float, lunge: Vector2) -> void:
	caster.set("lunge_velocity", lunge)
	_set_hitbox(hitbox, true)
	await get_tree().create_timer(active_time).timeout
	caster.set("lunge_velocity", Vector2.ZERO)
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
