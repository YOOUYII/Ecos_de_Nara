extends Node

## Autoload principal: gestiona personaje, transiciones de zona y reinicio de partida.

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


## Partida nueva: los idiomas se eligen aquí, una sola vez, y quedan bloqueados para la partida.
## Si solo hay una combinación posible (hoy alemán con glosa en español), se aplica sin preguntar.
func start_new_game() -> void:
	reset_all_data()
	if Lang.needs_selection():
		get_tree().change_scene_to_file("res://scenes/ui/language_select.tscn")
		return
	var pairs: Array = Lang.valid_pairs()
	if pairs.is_empty() or not confirm_languages(pairs[0][0], pairs[0][1]):
		push_error("No hay ninguna combinación de idiomas disponible.")
		return
	show_character_select()


## Fija los idiomas de la partida (aprender, principal) y los bloquea. Devuelve false si no son válidos.
func confirm_languages(target: String, native: String) -> bool:
	if not Lang.set_languages(target, native):
		return false
	Lang.lock()
	return true


## Vuelve al menú de inicio descartando la partida en curso (no guarda). "Continuar" carga lo guardado.
func return_to_menu() -> void:
	reset_all_data()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func show_character_select() -> void:
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
	StoryProgress.current_zone = zone
	
	# Guardado automático al cambiar de zona si SaveManager está disponible
	if Engine.has_singleton("SaveManager") or has_node("/root/SaveManager"):
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("save_game"):
			sm.save_game(spawn_pos)
			
	get_tree().change_scene_to_file(scene_path)


## Reanuda una partida cargada desde archivo.
func resume_saved_game(zone: String, spawn_pos: Vector2, direction: String = "down") -> void:
	var scene_path: String = ZONE_SCENES.get(zone, "")
	if scene_path.is_empty():
		scene_path = ZONE_SCENES["pueblo"]
	spawn_position = spawn_pos
	spawn_direction = direction
	StoryProgress.current_zone = zone
	get_tree().change_scene_to_file(scene_path)


## Reinicia el estado de todos los subsistemas para una partida nueva y limpia.
func reset_all_data() -> void:
	selected_character = ""
	spawn_position = Vector2.ZERO
	spawn_direction = "down"
	Lang.reset()
	StoryProgress.reset()
	Notebook.reset()
	Letter.reset()
