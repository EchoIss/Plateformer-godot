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

	var player: CharacterBody2D = game.player
	test(game.level != null, "la grande carte est chargee")
	test(player != null, "un joueur est present")
	test(player.camera.limit_right == 6800 and player.camera.limit_bottom == 1600,
		"les limites de camera couvrent la carte (droite=%d bas=%d)" % [player.camera.limit_right, player.camera.limit_bottom])
	test(game.coins_in_level >= 40, "la carte contient 42+ pieces (trouve : %d)" % game.coins_in_level)
	test(game.get_level_nodes("keys").size() == 6, "6 clés cachées")
	test(game.get_level_nodes("doors").size() == 1, "1 grande porte protege le trone")
	test(game.get_level_nodes("flags").size() == 7, "7 checkpoints places")
	test(game.get_level_nodes("orbs").size() == 4, "4 orbes de pouvoir")
	test(game.get_level_nodes("hearts").size() == 3, "3 cœurs supplémentaires caches")
	test(game.get_level_nodes("boss").size() == 3, "3 boss dans le monde")
	test(game.get_level_nodes("enemies").size() >= 15, "au moins 15 ennemis")
	test(game.hp == 3 and game.hp_max == 3, "3 coeurs au depart")
	test(game.checkpoint == game.player_start, "checkpoint initial = depart")
	test(not player.has_dash and not player.has_walljump, "ruée et saut mural verrouillés au depart")

	var names: Array = []
	for b in game.get_level_nodes("boss"):
		names.append(b.boss_name)
	test("Chef Gobou" in names and "Gardienne Kaverna" in names and "Roi Slime" in names,
		"les 3 boss ont leur identité (trouve : %s)" % ", ".join(names))
	var any_elite := false
	for e in game.get_level_nodes("enemies"):
		if e.max_hp >= 5:
			any_elite = true
	test(any_elite, "des ennemis elites plus forts existent")
	test(game.current_zone != "", "le nom de zone s'affiche (zone=%s)" % game.current_zone)

	Input.action_press("dash")
	await wait_physics(3)
	Input.action_release("dash")
	test(not player.dashing, "Maj sans la ruée ne fait rien")
	await wait_physics(30)

	var start_x: float = player.global_position.x
	Input.action_press("move_right")
	await wait_physics(25)
	Input.action_release("move_right")
	test(player.global_position.x > start_x + 80.0, "le joueur se deplace (dx=%.0f px)" % (player.global_position.x - start_x))
	await wait_physics(30)

	var kinds: Array = []
	for orb in game.get_level_nodes("orbs"):
		kinds.append(orb.kind)
	test("dash" in kinds and "walljump" in kinds and "knight" in kinds and "wizard" in kinds,
		"orbes completes (trouve : %s)" % ", ".join(kinds))

	player.make_invulnerable(600.0)
	for orb in game.get_level_nodes("orbs"):
		if orb.kind == "dash":
			await _teleport(orb.global_position, 10)
	test(player.has_dash, "l'orbe débloque la ruée")

	player.position = Vector2(600, 700)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await wait_physics(2)
	Input.action_press("dash")
	await wait_physics(4)
	Input.action_release("dash")
	Input.action_release("move_right")
	test(player.dashing and absf(player.velocity.x) >= 900.0, "la ruée propulse a 950 px/s (vx=%.0f)" % player.velocity.x)
	await wait_physics(30)
	test(not player.dashing, "la ruée s'arrete apres 0.2 s")

	for orb in game.get_level_nodes("orbs"):
		if orb.kind == "walljump":
			await _teleport(orb.global_position, 10)
	test(player.has_walljump, "l'orbe débloque le saut mural")

	player.position = Vector2(60, 880)
	player.velocity = Vector2.ZERO
	Input.action_press("move_left")
	await wait_physics(20)
	test(player.is_on_wall_only(), "le joueur glisse contre le mur (y=%.0f)" % player.velocity.y)
	test(player.velocity.y <= 150.0, "la glissade murale ralentit la chute")
	Input.action_press("jump")
	await wait_physics(4)
	Input.action_release("jump")
	Input.action_release("move_left")
	test(player.velocity.x > 300.0 and player.velocity.y < -300.0,
		"le saut mural éjecte du mur (vx=%.0f vy=%.0f)" % [player.velocity.x, player.velocity.y])
	await wait_physics(40)

	for orb in game.get_level_nodes("orbs"):
		if orb.kind == "wizard":
			await _teleport(orb.global_position, 10)
	test(game.form == "wizard", "l'orbe transforme en Sorcier (form=%s)" % game.form)
	var before: int = _count_fireballs()
	Input.action_press("attack")
	await wait_physics(4)
	Input.action_release("attack")
	await wait_physics(3)
	test(_count_fireballs() > before, "le Sorcier lance des boules de feu")
	await wait_physics(40)

	for orb in game.get_level_nodes("orbs"):
		if orb.kind == "knight":
			await _teleport(orb.global_position, 10)
	test(game.form == "knight", "l'orbe transforme en Chevalier (form=%s)" % game.form)
	var target: CharacterBody2D = null
	for e in game.get_level_nodes("enemies"):
		if is_instance_valid(e) and not e.dead and e.max_hp == 1:
			target = e
			break
	if target:
		target.position = Vector2(850, 1130)
		target.velocity = Vector2.ZERO
		await wait_physics(2)
		player.position = target.global_position + Vector2(-52, -5)
		player.velocity = Vector2.ZERO
		player.facing = 1.0
		await wait_physics(2)
		Input.action_press("attack")
		await wait_physics(4)
		Input.action_release("attack")
		await wait_physics(30)
		var gone := true
		for e in game.get_level_nodes("enemies"):
			if e == target and is_instance_valid(e) and not e.dead:
				gone = false
		test(gone, "l'épée élimine un ennemi")
	else:
		test(false, "un ennemi est disponible pour le test d'épée")

	var score_before: int = game.score
	await _teleport(Vector2(420, 1000), 10)
	test(game.score == score_before + 1, "une pieèce est ramassée (%d -> %d)" % [score_before, game.score])
	test(not game.switching, "ramasser les pieèces ne termine pas le jeu")

	var keys: Array = game.get_level_nodes("keys")
	await _teleport(keys[0].global_position, 10)
	test(game.keys_collected == 1, "une clé ramassée (clés=%d)" % game.keys_collected)
	test(game.keys_label.text.begins_with("Clés : 1"), "le HUD affiche la clé (texte='%s')" % game.keys_label.text)

	var door: StaticBody2D = game.get_level_nodes("doors")[0]
	await _teleport(door.global_position + Vector2(0, -60), 12)
	test(not door.open, "la porte reste fermée sans les 6 clés")
	test(game.message_label.text.begins_with("Il te faut"), "message de porte verrouillée (texte='%s')" % game.message_label.text)
	await _teleport(Vector2(600, 700), 5)
	while game.keys_collected < game.total_keys:
		var k: Area2D = game.get_level_nodes("keys")[0]
		if is_instance_valid(k):
			k.picked.emit()
		else:
			break
		await wait_physics(2)
	test(game.keys_collected == 6, "les 6 clés ramassées (clés=%d)" % game.keys_collected)
	door._cooldown = 0.0
	await _teleport(door.global_position + Vector2(0, -60), 12)
	test(door.open, "la grande porte s'ouvre avec les 6 clés")

	var heart: Area2D = game.get_level_nodes("hearts")[0]
	await _teleport(heart.global_position, 10)
	test(game.hp_max == 4 and game.hp == 4, "le cœur supplémentaire augmente la vie max (hp=%d/%d)" % [game.hp, game.hp_max])
	test(game.hearts_box.get_child_count() == 4, "le HUD affiche 4 cœurs")

	var flag: Area2D = game.get_level_nodes("flags")[0]
	await _teleport(flag.global_position, 12)
	test(flag.active, "le drapeau s'active au contact")
	test(game.checkpoint.distance_to(flag.global_position) < 60.0, "checkpoint mis à jour au drapeau")

	player.blink_tween.kill()
	player.invulnerable = false
	player.modulate.a = 1.0
	var hp_before: int = game.hp
	var kz: Area2D = game.get_level_nodes("kill_zone")[0]
	player.position = kz.global_position + Vector2(0, -10)
	player.velocity = Vector2.ZERO
	await wait_physics(30)
	test(game.hp == hp_before - 1, "le vide coûte 1 cœur (hp=%d)" % game.hp)
	test(player.global_position.distance_to(game.checkpoint) < 60.0, "respawn au checkpoint")
	player.make_invulnerable(60.0)

	var mid_boss: CharacterBody2D = null
	for b in game.get_level_nodes("boss"):
		if b.boss_name == "Chef Gobou":
			mid_boss = b
			break
	test(mid_boss != null and mid_boss.max_hp == 6, "Chef Gobou a 6 PV (trouve : %s)" % (str(mid_boss.max_hp) if mid_boss else "N/A"))
	if mid_boss:
		for i in 3:
			if is_instance_valid(mid_boss):
				mid_boss.take_hit(2, mid_boss.global_position + Vector2(10, 0))
			await wait_physics(3)
		await wait_physics(30)
		test(game.message_label.text.begins_with("Victoire"), "Gobou vaincu sans finir le jeu (texte='%s')" % game.message_label.text)
		test(not game.switching, "battre un petit boss ne termine pas le jeu")

	var final_boss: CharacterBody2D = null
	for b in game.get_level_nodes("boss"):
		if b.boss_name == "Roi Slime":
			final_boss = b
			break
	if final_boss:
		for i in 6:
			if is_instance_valid(final_boss):
				final_boss.take_hit(2, final_boss.global_position + Vector2(10, 0))
			await wait_physics(3)
		await wait_physics(30)
		test(game.message_label.text.begins_with("LE ROYAUME EST SAUVE"), "victoire finale apres le Roi Slime (texte='%s')" % game.message_label.text)
		test(game.switching, "le jeu se termine apres le boss final")
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
