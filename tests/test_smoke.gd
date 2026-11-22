extends SceneTree

var game: Node
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

func test(condition: bool, label: String) -> void:
	check(condition, label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await wait_physics(5)

	var player: CharacterBody2D = game.get_node("Level1/Player")
	test(player != null, "niveau 1 chargé avec un joueur")
	test(game.coins_in_level == 4, "niveau 1 contient 4 pièces (trouvé : %d)" % game.coins_in_level)
	test(game.get_level_nodes("enemies").size() >= 2, "au moins 2 ennemis présents")
	test(game.get_level_nodes("orbs").size() == 1, "1 orbe de transformation présent")
	test(game.hp == 3, "le joueur commence avec 3 cœurs")

	var start_x := player.global_position.x
	Input.action_press("move_right")
	await wait_physics(30)
	Input.action_release("move_right")
	test(player.global_position.x > start_x + 100.0, "le joueur se déplace à droite (dx=%.0f px)" % (player.global_position.x - start_x))
	await wait_physics(30)

	Input.action_press("jump")
	await wait_physics(2)
	Input.action_release("jump")
	test(player.velocity.y < -200.0, "le saut donne une vélocité négative")
	await wait_physics(12)
	Input.action_press("jump")
	await wait_physics(2)
	Input.action_release("jump")
	test(player.velocity.y < -200.0, "le double saut relance en l'air")
	await wait_physics(90)
	test(player.is_on_floor(), "le joueur retombe au sol")

	var orbs: Array = game.get_level_nodes("orbs")
	var orb: Area2D = orbs[0]
	player.position = orb.global_position
	player.velocity = Vector2.ZERO
	await wait_physics(8)
	test(game.form == "knight", "l'orbe transforme en Chevalier (form=%s)" % game.form)

	var enemies: Array = game.get_level_nodes("enemies")
	var target_enemy: CharacterBody2D = enemies[0]
	player.position = target_enemy.global_position + Vector2(-46, -5)
	player.velocity = Vector2.ZERO
	player.facing = 1.0
	await wait_physics(2)
	Input.action_press("attack")
	await wait_physics(3)
	Input.action_release("attack")
	await wait_physics(30)
	var target_alive := false
	for e in game.get_level_nodes("enemies"):
		if e == target_enemy and is_instance_valid(e) and not e.dead:
			target_alive = true
	test(not target_alive, "l'attaque à l'épée élimine un ennemi")

	var other: CharacterBody2D = null
	for e in game.get_level_nodes("enemies"):
		if is_instance_valid(e) and not e.dead:
			other = e
			break
	if other:
		player.position = other.global_position + Vector2(0, -2)
		player.velocity = Vector2.ZERO
		await wait_physics(15)
		test(game.hp == 2, "un contact de côté coûte 1 cœur (hp=%d)" % game.hp)
		test(player.invulnerable, "le joueur est invincible brièvement après un coup")
	else:
		test(false, "un ennemi vivant est disponible pour le test de contact")

	await wait_physics(90)
	player.position = Vector2(300, 760)
	player.velocity = Vector2.ZERO
	await wait_physics(40)
	test(game.hp == 1, "une chute coûte 1 cœur (hp=%d)" % game.hp)
	test(absf(player.global_position.x - 120.0) < 10.0, "le joueur réapparaît au départ après une chute")

	for coin in game.get_level_coins():
		player.position = coin.global_position
		player.velocity = Vector2.ZERO
		await wait_physics(8)
	await wait_physics(120)
	test(game.current_level == 1, "passage automatique au niveau 2")
	player = game.get_node_or_null("Level2/Player")
	test(player != null, "le niveau 2 est chargé")
	test(game.coins_in_level == 5, "le niveau 2 contient 5 pièces")

	var wizard_orb: Area2D = game.get_node_or_null("Level2/OrbWizard")
	if wizard_orb:
		player.position = wizard_orb.global_position
		player.velocity = Vector2.ZERO
		await wait_physics(8)
	test(game.form == "wizard", "l'orbe du niveau 2 transforme en Sorcier (form=%s)" % game.form)

	var fireballs_before := _count_fireballs()
	Input.action_press("attack")
	await wait_physics(3)
	Input.action_release("attack")
	await wait_physics(3)
	var fireballs_after := _count_fireballs()
	test(fireballs_after > fireballs_before, "le Sorcier lance une boule de feu")
	await wait_physics(90)

	for coin in game.get_level_coins():
		player.position = coin.global_position
		player.velocity = Vector2.ZERO
		await wait_physics(8)
	await wait_physics(120)
	test(game.current_level == 2, "passage automatique au niveau 3 (boss)")
	player = game.get_node_or_null("Level3/Player")
	var boss: CharacterBody2D = game.get_node_or_null("Level3/Boss")
	test(boss != null, "le boss est présent dans le niveau 3")
	test(game.boss_bar.visible, "la barre de vie du boss est affichée")

	if boss:
		player.make_invulnerable(60.0)
		for i in 4:
			if is_instance_valid(boss):
				boss.take_hit(2, boss.global_position + Vector2(10, 0))
				await wait_physics(3)
		await wait_physics(30)
		test(game.message_label.text.begins_with("Victoire"), "victoire affichée après la défaite du boss (texte='%s')" % game.message_label.text)

	print("---")
	if failures.is_empty():
		print("TOUS LES TESTS PASSENT")
		quit(0)
	else:
		print("%d ÉCHEC(S) : %s" % [failures.size(), ", ".join(failures)])
		quit(1)

func _count_fireballs() -> int:
	return _scan_fireballs(game)

func _scan_fireballs(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child.get_script() and str(child.get_script().resource_path).ends_with("fireball.gd"):
			count += 1
		count += _scan_fireballs(child)
	return count
