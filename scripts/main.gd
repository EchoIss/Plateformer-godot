extends Node2D

const START_POSITION := Vector2(120, 520)

var score := 0
var coins_total := 0

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $HUD/ScoreLabel

func _ready() -> void:
	coins_total = get_tree().get_nodes_in_group("coins").size()
	_update_label()

func _on_coin_collected() -> void:
	score += 1
	_update_label()
	if score >= coins_total:
		score_label.text = "Gagné ! Toutes les pièces ramassées 🎉"

func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player.position = START_POSITION
		player.velocity = Vector2.ZERO
		player._squash(Vector2(1.6, 0.4))

func _update_label() -> void:
	score_label.text = "Pièces : %d / %d" % [score, coins_total]
