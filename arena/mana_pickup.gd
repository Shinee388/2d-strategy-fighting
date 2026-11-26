class_name ManaPickup
extends Area2D

@export var amount: float = 25.0
@export var lifetime: float = 10.0  # 0 = ustakhgui
@export var radius: float = 14.0

var _age: float = 0.0


func _ready() -> void:
	add_to_group("mana_pickups")
	# Editor deer CollisionShape2D nemeegui bol code-oor uusgene
	var has_shape := false
	for child in get_children():
		if child is CollisionShape2D:
			has_shape = true
	if not has_shape:
		var shape := CircleShape2D.new()
		shape.radius = radius
		var col := CollisionShape2D.new()
		col.shape = shape
		add_child(col)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.25, 0.55, 1.0, 0.9))
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.75, 0.92, 1.0))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.WHITE, 2.0)


func _process(delta: float) -> void:
	_age += delta
	scale = Vector2.ONE * (1.0 + 0.1 * sin(_age * 6.0))
	if lifetime > 0.0:
		if _age >= lifetime:
			queue_free()
		elif _age > lifetime - 2.0:
			modulate.a = 0.5 + 0.5 * sin(_age * 16.0)  # ustakhaas omno anivchina


# Body-iin dotor ni zogsokhod ch tsugluulna (body_entered-ees nailtai)
func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var fighter := body as Fighter
		if fighter == null or not fighter.alive or not fighter.fighting:
			continue
		if fighter.mana >= fighter.max_mana:
			continue  # mana dugui bol avakhgui, daraa ni avakhaar uldene
		fighter.restore_mana(amount)
		queue_free()
		return
