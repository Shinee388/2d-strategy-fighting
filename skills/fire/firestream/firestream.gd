extends BaseSkill

@export var damage: float = 6.0
@export var tick_interval: float = 0.2
@export var grow_time: float = 0.25
@export var hold_time: float = 1.0
@export var fade_time: float = 0.2
@export var cast_time: float = 0.3        # skill-iig gargakh uyd caster zogsono
@export var spawn_offset: float = 10.0
@export var cancel_fade_time: float = 0.1  # tsutslagdakh uyd khurdan buurakh
@export var move_cancel_distance: float = 4.0  # caster ene zaigaas ikh yavbal stream ustana

var _full_scale: Vector2
var _tween: Tween
var _ending: bool = false
var _caster_start: Vector2
var _next_hit: Dictionary = {}  # {body: daraa ni damage ogokh tsag}


func _init() -> void:
	cooldown = 3.0
	mana_spend = 10.0


func _ready() -> void:
	if not is_projectile:
		go_dormant()
		return

	if caster:
		_caster_start = caster.global_position

	_full_scale = scale
	scale = Vector2(_full_scale.x * 0.05, _full_scale.y * 0.4)

	_tween = create_tween()
	_tween.tween_property(self, "scale", _full_scale, grow_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.parallel().tween_property(self, "scale:y", _full_scale.y * 0.3, fade_time)
	_tween.tween_callback(queue_free)


func use(dir: Vector2) -> void:
	busy = true
	lunge_velocity = Vector2.ZERO
	var stream := spawn_copy(dir, spawn_offset)
	stream.global_rotation = dir.angle()
	start_cooldown()
	await wait(cast_time)
	busy = false


func _physics_process(_delta: float) -> void:
	if not is_projectile or _ending:
		return

	if _should_cancel():
		end_stream()
		return

	# Stream dotor baigaa bukh body-d (caster-s busad) tick burt damage ogno
	var now := Time.get_ticks_msec() / 1000.0
	for body in get_overlapping_bodies():
		if body == caster or not body.has_method("take_damage"):
			continue
		if now >= _next_hit.get(body, 0.0):
			_next_hit[body] = now + tick_interval
			body.take_damage(damage)


func _should_cancel() -> bool:
	if not is_instance_valid(caster):
		return true
	var fighter := caster as Fighter
	if fighter and (not fighter.alive or not fighter.fighting):
		return true
	# Caster yavsan bol stream ustana
	return caster.global_position.distance_to(_caster_start) > move_cancel_distance


func end_stream() -> void:
	if _ending:
		return
	_ending = true
	set_deferred("monitoring", false) 
	if _tween:
		_tween.kill()

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, cancel_fade_time)
	fade.parallel().tween_property(self, "scale:y", _full_scale.y * 0.3, cancel_fade_time)
	fade.tween_callback(queue_free)
