extends SceneTree

## Animación de logro del Amuleto de Nara.
## Ejecutar: godot --headless --path . --script res://tests/test_achievement.gd
## No cambia misiones, zonas ni fragmentos (no dispara el autoguardado) para no tocar la partida real.

var _failures := 0
var _finished_count := 0


func _initialize() -> void:
	_run()


func _on_finished() -> void:
	_finished_count += 1


func _run() -> void:
	await create_timer(0.3).timeout
	var game: Node = root.get_node("GameManager")
	var story: Node = root.get_node("StoryProgress")
	var banner: Node = root.get_node("AchievementBanner")
	var menu: Node = root.get_node("MenuReturn")
	var icon: Texture2D = load("res://assets/art/props/objetos/item_amuleto.png")
	banner.finished.connect(_on_finished)

	# --- Unidad: ciclo de vida de la animación ---
	_check(not banner.is_playing() and not banner.visible and not paused, "la animación empieza apagada")
	banner.play(icon, "Título", "Nombre", "Subtítulo")
	_check(banner.is_playing() and banner.visible and paused, "play() la muestra y pausa el juego")
	_check(banner._title_label.text == "Título" and banner._name_label.text == "Nombre" and banner._sub_label.text == "Subtítulo", "muestra los textos recibidos")
	_check(banner._icon.texture == icon, "muestra el ícono recibido")
	_check(not banner.skip(), "no se puede saltar al instante (se ve el efecto)")
	banner.play(icon, "otra", "otra", "otra")
	_check(banner._title_label.text == "Título", "un segundo play() mientras suena se ignora")
	await create_timer(0.8).timeout
	_check(banner._icon.scale.x > 0.9, "el amuleto ya creció tras el rebote (%.2f)" % banner._icon.scale.x)
	_check(is_equal_approx(banner._banner.position.y, -240.0), "el cartel aún espera fuera de pantalla (empieza a los 0,9 s)")
	await create_timer(0.4).timeout
	_check(banner._banner.position.y > -240.0 and banner._banner.position.y < banner.BANNER_REST_Y + 30.0, "el cartel está bajando (y=%.0f)" % banner._banner.position.y)
	await create_timer(0.5).timeout
	_check(is_equal_approx(banner._banner.position.y, banner.BANNER_REST_Y), "el cartel llegó a su sitio (y=%.0f)" % banner._banner.position.y)
	_check(banner._sparkles.emitting, "las chispas siguen emitiendo mientras dura el cartel")
	_check(banner.skip(), "pasado el instante inicial sí se puede saltar")
	await create_timer(0.8).timeout
	_check(not banner.is_playing() and not banner.visible and not paused and _finished_count == 1, "al terminar se oculta, reanuda el juego y avisa (finished)")

	# Si el juego ya estaba en pausa, no se reanuda por error.
	paused = true
	banner.play(icon, "a", "b", "c")
	await create_timer(1.4).timeout
	banner.skip()
	await create_timer(0.8).timeout
	_check(paused and _finished_count == 2, "no reanuda un juego que ya estaba en pausa")
	paused = false

	# --- Integración: conseguir el amuleto en el río (en inglés) ---
	game.reset_all_data()
	game.confirm_languages("de", "en")
	var river: Node = load("res://scenes/world/world_rio.tscn").instantiate()
	root.add_child(river)
	current_scene = river
	await create_timer(0.4).timeout
	story.set_flag("fragment_3_translated", true)
	river._inspect_bridge()
	_check(story.has_flag("demo_completed") and story.has_item("amuleto_nara"), "el amuleto se consigue (bandera e ítem)")
	_check(banner.is_playing(), "conseguir el amuleto lanza la animación de logro")
	_check(banner._title_label.text == "Achievement unlocked!" and banner._name_label.text == "Amulet of Nara" and banner._sub_label.text.begins_with("You deciphered the letter"), "los textos del logro salen en el idioma principal")
	_check(not river.notice_panel.visible, "el aviso de texto espera a que termine la animación")
	game.select_character("forastero")
	_check(not menu.can_open(), "mientras suena el logro no se ofrece volver al menú (R)")
	await create_timer(1.4).timeout
	banner.skip()
	await create_timer(0.8).timeout
	_check(not banner.is_playing() and river.notice_panel.visible, "al terminar aparece el aviso con la pista final")
	_check(river.notice_label.text.begins_with("You found the Amulet of Nara under the bridge!"), "el aviso final está en el idioma principal")

	# La segunda vez no hay animación: solo el aviso de siempre.
	river.notice_panel.hide()
	river._inspect_bridge()
	_check(not banner.is_playing() and river.notice_label.text.begins_with("Under the bridge the river waters flow in peace"), "la segunda inspección no repite la animación")

	game.reset_all_data()
	print("RESULTADO: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok  - %s" % message)
	else:
		_failures += 1
		print("  FAIL - %s" % message)
