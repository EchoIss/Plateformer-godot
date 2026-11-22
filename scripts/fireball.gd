extends Area2D

var direction := 1.0
var _life := 1.1

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.x += 520.0 * direction * delta
	_life -= delta
	visual.rotation += 14.0 * delta * direction
	visual.scale = Vector2.ONE * (1.0 + sin(_life * 60.0) * 0.18)
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit(1, global_position)
		_pop()
	elif body is StaticBody2D:
		_pop()

func _pop() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector2(2.0, 2.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)
