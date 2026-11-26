extends BaseSkill

@export var damage: float = 6.0
@export var tick_interval: float = 0.2
@export var grow_time: float = 0.25
@export var hold_time: float = 1.0
@export var fade_time: float = 0.2
@export var cast_time: float = 0.3      # skill-iig gargakh uyd caster zogsono
@export var spawn_offset: float = 10.0
@export var mana_spend: float = 10.0


var _full_scale: Vector2


func _init() -> void:
	cooldown = 3.0


func _ready() -> void:
	if not is_projectile:
		go_dormant()
		return

	_full_scale = scale
	scale = Vector2(_full_scale.x * 0.05, _full_scale.y * 0.4)

	var tween := create_tween()
	tween.tween_property(self, "scale", _full_scale, grow_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.parallel().tween_property(self, "scale:y", _full_scale.y * 0.3, fade_time)
	tween.tween_callback(queue_free)

	var timer := Timer.new()
	timer.wait_time = tick_interval
	timer.timeout.connect(_on_tick)
	add_child(timer)
	timer.start()


func use(dir: Vector2) -> void:
	busy = true
	lunge_velocity = Vector2.ZERO
	var stream := spawn_copy(dir, spawn_offset)
	stream.global_rotation = dir.angle()
	start_cooldown()
	await get_tree().create_timer(cast_time).timeout
	busy = false


func _on_tick() -> void:
	for body in get_overlapping_bodies():
		if body == caster:
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage)
