class_name Fighter
extends CharacterBody2D

@export var player_id: int = 1
@export var speed: float = 300.0
@export var acceleration: float = 500.0
@export var friction: float = 1000.0
@export var max_health: float = 100.0

# Slot bur: tovch -> slot-iin node-iin ner
const KEY_TO_SLOT := {
	KEY_F: "style",      
	KEY_1: "skill1",
	KEY_2: "skill2",
	KEY_3: "skill3",
	KEY_SPACE: "mobility",
}

@onready var slots := {
	"style": $style,
	"skill1": $skill1,
	"skill2": $skill2,
	"skill3": $skill3,
	"mobility": $mobility,
}

var health: float = max_health
var last_direction: Vector2 = Vector2.RIGHT


# Selection-ees: {"style": "res://...tscn", "skill1": "res://...tscn", ...}
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


func _active_skill() -> BaseSkill:
	for slot_name in slots:
		var skill := get_skill(slot_name)
		if skill and skill.busy:
			return skill
	return null


func _physics_process(delta: float) -> void:
	# Skill khiij bui uyd yavakhgui, skill-iin lunge/dash-aar l khodolno
	var active := _active_skill()
	if active:
		velocity = active.lunge_velocity
		move_and_slide()
		return

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir != Vector2.ZERO:
		last_direction = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _active_skill() != null:
		return
	if not KEY_TO_SLOT.has(event.keycode):
		return

	var skill := get_skill(KEY_TO_SLOT[event.keycode])
	if skill and skill.can_use():
		skill.use(last_direction)


func take_damage(amount: float) -> void:
	health -= amount
	print(name, " health: ", health)
	if health <= 0.0:
		queue_free()
