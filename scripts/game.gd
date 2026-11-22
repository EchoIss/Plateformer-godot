extends Node

const MAP: PackedScene = preload("res://scenes/metroid_map.tscn")
const MAX_HP := 3
const COIN_SFX := preload("res://sounds/coin.wav")
const WIN_SFX := preload("res://sounds/win.wav")
const HIT_SFX := preload("res://sounds/hit.wav")
const TRANSFORM_SFX := preload("res://sounds/transform.wav")
const SLAM_SFX := preload("res://sounds/slam.wav")
const KEY_SFX := preload("res://sounds/key.wav")
const DOOR_SFX := preload("res://sounds/door.wav")
const FORM_NAMES := {"knight": "Chevalier", "wizard": "Sorcier"}

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
var hp := MAX_HP
var form := "base"
var switching := false
var game_over := false

@onready var score_label: Label = $HUD/ScoreLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var message_label: Label = $HUD/Message
@onready var keys_label: Label = $HUD/KeysLabel
@onready var hearts: Array = [$HUD/Hearts/Heart1, $HUD/Hearts/Heart2, $HUD/Hearts/Heart3]
@onready var boss_bar: Node2D = $HUD/BossBar
@onready var boss_fill: ColorRect = $HUD/BossBar/Fill

func _ready() -> void:
	load_level(0)

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

	var boss := get_first_level_boss()
	if boss:
		boss.health_changed.connect(_on_boss_health)
		boss.player_hit.connect(_on_entity_hit)
		boss.defeated.connect(_on_boss_defeated)
		boss.slammed.connect(_on_boss_slammed)
		boss_bar.visible = true
		_on_boss_health(boss.hp, boss.MAX_HP)
	else:
		boss_bar.visible = false

	total_keys = get_level_nodes("keys").size()
	_apply_camera_limits()
	level_label.text = "Exploration"
	score = 0
	keys_collected = 0
	coins_shown = false
	_update_label()
	_update_keys_label()
	_update_hearts()

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

func get_first_level_boss() -> Node:
	for boss in get_level_nodes("boss"):
		return boss
	return null

func _on_coin_collected() -> void:
	score += 1
	_play(COIN_SFX)
	_update_label()
	if not coins_shown and coins_in_level > 0 and score >= coins_in_level:
		coins_shown = true
		message_label.text = "Toutes les pi\u00e8ces ramass\u00e9es !"

func _on_orb_picked(kind: String) -> void:
	_play(TRANSFORM_SFX)
	if kind == "dash":
		player.has_dash = true
		message_label.text = "Ru\u00e9e d\u00e9bloqu\u00e9e ! (Maj / C)"
		await get_tree().create_timer(1.5).timeout
		if message_label.text.begins_with("Ru\u00e9e"):
			message_label.text = ""
		return
	form = kind
	player.apply_form(kind)
	if FORM_NAMES.has(kind):
		message_label.text = "Transformation : %s !" % FORM_NAMES[kind]
	await get_tree().create_timer(1.5).timeout
	if not switching and (message_label.text.begins_with("Transformation") or message_label.text.begins_with("Ru\u00e9e")):
		message_label.text = ""

func _on_key_picked() -> void:
	keys_collected += 1
	_play(KEY_SFX)
	_update_keys_label()
	message_label.text = "Cl\u00e9 trouv\u00e9e ! (%d/%d)" % [keys_collected, total_keys]
	await get_tree().create_timer(1.5).timeout
	if message_label.text.begins_with("Cl\u00e9 trouv\u00e9e"):
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
		message_label.text = "La porte s'ouvre ! Le boss t'attend..."
		await get_tree().create_timer(2.0).timeout
		if message_label.text.begins_with("La porte"):
			message_label.text = ""
	else:
		message_label.text = "Il te faut les 3 cl\u00e9s ! (%d/%d)" % [keys_collected, total_keys]

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
	message_label.text = "A\u00efe ! Retour au checkpoint..."
	await get_tree().create_timer(1.0).timeout
	hp = MAX_HP
	_update_hearts()
	player.reset(checkpoint)
	game_over = false
	switching = false

func _on_boss_health(current: int, max_hp: int) -> void:
	boss_fill.offset_right = 2.0 + 296.0 * clampf(float(current) / float(max_hp), 0.0, 1.0)

func _on_boss_slammed(_pos: Vector2) -> void:
	_play(SLAM_SFX)
	_shake()

func _on_boss_defeated() -> void:
	boss_bar.visible = false
	message_label.text = "Victoire ! Le Roi Slime est vaincu \ud83c\udf89"
	_play(WIN_SFX)
	switching = true

func _win() -> void:
	message_label.text = "Gagn\u00e9 ! Bravo \ud83c\udf89"
	_play(WIN_SFX)
	switching = true

func _shake() -> void:
	var tween := create_tween()
	for i in 6:
		tween.tween_property(level, "position", Vector2(randf_range(-9.0, 9.0), randf_range(-6.0, 6.0)), 0.05)
	tween.tween_property(level, "position", Vector2.ZERO, 0.06)

func _update_label() -> void:
	if coins_in_level > 0:
		score_label.text = "Pi\u00e8ces : %d / %d" % [score, coins_in_level]
	else:
		score_label.text = ""

func _update_keys_label() -> void:
	keys_label.text = "Cl\u00e9s : %d / %d" % [keys_collected, total_keys]

func _update_hearts() -> void:
	for i in hearts.size():
		hearts[i].modulate.a = 1.0 if i < hp else 0.15

func _play(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
