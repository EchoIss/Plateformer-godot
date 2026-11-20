extends SceneTree

var game: Node
var player: CharacterBody2D
var failures: Array[String] = []

func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures.append(label)
		print("FAIL: " + label)

func wait_physics(n: int) -> void:
	for i in n:
		await physics_frame

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await wait_physics(5)

	player = game.get_node("Level1/Player")
	check(player != null, "niveau 1 chargé avec un joueur")
	check(game.coins_in_level == 5, "niveau 1 contient 5 pièces (trouvé : %d)" % game.coins_in_level)
	check(game.get_tree().get_nodes_in_group("enemies").size() >= 2, "au moins 2 ennemis présents")

	var start_x := player.global_position.x
	Input.action_press("move_right")
	await wait_physics(30)
	Input.action_release("move_right")
	check(player.global_position.x > start_x + 100.0, "le joueur se déplace à droite (dx=%.0f px)" % (player.global_position.x - start_x))
	await wait_physics(30)

	var y_before := player.global_position.y
	Input.action_press("jump")
	await wait_physics(2)
	Input.action_release("jump")
	check(player.velocity.y < -200.0, "le saut donne une vélocité négative (v=%.0f)" % player.velocity.y)
	var jumped := player.velocity.y < -200.0
	await wait_physics(12)
	var mid_air := not player.is_on_floor()
	Input.action_press("jump")
	await wait_physics(2)
	Input.action_release("jump")
	var double_jump_vel := player.velocity.y
	check(double_jump_vel < -200.0, "le double saut relance en l'air (v=%.0f)" % double_jump_vel)
	await wait_physics(90)
	check(player.is_on_floor(), "le joueur retombe au sol")
	if jumped and not mid_air:
		failures.append("le joueur n'a pas quitté le sol après le premier saut")
		print("FAIL: le joueur n'a pas quitté le sol après le premier saut")

	var coins: Array = game.get_level_coins()
	check(coins.size() == 5, "5 pièces trouvées en scène")
	for coin in coins:
		player.position = coin.global_position
		player.velocity = Vector2.ZERO
		await wait_physics(6)
	await wait_physics(120)
	check(game.current_level == 1, "passage automatique au niveau 2 (niveau courant=%d)" % (game.current_level + 1))
	player = game.get_node_or_null("Level2/Player")
	check(player != null, "le niveau 2 est chargé avec un joueur")
	if player == null:
		quit(1)
		return
	check(game.coins_in_level == 6, "le niveau 2 contient 6 pièces (trouvé : %d)" % game.coins_in_level)

	var start := player.global_position
	var enemy: Node2D = game.get_node_or_null("Level2/Enemies/Enemy1")
	if enemy:
		player.position = enemy.global_position + Vector2(0, -10)
		player.velocity = Vector2(60, 0)
		await wait_physics(40)
		check(absf(player.global_position.x - 120.0) < 10.0, \
			"toucher un ennemi de côté fait réapparaître au départ (pos=%s)" % player.global_position)
		await wait_physics(30)
		enemy = game.get_node_or_null("Level2/Enemies/Enemy2")
		if enemy:
			player.position = enemy.global_position + Vector2(0, -45)
			player.velocity = Vector2(0, 300)
			var min_vy := 1000.0
			for i in 40:
				await physics_frame
				if is_instance_valid(player):
					min_vy = minf(min_vy, player.velocity.y)
			check(min_vy < -200.0, "rebond après écrasement d'un ennemi (vmin=%.0f)" % min_vy)
			await wait_physics(30)
			var still_there := false
			for e in get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.name == "Enemy2" and not e.dead:
					still_there = true
			check(not still_there, "l'ennemi écrasé disparaît")

	for coin in game.get_level_coins():
		player.position = coin.global_position
		player.velocity = Vector2.ZERO
		await wait_physics(8)
	await wait_physics(120)
	check(game.message_label.text.begins_with("Gagné"), "victoire affichée à la fin (texte='%s')" % game.message_label.text)

	print("---")
	if failures.is_empty():
		print("TOUS LES TESTS PASSENT (%d)" % 1)
		quit(0)
	else:
		print("%d ÉCHEC(S) : %s" % [failures.size(), ", ".join(failures)])
		quit(1)
