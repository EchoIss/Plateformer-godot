extends Area2D

signal picked

@onready var visual: Polygon2D = $Visual

var _time := randf() * TAU

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta * 3.0
	visual.position.y = sin(_time) * 5.0
	visual.rotation = sin(_time * 0.6) * 0.25

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		picked.emit()
		set_deferred("monitoring", false)
		set_process(false)
		var tween := create_tween()
		tween.tween_property(visual, "position:y", visual.position.y - 40.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
