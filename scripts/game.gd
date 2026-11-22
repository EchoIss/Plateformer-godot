extends Node

const MAP: PackedScene = preload("res://scenes/world.tscn")
const HP_START := 3
const COIN_SFX := preload("res://sounds/coin.wav")
const WIN_SFX := preload("res://sounds/win.wav")
const HIT_SFX := preload("res://sounds/hit.wav")
const TRANSFORM_SFX := preload("res://sounds/transform.wav")
const SLAM_SFX := preload("res://sounds/slam.wav")
const KEY_SFX := preload("res://sounds/key.wav")
const DOOR_SFX := preload("res://sounds/door.wav")
const FORM_NAMES := {"knight": "Chevalier", "wizard": "Sorcier"}
const ZONES: Array = [
	[0, "Prairie de l'Aube"],
	[1700, "Forêt des Mille Terrasses"],
	[3520, "Le Gouffre"],
	[4160, "Ruines Oubliées"],
	[5330, "Salle du Trône"],
]
const HEART_COLOR := Color(0.85, 0.15, 0.25, 1)

var level: Node = null
var player: CharacterBody2D
var player_start := Vector2.ZERO
var checkpoint := Vector2.ZERO
var current_level := 0
var score := 0
var coins_in_level := 0
var coins_shown := false
var keys_collected := 0
var total_keys := 0
var hp := HP_START
var hp_max := HP_START
var form := "base"
var switching := false
var game_over := false
var current_zone := ""

@onready var score_label: Label = $HUD/ScoreLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var message_label: Label = $HUD/Message
@onready var keys_label: Label = $HUD/KeysLabel
@onready var zone_label: Label = $HUD/ZoneLabel
@onready var hearts_box: Node2D = $HUD/Hearts
@onready var boss_bar: Node2D = $HUD/BossBar
@onready var boss_fill: ColorRect = $HUD/BossBar/Fill
@onready var boss_name_label: Label = $HUD/BossBar/NameLabel

func _ready() -> void:
	load_level(0)
	message_label.text = "Explore les 5 régions, trouve les 6 clés... et bats les 3 boss !"
	var t := create_tween()
	t.tween_interval(3.5)
	t.tween_property(message_label, "modulate:a", 0.0, 0.6)

func _process(_delta: float) -> void:
	_update_zone()
	_update_boss_bar_security()

func _update_boss_bar_security() -> void:
	if not is_instance_valid(player) or not is_instance_valid(level):
		return
	for boss in get_level_nodes("boss"):
		if is_instance_valid(boss) and not boss.dead and player.global_position.distance_to(boss.global_position) < 700.0:
			return
	boss_bar.visible = false

func load_level(index: int) -> void:
	current_level = index
	switching = false
	game_over = false
	message_label.text = ""
	if level:
		level.queue_free()
	level = MAP.instantiate()
	add_child(level)
	move_child(level, 0)
	level.position = Vector2.ZERO

	player = level.get_node("Player")
	player_start = player.position
	checkpoint = player_start
	player.apply_form(form)
	hp = hp_max
	_build_hearts()
	_update_hearts()

	var coins := get_level_nodes("coins")
	coins_in_level = coins.size()
	for coin in coins:
		coin.collected.connect(_on_coin_collected)
	for enemy in get_level_nodes("enemies"):
		enemy.player_hit.connect(_on_entity_hit)
	for orb in get_level_nodes("orbs"):
		orb.picked.connect(_on_orb_picked)
	for zone in get_level_nodes("kill_zone"):
		zone.body_entered.connect(_on_kill_zone_body_entered)
	for key in get_level_nodes("keys"):
		key.picked.connect(_on_key_picked)
	for door in get_level_nodes("doors"):
		door.touched.connect(_on_door_touched)
	for flag in get_level_nodes("flags"):
		flag.activated.connect(_on_flag_activated)
	for heart in get_level_nodes("hearts"):
		heart.picked.connect(_on_heart_picked)
	for boss in get_level_nodes("boss"):
		boss.health_changed.connect(_on_boss_health.bind(boss))
		boss.player_hit.connect(_on_entity_hit)
		boss.defeated.connect(_on_boss_defeated.bind(boss))
		boss.slammed.connect(_on_boss_slammed)

	boss_bar.visible = false
	total_keys = get_level_nodes("keys").size()
	_apply_camera_limits()
	level_label.text = "Exploration"
	score = 0
	keys_collected = 0
	coins_shown = false
	current_zone = ""
	_update_label()
	_update_keys_label()

