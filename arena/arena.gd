extends Node2D

signal match_finished(winner_id: int)  # 0 = tentsuu (draw)

const FIGHTER_SCENE := preload("res://fighter/fighter.tscn")

const PLAYER_COLORS := {1: Color.WHITE, 2: Color(0.55, 0.75, 1.0)}
const INTRO_TIME: float = 1.2
const FIGHT_TEXT_TIME: float = 0.6
const END_DELAY: float = 2.0

# Map node (SpawnP1/SpawnP2) baikhgui uyd ashiglakh bairlal
@export var fallback_spawn_p1: Vector2 = Vector2(260, 380)
@export var fallback_spawn_p2: Vector2 = Vector2(1660, 380)

# Tanii gar-aar nemsen node-uud (zaaval bish): "Map", "HUD"
@onready var map: Node = get_node_or_null("Map")
@onready var hud: Node = get_node_or_null("HUD")

var fighters: Dictionary = {}  # player_id -> Fighter

var _loadouts: Dictionary = {}
var _series: Dictionary = {}
var _resolving: bool = false


# game.gd scene-ee nemekhees omno duudna
func setup(loadouts: Dictionary, series: Dictionary) -> void:
	_loadouts = loadouts
	_series = series


func _ready() -> void:
	var wins: Dictionary = _series.get("wins", {1: 0, 2: 0})
	_hud(&"setup", [_series.get("best_of", 3), _series.get("wins_needed", 2)])
	_hud(&"set_wins", [wins[1], wins[2]])
	_hud(&"set_match_number", [_series.get("match_number", 1)])

	for player_id in [1, 2]:
		var fighter: Fighter = FIGHTER_SCENE.instantiate()
		fighter.player_id = player_id
		fighter.name = "Player%d" % player_id
		fighter.modulate = PLAYER_COLORS[player_id]
		add_child(fighter)
		fighter.equip_loadout(_loadouts.get(player_id, {}))
		fighter.died.connect(_on_fighter_died)
		fighters[player_id] = fighter

		if hud and hud.has_method("bind_fighter"):
			hud.bind_fighter(fighter)
		else:
			fighter.health_changed.connect(
				func(current: float, _max_hp: float) -> void:
					print("P%d HP: %d" % [player_id, current]))

	_run_intro()


# HUD-d method baival duudna, baikhgui bol show_message-iig print khiine
func _hud(method: StringName, args: Array = []) -> void:
	if hud and hud.has_method(method):
		hud.callv(method, args)
	elif method == &"show_message":
		print(args[0])


func _get_spawn(player_id: int) -> Vector2:
	if map:
		var marker := map.get_node_or_null("SpawnP%d" % player_id) as Node2D
		if marker:
			return marker.global_position
	return fallback_spawn_p1 if player_id == 1 else fallback_spawn_p2


func _run_intro() -> void:
	for fighter: Fighter in fighters.values():
		fighter.reset_for_match(_get_spawn(fighter.player_id))

	_hud(&"show_message", ["MATCH %d" % _series.get("match_number", 1)])
	await _wait(INTRO_TIME)

	_hud(&"show_message", ["FIGHT!"])
	for fighter: Fighter in fighters.values():
		fighter.fighting = true
	await _wait(FIGHT_TEXT_TIME)
	if not _resolving:
		_hud(&"clear_message")


func _on_fighter_died(_player_id: int) -> void:
	if _resolving:
		return
	_resolving = true
	# Deferred: neg frame-d 2 toglogch khoyulaa ukhvul tentsuu gej tootsno
	_resolve_match.call_deferred()


func _resolve_match() -> void:
	for fighter: Fighter in fighters.values():
		fighter.fighting = false
	for node in get_tree().get_nodes_in_group("projectiles"):
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
