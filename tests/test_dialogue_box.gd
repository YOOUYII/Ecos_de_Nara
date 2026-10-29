extends SceneTree

## Prueba headless del cuadro de diálogo.
## Ejecutar: godot --headless --path . --script res://tests/test_dialogue_box.gd

const PORTRAIT := "res://assets/art/portraits/anim/guardia_serio_talk_3f.png"
const ICON := "res://assets/art/ui/ui_icono_candado.png"

var _failures := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var box: DialogueBox = load("res://scenes/ui/dialogue_box.tscn").instantiate()
	root.add_child(box)
	await process_frame

	# Línea clásica (String, sin extras): se escribe progresivamente y se completa con finish_typing.
	box.show_line("Karl", "Halt!", PORTRAIT, false)
	_check(box.is_typing(), "la línea empieza escribiéndose")
	_check(box.dialogue_label.visible_characters == 0, "ningún carácter visible al inicio")
	box.finish_typing()
	_check(not box.is_typing(), "finish_typing termina la escritura")
	_check(box.dialogue_label.visible_characters == -1, "texto completo tras finish_typing")
	_check(not box.icon_popup.visible, "sin extras no hay pictograma")

	# Icono inexistente: se ignora sin error.
	box.show_line("Karl", "Halt!", PORTRAIT, false, {"icon": "res://no_existe.png"})
	box.finish_typing()
	_check(not box.icon_popup.visible, "icono inexistente se ignora")

	# Icono con palabra: aparece solo al llegar al final de la palabra.
	box.show_line("Helga", "Das ist Brot.", PORTRAIT, false, {"icon": ICON, "icon_word": "Brot"})
	box._on_char_progress(5)
	_check(not box.icon_popup.visible, "el icono no aparece antes de la palabra")
	box._on_char_progress(12)
	_check(box.icon_popup.visible, "el icono aparece al terminar la palabra")
	box.finish_typing()
	_check(box.icon_popup.visible, "el icono sigue visible al terminar")

	# Una línea nueva oculta el icono de la anterior.
	box.show_line("Helga", "Hallo!", PORTRAIT, true)
	_check(not box.icon_popup.visible, "la línea nueva oculta el icono anterior")
	_check(box.next_button.text == "Cerrar", "última línea muestra Cerrar")

	box.hide_dialogue()
	_check(not box.panel.visible and not box.is_typing(), "hide_dialogue limpia el estado")

	print("RESULTADO: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok  - %s" % message)
	else:
		_failures += 1
		print("  FAIL - %s" % message)
