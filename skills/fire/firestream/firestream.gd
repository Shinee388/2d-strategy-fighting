extends Area2D

@export var damage: float = 6.0
@export var tick_interval: float = 0.2
@export var grow_time: float = 0.25   # garch irekh khugatsaa
@export var hold_time: float = 1.0    # buten khemjeegeer baikh khugatsaa
@export var fade_time: float = 0.2    # ustakh khugatsaa

var caster: Node2D
var _full_scale: Vector2


func _ready() -> void:
	_full_scale = scale
	# Beltgel: jijig, nariin baidaltai ekhelne (0 scale collision-d aldaa uusgedeg)
	scale = Vector2(_full_scale.x * 0.05, _full_scale.y * 0.4)

	var tween := create_tween()
	# 1) Garch irekh: urt ni nuguulj, ikhsgene
	tween.tween_property(self, "scale", _full_scale, grow_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 2) Baikh
	tween.tween_interval(hold_time)
	# 3) Buurch, nuukhtsul ustana
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.parallel().tween_property(self, "scale:y", _full_scale.y * 0.3, fade_time)
	tween.tween_callback(queue_free)

	var timer := Timer.new()
	timer.wait_time = tick_interval
	timer.timeout.connect(_on_tick)
	add_child(timer)
	timer.start()


func _on_tick() -> void:
	for body in get_overlapping_bodies():
		if body == caster:
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage)
