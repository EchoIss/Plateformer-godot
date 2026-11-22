extends StaticBody2D

signal touched(door: Node)

@onready var sensor: Area2D = $Sensor
@onready var panel: Polygon2D = $Panel

var open := false
var _cooldown := 0.0

func _ready() -> void:
	sensor.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func _on_body_entered(body: Node2D) -> void:
	if open or _cooldown > 0.0 or not body.is_in_group("player"):
		return
	_cooldown = 1.0
	touched.emit(self)

func open_door() -> void:
	if open:
		return
	open = true
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	sensor.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", 230.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.2, 0.7)
	tween.tween_property(self, "modulate:a", 0.4, 0.7)
