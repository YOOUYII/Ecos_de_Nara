extends SceneTree

## Prueba headless del combate final: mazo sin repetidos, temporizador, daño y resultados.
## Ejecutar: godot --headless --path . --script res://tests/test_echo_battle.gd

var _failures := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var script: GDScript = load("res://scripts/ui/echo_battle.gd")
	var fallback: Array = script.FALLBACK_CONCEPTS

	# --- Mazo sin repetidos
	var few: Array[String] = script.build_deck(["bread", "key", "bread"], 7, fallback)
	_check(few.size() >= 7, "con pocos conceptos el mazo se completa hasta las rondas posibles (%d)" % few.size())
	_check(_all_unique(few), "el mazo con pocos conceptos no repite ninguno")
	_check(few.has("bread") and few.has("key"), "los conceptos confirmados van en el mazo")
	var many_input: Array = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"]
	var many: Array[String] = script.build_deck(many_input, 7, fallback)
	_check(many.size() == 12 and _all_unique(many), "con muchos conceptos usa solo los confirmados, sin repetir")
	var all_ok := true
	for i in 40:
		var deck: Array[String] = script.build_deck(["bread", "key", "wood"], 7, fallback)
		all_ok = all_ok and _all_unique(deck) and deck.size() >= 7
	_check(all_ok, "40 mazos barajados seguidos nunca repiten conceptos")

	# --- Combate
	root.get_node("Lang").set_languages("de", "es")
	root.get_node("GameManager").select_character("forastero")
	var battle = script.new()
	root.add_child(battle)
	await process_frame
	battle.start_battle()
	_check(battle.accepting_answer, "tras start_battle se acepta respuesta")
	_check(is_equal_approx(battle.time_left, battle.QUESTION_TIME), "el temporizador arranca completo")
	_check(battle.player_gems.size() == 3 and battle.echo_gems.size() == 5, "hay una gema por punto de vida (3 y 5)")

	var seen: Array[String] = [battle.current_concept]
	for i in 6:
		battle._next_round()
		seen.append(battle.current_concept)
	_check(_all_unique(seen), "las 7 rondas posibles no repiten pregunta: %s" % str(seen))
	battle.deck = script.build_deck(["bread", "key", "wood"], 7, fallback)
	battle._next_round()

	# Tiempo agotado = golpe recibido
	var hp: int = battle.player_health
	battle.time_left = 0.02
	await create_timer(0.3).timeout
	_check(battle.player_health == hp - 1, "agotar el tiempo resta una vida al jugador")
	_check(battle.results.size() == 1 and battle.results[0]["timeout"] and not battle.results[0]["correct"], "el tiempo agotado se registra como fallo")
	_check(not battle.accepting_answer, "tras resolver no se acepta otra respuesta")

	# El tiempo no corre con la libreta abierta
	await create_timer(battle.ROUND_DELAY + 0.2).timeout
	_check(battle.accepting_answer, "tras el retardo empieza la siguiente ronda")
	var notebook = root.get_node("Notebook")
	notebook.is_open = true
	var before: float = battle.time_left
	await create_timer(0.3).timeout
	_check(is_equal_approx(battle.time_left, before), "con la libreta abierta el tiempo no avanza")
	notebook.is_open = false

	# Acierto = el Eco pierde vida y la opción elegida tiembla y vuelve a su sitio
	var echo_hp: int = battle.echo_health
	var correct_index := -1
	for i in battle.option_buttons.size():
		if battle.option_buttons[i].text == battle._gloss_answer(battle.current_concept):
			correct_index = i
	_check(correct_index >= 0, "la respuesta correcta está entre las opciones")
	battle._answer(correct_index)
	_check(battle.echo_health == echo_hp - 1, "acertar resta una vida al Eco")
	_check(battle.results[-1]["correct"], "el acierto se registra")
	await create_timer(0.1).timeout
	var shaking := false
	for i in battle.option_buttons.size():
		shaking = shaking or battle.option_buttons[i].position != battle.button_base[i]
	_check(shaking, "las opciones tiemblan al responder")
	await create_timer(0.7).timeout
	var settled := true
	for i in battle.option_buttons.size():
		settled = settled and battle.option_buttons[i].position.is_equal_approx(battle.button_base[i])
	_check(settled, "las opciones vuelven a su posición tras el shake")
	_check(battle.echo_gems[echo_hp - 1].texture == battle.GEM_EMPTY, "la gema perdida del Eco queda vacía")

	await create_timer(battle.ROUND_DELAY).timeout
	# Fallo = el jugador pierde vida y la gema se rompe
	var wrong_index := (correct_index + 1) % 3
	for i in battle.option_buttons.size():
		if battle.option_buttons[i].text != battle._gloss_answer(battle.current_concept):
			wrong_index = i
			break
	var player_hp: int = battle.player_health
	battle._answer(wrong_index)
	_check(battle.player_health == player_hp - 1, "fallar resta una vida al jugador")
	await create_timer(0.8).timeout
	_check(battle.player_gems[player_hp - 1].texture == battle.GEM_EMPTY, "la gema perdida del jugador queda vacía")

	battle.queue_free()
	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(_failures)


func _all_unique(values: Array) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok  - ", message)
	else:
		_failures += 1
		print("  FAIL - ", message)
