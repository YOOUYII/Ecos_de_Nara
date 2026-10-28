extends Node

## Autoload principal: gestiona personaje, transiciones de zona y posición de spawn.

const CHARACTER_FORASTERO := "forastero"
const CHARACTER_FORASTERA := "forastera"

## Mapeo de zona → escena
const ZONE_SCENES := {
	"pueblo": "res://scenes/world/world_test.tscn",
	"bosque": "res://scenes/world/world_bosque.tscn",
	"rio": "res://scenes/world/world_rio.tscn",
}

var selected_character := ""

## Posición y dirección de spawn al entrar a una zona nueva
var spawn_position := Vector2.ZERO
var spawn_direction := "down"


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
	spawn_position = Vector2.ZERO
	spawn_direction = "down"
	get_tree().change_scene_to_file("res://scenes/world/world_test.tscn")


## Cambia de zona con posición de entrada y orientación del jugador.
func change_zone(zone: String, spawn_pos: Vector2, direction: String = "down") -> void:
	var scene_path: String = ZONE_SCENES.get(zone, "")
	if scene_path.is_empty():
		push_error("Zona desconocida: %s" % zone)
		return
	spawn_position = spawn_pos
	spawn_direction = direction
	get_tree().change_scene_to_file(scene_path)
