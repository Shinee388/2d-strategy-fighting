extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 500.0
@export var friction: float = 1000.0
@export var max_health: float = 100.0

var health: float = max_health
var last_direction: Vector2 = Vector2.RIGHT
var style: BaseStyle


func _ready() -> void:
	style = GameState.create_style()
	style.caster = self
	add_child(style)


func _physics_process(delta: float) -> void:
	# Skill khiij bui uyd (combo, firestream) yavakhgui; combo-d urd zereg urgui orno
	if style.busy:
		velocity = style.lunge_velocity
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
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: style.skill1(last_direction)
			KEY_2: style.skill2(last_direction)
			KEY_3: style.skill3(last_direction)
			KEY_4: style.skill4(last_direction)


func take_damage(amount: float) -> void:
	health -= amount
	print(name, " health: ", health)
	if health <= 0.0:
		queue_free()
