extends Area2D

signal picked(kind: String)

@export var kind := "knight"

@onready var visual: Polygon2D = $Visual

var _time := randf() * TAU

const ORB_COLORS := {
	"knight": Color(0.3, 0.7, 1.0),
	"wizard": Color(0.8, 0.35, 1.0),
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visual.color = ORB_COLORS.get(kind, Color.WHITE)

func _process(delta: float) -> void:
	_time += delta * 5.0
	visual.scale = Vector2.ONE * (1.0 + sin(_time) * 0.25)
	visual.rotation = sin(_time * 0.5) * 0.3

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		picked.emit(kind)
		set_deferred("monitoring", false)
		set_process(false)
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector2(2.6, 2.6), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
