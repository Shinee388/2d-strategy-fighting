extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 500.0
@export var friction: float = 1000.0
@export var max_health: float = 100.0

@export_group("Fireball")
@export var fireball_scene: PackedScene = preload("res://skills/FireBall/fire_ball.tscn")
@export var fireball_cooldown: float = 0.5
@export var fireball_spawn_distance: float = 30.0

@export_group("Style")
@export var style_scene: PackedScene = preload("res://style/firestyle/firestyle.tscn")

var health: float = max_health
var last_direction: Vector2 = Vector2.RIGHT
var can_cast: bool = true
var style: Node2D


func _ready() -> void:
	style = style_scene.instantiate()
	style.caster = self
	add_child(style)


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir != Vector2.ZERO:
		last_direction = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			cast_fireball()
		elif event.keycode == KEY_K:
			style.attack(last_direction)  # K: 1 -> 2 -> 3 combo


func cast_fireball() -> void:
	if not can_cast or fireball_scene == null:
		return

	can_cast = false

	var fireball := fireball_scene.instantiate()
	fireball.direction = last_direction
	fireball.caster = self
	get_parent().add_child(fireball)
	fireball.global_position = global_position + last_direction * fireball_spawn_distance

	await get_tree().create_timer(fireball_cooldown).timeout
	can_cast = true


func take_damage(amount: float) -> void:
	health -= amount
	print(name, " health: ", health)
	if health <= 0.0:
		queue_free()
