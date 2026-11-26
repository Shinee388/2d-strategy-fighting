
extends Control

signal finished(result: Dictionary)
signal back_to_menu

var player_count: int = 2
var swap_mode: bool = false
var max_swaps: int = 2
var loadouts: Dictionary = {}

const ELEMENTS := [
	"Fire", "Water", "Earth", "Air", "Lightning"
]

const ROW_NAMES := [
	"Skill 1", "Skill 2", "Mobility", "Style"
]

const ROW_TYPES := [
	"skill", "skill", "mobility", "style"
]

const SKILL_SLOTS := ["skill1", "skill2", "skill3"]
const ALL_SLOTS := [
	"skill1", "skill2", "skill3", "mobility", "style"
]

# Шинэ ability нэмэхдээ зөвхөн энд бүртгэнэ.
# Path нь бодит PackedScene файл байх ёстой.
const CATALOG := [
	{
		"name": "Fireball",
		"element": "Fire",
		"type": "skill",
		"path": "res://skills/fire/FireBall/fire_ball.tscn"
	},
	{
		"name": "Firestream",
		"element": "Fire",
		"type": "skill",
		"path": "res://skills/fire/firestream/firestream.tscn"
	},
	{
		"name": "Fire Style",
		"element": "Fire",
		"type": "style",
		"path": "res://style/firestyle/firestyle.tscn"
	}
]

@onready var available_title: Label = \
	$MarginContainer/mainLayout/Available/VBoxContainer/Label

@onready var available_grid: GridContainer = \
	$MarginContainer/mainLayout/Available/VBoxContainer/ScrollContainer/GridContainer

@onready var loadout_title: Label = \
	$MarginContainer/mainLayout/Ladout/VBoxContainer/Label

@onready var skill_grid: GridContainer = \
	$MarginContainer/mainLayout/Ladout/VBoxContainer/GridContainer

@onready var mobility_grid: GridContainer = \
	$MarginContainer/mainLayout/Ladout/VBoxContainer/HBoxContainer2/VBoxContainer/GridContainer

@onready var style_grid: GridContainer = \
	$MarginContainer/mainLayout/Ladout/VBoxContainer/HBoxContainer2/VBoxContainer2/GridContainer

@onready var start_button: Button = \
	$MarginContainer/mainLayout/Ladout/VBoxContainer/VBoxContainer2/Button
@onready var back_button: Button =\
	$MarginContainer/mainLayout/Ladout/VBoxContainer/VBoxContainer2/Button2
var _working: Dictionary = {}
var _current_player: int = 1
var _notice: String = ""


func _ready() -> void:
	_working = loadouts.duplicate(true)

	for id in range(1, player_count + 1):
		if not _working.has(id):
			_working[id] = {}

	available_grid.columns = 6
	skill_grid.columns = 3
	mobility_grid.columns = 1
	style_grid.columns = 1

	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	_refresh()


func _current_loadout() -> Dictionary:
	return _working[_current_player]


func _get_abilities(element: String, kind: String) -> Array:
	var result: Array = []

	for entry in CATALOG:
		if entry["element"] != element:
			continue
		if entry["type"] != kind:
			continue

		if ResourceLoader.exists(entry["path"]):
			result.append(entry)

	return result


func _get_name(path: String) -> String:
	for entry in CATALOG:
		if entry["path"] == path:
			return entry["name"]

	if path.is_empty():
		return "Empty"

	return path.get_file().get_basename()


