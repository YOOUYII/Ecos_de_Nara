extends Node

const CHARACTER_FORASTERO := "forastero"
const CHARACTER_FORASTERA := "forastera"

var selected_character := ""

func select_character(character_type: String) -> void:
	if character_type == CHARACTER_FORASTERO or character_type == CHARACTER_FORASTERA:
		selected_character = character_type

func has_selected_character() -> bool:
	return selected_character != ""

func start_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func show_intro() -> void:
	if has_selected_character():
		get_tree().change_scene_to_file("res://scenes/ui/intro.tscn")

func begin_world() -> void:
	get_tree().change_scene_to_file("res://scenes/world/world_test.tscn")
