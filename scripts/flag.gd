extends Area2D

signal activated(pos: Vector2)

@onready var banner: Polygon2D = $Banner

var active := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if active or not body.is_in_group("player"):
		return
	active = true
	banner.color = Color(0.3, 0.9, 0.4)
	activated.emit(global_position)
	var tween := create_tween()
	tween.tween_property(banner, "position:y", -110.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var shine := create_tween()
	shine.tween_property(banner, "scale", Vector2(1.25, 1.25), 0.12)
	shine.tween_property(banner, "scale", Vector2.ONE, 0.15)
