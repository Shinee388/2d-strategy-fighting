extends Node2D

signal match_finished(winner_id: int)  # 0 = tentsuu (draw)

const MANA_PICKUP_SCENE := preload("res://arena/mana_pickup.tscn")

const PLAYER_COLORS := {1: Color.WHITE, 2: Color(0.55, 0.75, 1.0)}
const INTRO_TIME: float = 1.2
const FIGHT_TEXT_TIME: float = 0.6
const END_DELAY: float = 2.0

# --- Mana spawn tokhirgoo ---
@export var mana_amount: float = 25.0           # neg mana-iin sergeekh khemjee
@export var mana_spawn_interval: float = 4.0    # sekund buriin spawn
@export var mana_max_on_field: int = 3          # nug tsagt maksimum too
@export var mana_lifetime: float = 10.0         # ustakh khugatsaa (0 = ustakhgui)
@export var mana_spawn_area: Rect2 = Rect2(300, 140, 1320, 480)  # map-iinkhaa khemjeend tokhiruul

@onready var players: Node = $players
@onready var map: Node = get_node_or_null("map")   # Marker2D: SpawnP1, SpawnP2 (zaaval bish)
@onready var hud: Node = get_node_or_null("HUD")   # zaaval bish

var fighters: Dictionary = {}       # player_id -> Fighter
var _spawns: Dictionary = {}        # player_id -> Vector2

var _loadouts: Dictionary = {}
var _series: Dictionary = {}
var _resolving: bool = false
var _mana_timer: Timer


# game.gd scene-ee nemekhees omno duudna
func setup(loadouts: Dictionary, series: Dictionary) -> void:
	_loadouts = loadouts
	_series = series


func _ready() -> void:
	var wins: Dictionary = _series.get("wins", {1: 0, 2: 0})
	_hud(&"setup", [_series.get("best_of", 3), _series.get("wins_needed", 2)])
	_hud(&"set_wins", [wins[1], wins[2]])
	_hud(&"set_match_number", [_series.get("match_number", 1)])

	for child in players.get_children():
		var fighter := child as Fighter
		if fighter == null:
			continue
		var id := fighter.player_id
		fighters[id] = fighter
		_spawns[id] = _find_spawn(id, fighter.global_position)

		fighter.modulate = PLAYER_COLORS.get(id, Color.WHITE)
		fighter.equip_loadout(_loadouts.get(id, {}))
		fighter.died.connect(_on_fighter_died)

		if hud and hud.has_method("bind_fighter"):
			hud.bind_fighter(fighter)
		else:
			fighter.health_changed.connect(
				func(current: float, _max_hp: float) -> void:
					print("P%d HP: %d" % [id, current]))

	_mana_timer = Timer.new()
	_mana_timer.wait_time = mana_spawn_interval
	_mana_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_mana_timer.timeout.connect(_spawn_mana)
	add_child(_mana_timer)

	_run_intro()


# HUD-d method baival duudna, baikhgui bol show_message-iig print khiine
func _hud(method: StringName, args: Array = []) -> void:
	if hud and hud.has_method(method):
		hud.callv(method, args)
	elif method == &"show_message":
		print(args[0])


# Map-d SpawnP1/SpawnP2 baival tuuniig, uguig bol editor deer tavisan baiguulalt
func _find_spawn(player_id: int, default_pos: Vector2) -> Vector2:
	if map:
		var marker := map.get_node_or_null("SpawnP%d" % player_id) as Node2D
		if marker:
			return marker.global_position
	return default_pos


func _run_intro() -> void:
	for fighter: Fighter in fighters.values():
		fighter.reset_for_match(_spawns[fighter.player_id])

	_hud(&"show_message", ["MATCH %d" % _series.get("match_number", 1)])
	await _wait(INTRO_TIME)

	_hud(&"show_message", ["FIGHT!"])
	for fighter: Fighter in fighters.values():
		fighter.fighting = true
	_mana_timer.start()
	await _wait(FIGHT_TEXT_TIME)
	if not _resolving:
		_hud(&"clear_message")


# ---------------- Mana spawn ----------------

func _spawn_mana() -> void:
	if _resolving:
		return
	if get_tree().get_nodes_in_group("mana_pickups").size() >= mana_max_on_field:
		return

	var pos: Variant = _find_free_position()
	if pos == null:
		return

	var pickup: ManaPickup = MANA_PICKUP_SCENE.instantiate()
	pickup.amount = mana_amount
	pickup.lifetime = mana_lifetime
	add_child(pickup)
	pickup.global_position = pos


# Khana, tosgon, toglogch deer tuurakhgui chuluutei tsegiig 12 udaa sorino
func _find_free_position() -> Variant:
	var space := get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collide_with_bodies = true
	query.collide_with_areas = false

	for i in 12:
		var p := Vector2(
			randf_range(mana_spawn_area.position.x, mana_spawn_area.end.x),
			randf_range(mana_spawn_area.position.y, mana_spawn_area.end.y))
		query.transform = Transform2D(0.0, p)
		if space.intersect_shape(query, 1).is_empty():
			return p
	return null


# ---------------- Match duusakh ----------------

func _on_fighter_died(_player_id: int) -> void:
	if _resolving:
		return
	_resolving = true
	# Deferred: neg frame-d 2 toglogch khoyulaa ukhvul tentsuu gej tootsno
	_resolve_match.call_deferred()


func _resolve_match() -> void:
	_mana_timer.stop()
	for fighter: Fighter in fighters.values():
		fighter.fighting = false
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("mana_pickups"):
		node.queue_free()

	var winner_id := 0
	for fighter: Fighter in fighters.values():
		if fighter.alive:
			winner_id = fighter.player_id

	if winner_id == 0:
		_hud(&"show_message", ["DRAW"])
	else:
		_hud(&"show_message", ["PLAYER %d WINS THE MATCH" % winner_id])

	await _wait(END_DELAY)
	match_finished.emit(winner_id)


func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()
