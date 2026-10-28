extends Node

## Estado de la historia, zonas y progreso narrativo.
## Conecta el aprendizaje de la carta con objetivos claros para el jugador.

signal flag_changed(flag_name: String, value: bool)
signal objective_changed(new_objective: String)
signal zone_unlocked(zone_name: String)

const ZONE_PUEBLO := "pueblo"
const ZONE_BOSQUE := "bosque"
const ZONE_RIO := "rio"

var current_zone := ZONE_PUEBLO
var unlocked_zones := {
	ZONE_PUEBLO: true,
	ZONE_BOSQUE: false,
	ZONE_RIO: false,
}
var flags: Dictionary = {}
var current_objective := "Habla con los habitantes del pueblo, anota vocabulario (N) y revisa tu carta (C)."


func can_enter(zone: String) -> bool:
	return unlocked_zones.get(zone, false)


func unlock_zone(zone: String) -> void:
	if unlocked_zones.has(zone) and not unlocked_zones[zone]:
		unlocked_zones[zone] = true
		zone_unlocked.emit(zone)


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String, value := true) -> void:
	var old_value: bool = flags.get(flag, false)
	flags[flag] = value
	if old_value != value:
		flag_changed.emit(flag, value)


func set_objective(objective: String) -> void:
	current_objective = objective
	objective_changed.emit(objective)
