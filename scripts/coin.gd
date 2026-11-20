extends Area2D

signal collected

@onready var visual: Polygon2D = $Visual

var _time := randf() * TAU

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta * 4.0
	visual.scale.x = cos(_time)
	visual.scale.y = 1.0 + sin(_time * 0.5) * 0.12
	visual.position.y = sin(_time * 0.25) * 4.0

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit()
		set_process(false)
		set_deferred("monitoring", false)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(visual, "scale", Vector2(2.6, 2.6), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(queue_free)
