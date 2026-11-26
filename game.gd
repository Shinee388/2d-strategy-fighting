extends Node2D

const MAIN_MENU_SCENE := preload("res://mainmenu/main_menu.tscn")
const SELECTION_SCENE := preload("res://selection/selection.tscn")
const ARENA_SCENE := preload("res://arena/Arena.tscn")

const PLAYER_COUNT: int = 2
const MAX_SWAPS: int = 2  # match tus buriin daraa solij boloh ikh tuhai chadvar

# true bol selection-iig algasaad DEBUG_LOADOUT-aar shuud togloh
# (selection script bichigdeed false bolgono)
const SKIP_SELECTION: bool = false
const DEBUG_LOADOUT := {
	"style": "res://style/firestyle/firestyle.tscn",
	"skill1": "res://skills/fire/FireBall/fire_ball.tscn",
	"skill2": "res://skills/fire/firestream/firestream.tscn",
}

@export var best_of: int = 3  # 3 = bo3, 5 = bo5

@onready var scene_holder: Node = $Node

# {1: {"style": path, "skill1": path, ...}, 2: {...}}
var loadouts: Dictionary = {}
var wins: Dictionary = {1: 0, 2: 0}
var match_number: int = 0
var current: Node


func _ready() -> void:
	InputSetup.register()
	show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		show_main_menu()


func change_scene(node: Node) -> void:
	if current:
		current.queue_free()
	current = node
	scene_holder.add_child(current)


func wins_needed() -> int:
	return floori(best_of / 2.0) + 1


func show_main_menu() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	menu.start_pressed.connect(start_series)
	change_scene(menu)


func start_series() -> void:
	wins = {1: 0, 2: 0}
	match_number = 0
	loadouts.clear()
	if SKIP_SELECTION:
		loadouts = {1: DEBUG_LOADOUT.duplicate(), 2: DEBUG_LOADOUT.duplicate()}
		start_next_match()
	else:
		show_selection(false)


# swap_mode = true: match-iin dund 1-2 chadvar solikh
# Selection script ni: player_count, swap_mode, max_swaps, loadouts (var-uud)
# bolon finished(result: Dictionary) signal-tai baih yostoi
func show_selection(swap_mode: bool) -> void:
	var selection := SELECTION_SCENE.instantiate()

	selection.player_count = PLAYER_COUNT
	selection.swap_mode = swap_mode
	selection.max_swaps = MAX_SWAPS
	selection.loadouts = loadouts.duplicate(true)

	selection.finished.connect(_on_selection_finished)
	selection.back_to_menu.connect(show_main_menu)

	change_scene(selection)

func _on_selection_finished(result: Dictionary) -> void:
	if match_number > 0:
		for player_id in result:
			var old_loadout: Dictionary = loadouts.get(player_id, {})
			if count_swaps(old_loadout, result[player_id]) > MAX_SWAPS:
				push_warning("Player %d: too many swaps, keeping old loadout" % player_id)
				result[player_id] = old_loadout
	loadouts = result
	start_next_match()


func count_swaps(old_loadout: Dictionary, new_loadout: Dictionary) -> int:
	var count := 0
	for slot_name in new_loadout:
		if old_loadout.get(slot_name) != new_loadout[slot_name]:
			count += 1
	return count


func start_next_match() -> void:
	match_number += 1
	var arena := ARENA_SCENE.instantiate()
	arena.setup(loadouts, {
		"best_of": best_of,
		"wins_needed": wins_needed(),
		"wins": wins.duplicate(),
		"match_number": match_number,
	})
	arena.match_finished.connect(_on_match_finished)
	change_scene(arena)


func _on_match_finished(winner_id: int) -> void:
	if winner_id == 0:
		match_number -= 1  # tentsuu: neg match-iig dakhin togloно
		start_next_match()
		return

	wins[winner_id] += 1
	if wins[winner_id] >= wins_needed():
		show_series_result(winner_id)
	elif SKIP_SELECTION:
		start_next_match()
	else:
		show_selection(true)


func show_series_result(winner_id: int) -> void:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(box)

	var title := Label.new()
	title.text = "PLAYER %d WINS THE SERIES" % winner_id
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)

	var score := Label.new()
	score.text = "%d - %d" % [wins[1], wins[2]]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 40)
	box.add_child(score)

	var button := Button.new()
	button.text = "Main menu"
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(show_main_menu)
	box.add_child(button)

	change_scene(screen)