func _make_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(125, 55)
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _make_header(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(125, 45)
	return label


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _refresh() -> void:
	_refresh_available()
	_refresh_loadout()

	var heading := "PLAYER %d SELECTION" % _current_player

	if swap_mode:
		heading += "  |  SWAPS %d/%d" % [
			_count_swaps(_current_player), max_swaps
		]

	if not _notice.is_empty():
		heading += "  |  " + _notice

	available_title.text = heading
	loadout_title.text = "PLAYER %d LOADOUT" % _current_player

	start_button.text = (
        "START FIGHT"
		if _current_player >= player_count
		else "NEXT PLAYER"
	)

	start_button.disabled = not _is_loadout_valid()


func _refresh_available() -> void:
	_clear_container(available_grid)

	available_grid.add_child(_make_header("TYPE"))

	for element in ELEMENTS:
		available_grid.add_child(_make_header(element))

	for row_index in range(ROW_TYPES.size()):
		var kind: String = ROW_TYPES[row_index]

		available_grid.add_child(
			_make_header(ROW_NAMES[row_index])
		)

		for element in ELEMENTS:
			var options := _get_abilities(element, kind)

			var ability_index := 0
			if kind == "skill":
				ability_index = row_index

			if ability_index >= options.size():
				var empty := _make_button("—")
				empty.disabled = true
				available_grid.add_child(empty)
				continue

			var ability: Dictionary = options[ability_index]
			var path: String = ability["path"]

			var button := _make_button(ability["name"])
			button.tooltip_text = element + " / " + kind

			if _is_equipped(path):
				button.text = "✓ " + ability["name"]

			button.pressed.connect(
				_on_ability_pressed.bind(ability)
			)

			available_grid.add_child(button)


func _refresh_loadout() -> void:
	_clear_container(skill_grid)
	_clear_container(mobility_grid)
	_clear_container(style_grid)

	for slot_name in SKILL_SLOTS:
		_add_slot_button(skill_grid, slot_name)

	_add_slot_button(mobility_grid, "mobility")
	_add_slot_button(style_grid, "style")


func _add_slot_button(
	container: GridContainer,
	slot_name: String
) -> void:
	var current := _current_loadout()
	var path: String = current.get(slot_name, "")

	var label_text := "Empty"
	if not path.is_empty():
		label_text = _get_name(path)

	var button := _make_button(label_text)
	button.tooltip_text = slot_name

	if path.is_empty():
		button.disabled = true
	else:
		button.pressed.connect(
			_on_slot_pressed.bind(slot_name)
		)

	container.add_child(button)


func _is_equipped(path: String) -> bool:
	var current := _current_loadout()

	for slot_name in ALL_SLOTS:
		if current.get(slot_name, "") == path:
			return true

	return false


func _find_slot_for_path(path: String) -> String:
	var current := _current_loadout()

	for slot_name in ALL_SLOTS:
		if current.get(slot_name, "") == path:
			return slot_name

	return ""


func _on_ability_pressed(ability: Dictionary) -> void:
	var kind: String = ability["type"]
	var path: String = ability["path"]
	var current := _current_loadout().duplicate()

	var existing_slot := _find_slot_for_path(path)

	# Дахин дарахад тухайн ability-г хасна.
	if not existing_slot.is_empty():
		current.erase(existing_slot)
	elif kind == "skill":
		var target_slot := ""

		for slot_name in SKILL_SLOTS:
			if not current.has(slot_name):
				target_slot = slot_name
				break

		if target_slot.is_empty():
			_notice = "Skill slots full"
			_refresh()
			return

		current[target_slot] = path
	else:
		# Mobility болон Style тус бүр нэг slot-той.
		current[kind] = path

	_try_apply(current)


func _on_slot_pressed(slot_name: String) -> void:
	var current := _current_loadout().duplicate()
	current.erase(slot_name)
	_try_apply(current)


func _try_apply(candidate: Dictionary) -> void:
	_notice = ""

	if swap_mode:
		if _calculate_swaps(
			loadouts.get(_current_player, {}),
			candidate
		) > max_swaps:
			_notice = "Swap limit reached"
			_refresh()
			return

	_working[_current_player] = candidate
	_refresh()


func _calculate_swaps(
	old_data: Dictionary,
	new_data: Dictionary
) -> int:
	var count := 0

	for slot_name in ALL_SLOTS:
		if old_data.get(slot_name, "") != \
				new_data.get(slot_name, ""):
			count += 1

	return count


func _count_swaps(player_id: int) -> int:
	return _calculate_swaps(
		loadouts.get(player_id, {}),
		_working.get(player_id, {})
	)


func _is_loadout_valid() -> bool:
	var current := _current_loadout()

	if not current.has("style"):
		return false

	var has_skill := false

	for slot_name in SKILL_SLOTS:
		if current.has(slot_name):
			has_skill = true
			break

	return has_skill


func _on_back_button_pressed() -> void:
	if _current_player > 1:
		_current_player -= 1
		_notice = ""
		_refresh()
	else:
		back_to_menu.emit()

func _on_start_pressed() -> void:
	if not _is_loadout_valid():
		return

	_notice = ""

	if _current_player < player_count:
		_current_player += 1
		_refresh()
		return

	finished.emit(_working.duplicate(true))
