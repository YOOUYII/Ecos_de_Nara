extends SceneTree

## Prueba visual con ventana real: abre el pueblo, inicia un diálogo con pictogramas
## (inyectado solo en memoria, sin tocar el JSON) y guarda capturas.
## Ejecutar: godot --path . --script res://tests/play_dialogue_visual.gd -- <carpeta_salida>

const BROT := "res://assets/art/ui/vocab/vocab_brot.png"
const WASSER := "res://assets/art/ui/vocab/vocab_wasser.png"
const PORTRAIT := "res://assets/art/portraits/anim/panadera_amable_talk_3f.png"

var _out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://"
	_run()


func _run() -> void:
	var world: Node = load("res://scenes/world/world_test.tscn").instantiate()
	root.add_child(world)
	await create_timer(0.5).timeout

	var npc: Npc
	for n in world.find_children("*", "Npc", true, false):
		if (n as Npc).npc_id == "panadera":
			npc = n
	if npc == null:
		print("FAIL: no se encontró la panadera en world_test")
		quit(1)
		return

	var dm: Node = root.get_node("DialogueManager")
	var test_variant := {
		"condition": {},
		"portrait": PORTRAIT,
		"effects": [],
		"lines": [
			"Hallo!",
			{"text": "Das ist Brot.", "icon": BROT, "icon_word": "Brot"},
			{"text": "Das ist Wasser.", "icon": WASSER, "icon_word": "Wasser"},
		],
	}
	# La zona tiene prioridad sobre los diálogos base: inyectar en ambos (solo en memoria).
	# Con el argumento "real" se usan los diálogos del JSON sin inyectar nada.
	if not OS.get_cmdline_user_args().has("real"):
		for source: Dictionary in [dm.zone_dialogue_data, dm.dialogue_data]:
			if source.get("dialogues", {}).has("panadera"):
				source["dialogues"]["panadera"]["variants"].insert(0, test_variant)

	print("start_dialogue -> ", dm.start_dialogue(npc))
	var box: DialogueBox = dm.dialogue_box
	await create_timer(0.15).timeout
	print("escribiendo (t=0.15s): typing=%s visibles=%d" % [box.is_typing(), box.dialogue_label.visible_characters])
	_shot("1_hallo_escribiendo")

	dm.advance_dialogue() # primer E: completa la línea
	print("tras 1er avance: typing=%s linea=%d" % [box.is_typing(), dm.current_line_index])
	await create_timer(0.1).timeout
	_shot("2_hallo_completo")

	dm.advance_dialogue() # segundo E: pasa a "Das ist Brot."
	print("tras 2do avance: linea=%d icono_visible=%s" % [dm.current_line_index, box.icon_popup.visible])
	await create_timer(0.2).timeout
	_shot("3_brot_antes_de_palabra")
	await create_timer(0.8).timeout
	print("fin de 'Das ist Brot.': typing=%s icono_visible=%s" % [box.is_typing(), box.icon_popup.visible])
	_shot("4_brot_con_pictograma")

	dm.advance_dialogue()
	await create_timer(1.0).timeout
	_shot("5_wasser_con_pictograma")
	print("linea=%d icono_visible=%s" % [dm.current_line_index, box.icon_popup.visible])

	dm.advance_dialogue()
	print("cierre: abierto=%s" % dm.is_dialogue_open)
	quit(0)


func _shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [_out, name])
