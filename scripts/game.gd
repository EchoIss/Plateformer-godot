extends Node

const LEVELS: Array = [
	preload("res://scenes/level_1.tscn"),
	preload("res://scenes/level_2.tscn"),
]
const COIN_SFX := preload("res://sounds/coin.wav")
const WIN_SFX := preload("res://sounds/win.wav")
const HIT_SFX := preload("res://sounds/hit.wav")

var level: Node = null
var player: CharacterBody2D
var player_start := Vector2.ZERO
var current_level := 0
var score := 0
var coins_in_level := 0
var switching := false

@onready var score_label: Label = $HUD/ScoreLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var message_label: Label = $HUD/Message

func _ready() -> void:
	load_level(0)

func load_level(index: int) -> void:
	current_level = index
	switching = false
	message_label.text = ""
	if level:
		level.queue_free()
	level = LEVELS[index].instantiate()
	add_child(level)
	move_child(level, 0)

	player = level.get_node("Player")
	player_start = player.position

	var coins := get_level_coins()
	coins_in_level = coins.size()
	for coin in coins:
		coin.collected.connect(_on_coin_collected)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if level.is_ancestor_of(enemy):
			enemy.player_hit.connect(_on_player_hit)
	for zone in get_tree().get_nodes_in_group("kill_zone"):
		if level.is_ancestor_of(zone):
			zone.body_entered.connect(_on_kill_zone_body_entered)

	level_label.text = "Niveau %d" % (index + 1)
	_update_label()

func get_level_coins() -> Array:
	var result := []
	for coin in get_tree().get_nodes_in_group("coins"):
		if level.is_ancestor_of(coin):
			result.append(coin)
	return result

func _on_coin_collected() -> void:
	score += 1
	_play(COIN_SFX)
	_update_label()
	if switching:
		return
	if score >= coins_in_level:
		score = 0
		if current_level + 1 < LEVELS.size():
			_switch_to(current_level + 1)
		else:
			message_label.text = "Gagné ! Bravo 🎉"
			_play(WIN_SFX)
			switching = true

func _switch_to(index: int) -> void:
	switching = true
	message_label.text = "Niveau terminé !"
	await get_tree().create_timer(1.2).timeout
	load_level(index)

func _on_player_hit() -> void:
	_play(HIT_SFX)
	player.reset(player_start)

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_play(HIT_SFX)
		player.reset(player_start)

func _update_label() -> void:
	score_label.text = "Pièces : %d / %d" % [score, coins_in_level]

func _play(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
