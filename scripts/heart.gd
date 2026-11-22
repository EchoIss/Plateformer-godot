extends Area2D

signal picked

@onready var visual: Polygon2D = $Visual

var _time := randf() * TAU

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta * 4.0
	visual.scale = Vector2.ONE * (1.0 + sin(_time) * 0.2)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	picked.emit()
	set_deferred("monitoring", false)
	set_process(false)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(2.4, 2.4), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