func _apply_camera_limits() -> void:
	if not level or not player:
		return
	player.camera.limit_left = int(level.get_meta("camera_left", 0))
	player.camera.limit_top = int(level.get_meta("camera_top", 0))
	player.camera.limit_right = int(level.get_meta("camera_right", 1152))
	player.camera.limit_bottom = int(level.get_meta("camera_bottom", 648))
	player.camera.reset_smoothing()

func get_level_nodes(group_name: String) -> Array:
	var result := []
	for node in get_tree().get_nodes_in_group(group_name):
		if is_instance_valid(node) and level.is_ancestor_of(node):
			result.append(node)
	return result

func _update_zone() -> void:
	if not level or not player or switching:
		return
	var zone := ""
	for entry in ZONES:
		if player.position.x >= float(entry[0]):
			zone = entry[1]
	if zone != "" and zone != current_zone:
		current_zone = zone
		zone_label.text = "~ %s ~" % zone
		zone_label.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(2.0)
		tween.tween_property(zone_label, "modulate:a", 0.0, 0.8)

func _on_coin_collected() -> void:
	score += 1
	_play(COIN_SFX)
	_update_label()
	if not coins_shown and coins_in_level > 0 and score >= coins_in_level:
		coins_shown = true
		message_label.text = "Toutes les pièces ramassées ! Bravo l'explorateur !"
		_play(WIN_SFX)

func _on_orb_picked(kind: String) -> void:
	_play(TRANSFORM_SFX)
	if kind == "dash":
		player.has_dash = true
		message_label.text = "Ruée débloquée ! (Maj / C)"
		await get_tree().create_timer(1.5).timeout
		if message_label.text.begins_with("Ruée"):
			message_label.text = ""
		return
	if kind == "walljump":
		player.has_walljump = true
		message_label.text = "Saut mural débloqué ! (glisse sur un mur et saute)"
		await get_tree().create_timer(2.0).timeout
		if message_label.text.begins_with("Saut mural"):
			message_label.text = ""
		return
	form = kind
	player.apply_form(kind)
	if FORM_NAMES.has(kind):
		message_label.text = "Transformation : %s !" % FORM_NAMES[kind]
	await get_tree().create_timer(1.5).timeout
	if message_label.text.begins_with("Transformation"):
		message_label.text = ""

func _on_key_picked() -> void:
	keys_collected += 1
	_play(KEY_SFX)
	_update_keys_label()
	message_label.text = "Clé trouvée ! (%d/%d)" % [keys_collected, total_keys]
	await get_tree().create_timer(1.5).timeout
	if message_label.text.begins_with("Clé trouvée"):
		message_label.text = ""

func _on_heart_picked() -> void:
	hp_max += 1
	hp = hp_max
	_build_hearts()
	_update_hearts()
	_play(TRANSFORM_SFX)
	message_label.text = "Cœur supplémentaire ! Vie max : %d" % hp_max
	await get_tree().create_timer(2.0).timeout
	if message_label.text.begins_with("Cœur supplémentaire"):
		message_label.text = ""

func _on_flag_activated(_pos: Vector2) -> void:
	checkpoint = player.position
	_play(TRANSFORM_SFX)
	message_label.text = "Point de sauvegarde !"
	await get_tree().create_timer(1.5).timeout
	if message_label.text.begins_with("Point de sauvegarde"):
		message_label.text = ""

