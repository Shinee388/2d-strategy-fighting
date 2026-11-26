
extends CanvasLayer

@onready var p1_hp: ProgressBar = $ArenaHUD/TopContainer/HBoxContainer/Player1/VBoxContainer/HPBar
@onready var p1_mp: ProgressBar = $ArenaHUD/TopContainer/HBoxContainer/Player1/VBoxContainer/MPBar

@onready var p2_hp: ProgressBar = $ArenaHUD/TopContainer/HBoxContainer/Player2/VBoxContainer/HPBar
@onready var p2_mp: ProgressBar = $ArenaHUD/TopContainer/HBoxContainer/Player2/VBoxContainer/MPBar

@onready var match_label: Label = $ArenaHUD/Match
@onready var match_info: VBoxContainer = $ArenaHUD/TopContainer/HBoxContainer/MatchInfo

var best_of: int = 3
var wins_needed: int = 2


func _ready() -> void:
	match_label.hide()


# Arena-аас хоёр Fighter-ийг ээлжлэн дамжуулна.
func bind_fighter(fighter: Fighter) -> void:
	var hp_bar: ProgressBar
	var mp_bar: ProgressBar

	if fighter.player_id == 1:
		hp_bar = p1_hp
		mp_bar = p1_mp
	elif fighter.player_id == 2:
		hp_bar = p2_hp
		mp_bar = p2_mp
	else:
		return

	fighter.health_changed.connect(
		func(current: float, max_hp: float):
			update_bar(hp_bar, current, max_hp)
	)

	fighter.mana_changed.connect(
		func(current: float, max_mp: float):
			update_bar(mp_bar, current, max_mp)
	)

	# Signal ирэхээс өмнө анхны утгыг харуулах.
	update_bar(hp_bar, fighter.health, fighter.max_health)
	update_bar(mp_bar, fighter.mana, fighter.max_mana)


func update_bar(
	bar: ProgressBar,
	current: float,
	maximum: float
) -> void:
	bar.max_value = maximum
	bar.value = current


# BO3 / BO5
func setup(bo: int, required_wins: int) -> void:
	best_of = bo
	wins_needed = required_wins
	_set_info_label("BestOfLabel", "BO%d" % bo)


func set_wins(p1: int, p2: int) -> void:
	_set_info_label("ScoreLabel", "%d : %d" % [p1, p2])


func set_match_number(number: int) -> void:
	_set_info_label("MatchNumberLabel", "MATCH %d" % number)


func _set_info_label(node_name: String, text_value: String) -> void:
	var label := match_info.get_node_or_null(node_name) as Label
	if label:
		label.text = text_value


func show_message(message: String) -> void:
	match_label.text = message
	match_label.show()


func clear_message() -> void:
	match_label.hide()
