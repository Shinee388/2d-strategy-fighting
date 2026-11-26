extends Node2D

const MAIN_MENU_SCRIPT := preload("res://main_menu.gd")
const SELECTION_SCENE := preload("res://selection.tscn")
const ARENA_SCENE := preload("res://Arena.tscn")

const PLAYER_COUNT: int = 2

var loadouts: Dictionary = {}  # {player_id: {"combat": "Fire", "mobility": "Dash"}}
var current: Node


func _ready() -> void:
	show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		show_main_menu()


func change_scene(node: Node) -> void:
	if current:
		current.queue_free()
	current = node
	add_child(current)


func show_main_menu() -> void:
	var menu = MAIN_MENU_SCRIPT.new()
	menu.start_pressed.connect(show_selection)
	change_scene(menu)


func show_selection() -> void:
	loadouts.clear()
	var selection := SELECTION_SCENE.instantiate()
	selection.player_count = PLAYER_COUNT
	selection.finished.connect(_on_selection_finished)
	change_scene(selection)


func _on_selection_finished(result: Dictionary) -> void:
	loadouts = result
	start_arena()


func start_arena() -> void:
	var arena := ARENA_SCENE.instantiate()
	arena.setup(loadouts)
	change_scene(arena)