func _on_door_touched(door: Node) -> void:
	if door.open:
		return
	if keys_collected >= total_keys:
		door.open_door()
		_play(DOOR_SFX)
		message_label.text = "La grande porte s'ouvre ! Le Roi Slime t'attend..."
		await get_tree().create_timer(2.0).timeout
		if message_label.text.begins_with("La grande porte"):
			message_label.text = ""
	else:
		message_label.text = "Il te faut les %d clés d’abord ! (%d/%d)" % [total_keys, keys_collected, total_keys]

func _on_entity_hit(from_pos: Vector2 = Vector2.ZERO) -> void:
	_damage_player(from_pos)

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_damage_player(Vector2.ZERO)
		player.reset(checkpoint)
		player.make_invulnerable(2.0)

func _damage_player(from_pos: Vector2) -> void:
	if player.invulnerable or switching or game_over:
		return
	hp -= 1
	_update_hearts()
	_play(HIT_SFX)
	if hp <= 0:
		_game_over()
	elif from_pos == Vector2.ZERO:
		player.reset(checkpoint)
	else:
		var away := signf(player.global_position.x - from_pos.x)
		if away == 0.0:
			away = 1.0
		player.velocity = Vector2(away * 260.0, -300.0)
		player.make_invulnerable(1.5)

func _game_over() -> void:
	if game_over or switching:
		return
	game_over = true
	switching = true
	message_label.text = "Aïe ! Retour au checkpoint..."
	await get_tree().create_timer(1.0).timeout
	hp = hp_max
	_update_hearts()
	player.reset(checkpoint)
	game_over = false
	switching = false

func _on_boss_health(current: int, max_hp: int, boss: Node) -> void:
	if not is_instance_valid(boss) or not is_instance_valid(player):
		return
	var near := player.global_position.distance_to(boss.global_position) < 1100.0
	boss_bar.visible = near and not boss.dead
	boss_name_label.text = boss.boss_name
	boss_fill.offset_right = 2.0 + 296.0 * clampf(float(current) / float(max_hp), 0.0, 1.0)

func _on_boss_slammed(_pos: Vector2) -> void:
	_play(SLAM_SFX)
	_shake()

func _on_boss_defeated(boss: Node) -> void:
	_play(WIN_SFX)
	if boss.final:
		boss_bar.visible = false
		switching = true
		message_label.text = "LE ROYAUME EST SAUVE ! %s est vaincu, bravo !" % boss.boss_name
	else:
		message_label.text = "Victoire ! %s est vaincu !" % boss.boss_name

func _shake() -> void:
	var tween := create_tween()
	for i in 6:
		tween.tween_property(level, "position", Vector2(randf_range(-9.0, 9.0), randf_range(-6.0, 6.0)), 0.05)
	tween.tween_property(level, "position", Vector2.ZERO, 0.06)

func _update_label() -> void:
	if coins_in_level > 0:
		score_label.text = "Pièces : %d / %d" % [score, coins_in_level]
	else:
		score_label.text = ""

func _update_keys_label() -> void:
	keys_label.text = "Clés : %d / %d" % [keys_collected, total_keys]

func _update_hearts() -> void:
	var i := 0
	for heart in hearts_box.get_children():
		heart.modulate.a = 1.0 if i < hp else 0.15
		i += 1

func _build_hearts() -> void:
	for child in hearts_box.get_children():
		child.queue_free()
	for i in hp_max:
		var rect := ColorRect.new()
		rect.offset_left = 20.0 + i * 30.0
		rect.offset_top = 64.0
		rect.offset_right = 42.0 + i * 30.0
		rect.offset_bottom = 86.0
		rect.color = HEART_COLOR
		var glow := ColorRect.new()
		glow.offset_left = 2.0
		glow.offset_top = 2.0
		glow.offset_right = 5.0
		glow.offset_bottom = 6.0
		glow.color = Color(1, 1, 1, 0.6)
		rect.add_child(glow)
		hearts_box.add_child(rect)

func _play(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
