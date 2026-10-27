extends Node

## Estado mínimo de las zonas. En secciones posteriores se conectará a misiones,
## diálogos y guardado; por ahora deja preparada la estructura del progreso.
const ZONE_PUEBLO := "pueblo"
const ZONE_BOSQUE := "bosque"
const ZONE_RIO := "rio"

var current_zone := ZONE_PUEBLO
var unlocked_zones := {
	ZONE_PUEBLO: true,
	ZONE_BOSQUE: false,
	ZONE_RIO: false,
}


func can_enter(zone: String) -> bool:
	return unlocked_zones.get(zone, false)
