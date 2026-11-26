class_name Fighter
extends CharacterBody2D

signal health_changed(current: float, max_hp: float)
signal mana_changed(current: float, max_mp: float)
signal not_enough_mana(slot_name: String)
signal died(player_id: int)

@export var player_id: int = 1
@export var speed: float = 300.0
@export var acceleration: float = 500.0
@export var friction: float = 1000.0
@export var max_health: float = 100.0
@export var max_mana: float = 100.0

const SLOT_NAMES: Array[String] = ["style", "skill1", "skill2", "skill3", "mobility"]

@onready var slots := {
	"style": $style,
	"skill1": $skill1,
	"skill2": $skill2,
	"skill3": $skill3,
	"mobility": $mobility,
}

var health: float = 0.0
var mana: float = 0.0
var alive: bool = true
var fighting: bool = false  # true uyd l khodolno, skill khiine, dmg avna, mana sergene
var last_direction: Vector2 = Vector2.RIGHT

var _act_left: StringName
var _act_right: StringName
var _act_up: StringName
var _act_down: StringName


func _ready() -> void:
	_act_left = InputSetup.action(player_id, "left")
	_act_right = InputSetup.action(player_id, "right")
	_act_up = InputSetup.action(player_id, "up")
	_act_down = InputSetup.action(player_id, "down")
	health = max_health
	mana = max_mana


# loadout: {"style": "res://...tscn", "skill1": "res://...tscn", ...}
func equip_loadout(loadout: Dictionary) -> void:
	for slot_name in loadout:
		equip(slot_name, load(loadout[slot_name]))


func equip(slot_name: String, scene: PackedScene) -> void:
	var slot: Node2D = slots[slot_name]
	for old in slot.get_children():
		old.queue_free()

	var skill := scene.instantiate()
	skill.caster = self
	slot.add_child(skill)


func get_skill(slot_name: String) -> BaseSkill:
	var slot: Node2D = slots[slot_name]
	if slot.get_child_count() == 0:
		return null
	return slot.get_child(0) as BaseSkill


func reset_for_match(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	health = max_health
	mana = max_mana
	alive = true
	fighting = false
	modulate.a = 1.0
	last_direction = Vector2.RIGHT if player_id == 1 else Vector2.LEFT
	for slot_name in slots:
		var skill := get_skill(slot_name)
		if skill:
			skill.reset_state()
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)


func take_damage(amount: float) -> void:
	if not alive or not fighting:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()


# Mana khangalttai bol khasaad true, dutuu bol yu ch khiikhgui false butsaana
func spend_mana(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if mana < amount:
		return false
	mana -= amount
	mana_changed.emit(mana, max_mana)
	return true

func _die() -> void:
	alive = false
	fighting = false
	velocity = Vector2.ZERO
	modulate.a = 0.35
	died.emit(player_id)


func _active_skill() -> BaseSkill:
	for slot_name in slots:
		var skill := get_skill(slot_name)
		if skill and skill.busy:
			return skill
	return null


func _physics_process(delta: float) -> void:
	if not fighting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Skill khiij bui uyd zuvkhun skill-iin lunge-aar khodolno
	var active := _active_skill()
	if active:
		velocity = active.lunge_velocity
		move_and_slide()
		return

	var input_dir := Input.get_vector(_act_left, _act_right, _act_up, _act_down)
	if input_dir != Vector2.ZERO:
		last_direction = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not fighting or key == null or key.echo:
		return
	if _active_skill() != null:
		return

	for slot_name in SLOT_NAMES:
		if event.is_action_pressed(InputSetup.action(player_id, slot_name)):
			_try_use_skill(slot_name)
			return


func _try_use_skill(slot_name: String) -> void:
	var skill := get_skill(slot_name)
	if skill == null or not skill.can_use():
		return
	if not spend_mana(skill.mana_spend):
		not_enough_mana.emit(slot_name)
		return
	skill.use(last_direction)

func restore_mana(amount: float) -> void:
	mana = minf(mana + amount, max_mana)
	mana_changed.emit(mana, max_mana)
