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

func _teleport(pos: Vector2, frames: int = 8) -> void:
	var player: CharacterBody2D = game.player
	player.position = pos
	player.velocity = Vector2.ZERO
	await wait_physics(frames)

func _run() -> void:
	await process_frame
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await wait_physics(5)

	test(game.level != null, "la grande carte est chargee")
	var player: CharacterBody2D = game.player
	test(player != null, "un joueur est present")
	test(game.player.camera != null, "le joueur possede une camera")
	test(player.camera.limit_right == 3400 and player.camera.limit_bottom == 1600,
		"les limites de camera viennent des metadonnees (droite=%d bas=%d)" % [player.camera.limit_right, player.camera.limit_bottom])
	test(game.coins_in_level == 13, "la carte contient 13 pieces (trouve : %d)" % game.coins_in_level)
	test(game.get_level_nodes("keys").size() == 3, "3 cles sont cachees dans la carte")
	test(game.get_level_nodes("doors").size() == 1, "1 porte fermee protege le boss")
	test(game.get_level_nodes("flags").size() == 4, "4 checkpoints sont places")
	test(game.get_level_nodes("orbs").size() == 3, "3 orbes de pouvoir sont presents")
	test(game.get_level_nodes("enemies").size() >= 9, "au moins 9 ennemis fixes")
	test(game.get_level_nodes("boss").size() == 1, "le boss Roi Slime est present")
	test(game.hp == 3, "le joueur commence avec 3 coeurs")
	test(game.checkpoint == game.player_start, "le checkpoint initial est le depart")
	test(not player.has_dash, "la rupee est verrouillee au depart")

	Input.action_press("dash")
	await wait_physics(3)
	Input.action_release("dash")
	test(not player.dashing, "presser Maj sans la rupee ne fait rien")
	await wait_physics(30)

	var start_x: float = player.global_position.x
	Input.action_press("move_right")
	await wait_physics(30)
	Input.action_release("move_right")
	test(player.global_position.x > start_x + 100.0, "le joueur se deplace a droite (dx=%.0f px)" % (player.global_position.x - start_x))
	await wait_physics(30)

	var orbs: Array = game.get_level_nodes("orbs")
	var dash_orb: Area2D = null
	for orb in orbs:
		if orb.kind == "dash":
			dash_orb = orb
			break
	test(dash_orb != null, "un orbe de rupee existe")
	player.make_invulnerable(600.0)
	if dash_orb:
		await _teleport(dash_orb.global_position)
		test(player.has_dash, "l'orbe debloque la rupee")
		test(game.message_label.text.begins_with("Ru"), "message de rupee affiche (texte='%s')" % game.message_label.text)

	player.position = Vector2(600, 700)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await wait_physics(2)
	Input.action_press("dash")
	await wait_physics(4)
	Input.action_release("dash")
	test(player.dashing and absf(player.velocity.x) >= 900.0,
		"la rupee propulse a 950 px/s (vx=%.0f)" % player.velocity.x)
	Input.action_release("move_right")
	await wait_physics(30)
	test(not player.dashing, "la rupee s'arrete apres 0.2 s")

	var wizard_orb: Area2D = null
	for orb in game.get_level_nodes("orbs"):
		if orb.kind == "wizard":
			wizard_orb = orb
			break
	if wizard_orb:
		await _teleport(wizard_orb.global_position)
		test(game.form == "wizard", "l'orbe transforme en Sorcier (form=%s)" % game.form)
		var before: int = _count_fireballs()
		Input.action_press("attack")
		await wait_physics(3)
		Input.action_release("attack")
		await wait_physics(3)
		test(_count_fireballs() > before, "le Sorcier lance une boule de feu")
		await wait_physics(60)

	var score_before: int = game.score
	await _teleport(Vector2(420, 1000))
	test(game.score == score_before + 1, "une piece est ramassee (score=%d -> %d)" % [score_before, game.score])
	test(not game.switching, "ramasser les pieces ne termine pas le niveau")

	var keys: Array = game.get_level_nodes("keys")
	var key: Area2D = keys[0]
	await _teleport(key.global_position)
	test(game.keys_collected == 1, "une cle est ramassee (cles=%d)" % game.keys_collected)
	test(game.keys_label.text.begins_with("Cl\u00e9s : 1"), "le HUD affiche la cle (texte='%s')" % game.keys_label.text)

	var door: StaticBody2D = game.get_level_nodes("doors")[0]
	await _teleport(door.global_position + Vector2(0, -60), 12)
	test(not door.open, "la porte reste fermee sans les 3 cles")
	test(game.message_label.text.begins_with("Il te faut"), "message de porte verrouillee (texte='%s')" % game.message_label.text)
	await _teleport(Vector2(600, 700), 5)
	while game.keys_collected < game.total_keys:
		var k: Area2D = game.get_level_nodes("keys")[0]
		if is_instance_valid(k):
			k.picked.emit()
		else:
			break
		await wait_physics(2)
	test(game.keys_collected == 3, "les 3 cles sont ramassees (cles=%d)" % game.keys_collected)

	door._cooldown = 0.0
	await _teleport(door.global_position + Vector2(0, -60), 12)
	test(door.open, "la porte s'ouvre avec les 3 cles")

	var cave_flag: Area2D = null
	for flag in game.get_level_nodes("flags"):
		if flag.global_position.x == 2000.0:
			cave_flag = flag
			break
	if cave_flag:
		await _teleport(cave_flag.global_position, 12)
		test(cave_flag.active, "le drapeau s'active au contact")
		test(game.checkpoint.distance_to(cave_flag.global_position) < 60.0, "le checkpoint est deplace au drapeau (checkpoint=%s)" % str(game.checkpoint))
	else:
		test(false, "le drapeau de la grotte est present")

	player.blink_tween.kill()
	player.invulnerable = false
	player.modulate.a = 1.0
	var hp_before: int = game.hp
	player.position = Vector2(1700, 1550)
	player.velocity = Vector2.ZERO
	await wait_physics(30)
	test(game.hp == hp_before - 1, "le vide coute 1 coeur (hp=%d)" % game.hp)
	test(player.global_position.distance_to(game.checkpoint) < 60.0, "respawn au checkpoint")
	player.make_invulnerable(60.0)

	var boss: CharacterBody2D = game.get_level_nodes("boss")[0]
	game.player.make_invulnerable(60.0)
	for i in 4:
		if is_instance_valid(boss):
			boss.take_hit(2, boss.global_position + Vector2(10, 0))
			await wait_physics(3)
		await wait_physics(2)
	await wait_physics(30)
	test(game.message_label.text.begins_with("Victoire"), "victoire apres la defaite du boss (texte='%s')" % game.message_label.text)
	test(not game.boss_bar.visible, "la barre de boss disparait")

	print("---")
	if failures.is_empty():
		print("TOUS LES TESTS PASSENT")
		quit(0)
	else:
		print("%d ECHEC(S) : %s" % [failures.size(), ", ".join(failures)])
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
