extends CharacterBody2D

const SPEED := 80.0
const GRAVITY := 980.0

signal player_hit(from_pos: Vector2)

@onready var visual: Node2D = $Visual
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var hitbox: Area2D = $Hitbox
@onready var stomp_sound: AudioStreamPlayer = $StompSound

var hp := 1
var direction := -1.0
var dead := false
var hurt_cooldown := 0.0
var _time := randf() * TAU

func _physics_process(delta: float) -> void:
	if dead:
		return
	_time += delta
	visual.scale.y = 1.0 + sin(_time * 8.0) * 0.08

	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 1200.0)
	else:
		velocity.y = 0.0
		if not edge_ray.is_colliding():
			_turn()

	velocity.x = direction * SPEED
	move_and_slide()

	if is_on_wall():
		_turn()

	if hurt_cooldown > 0.0:
		hurt_cooldown -= delta
		return

	for body in hitbox.get_overlapping_bodies():
		if body == self or not body is CharacterBody2D:
			continue
		if body.global_position.y < global_position.y - 16.0:
			_die()
			body.bounce()
			break
		else:
			player_hit.emit(global_position)
			hurt_cooldown = 0.6
			break

func take_hit(damage: int, from_pos: Vector2) -> void:
	if dead:
		return
	hp -= damage
	velocity.x = signf(global_position.x - from_pos.x) * 220.0
	velocity.y = -160.0
	_flash()
	if hp <= 0:
		_die()

func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(8.0, 8.0, 8.0, 1.0), 0.05)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.2)

func _turn() -> void:
	direction = -direction
	edge_ray.position.x = 16.0 * direction

func _die() -> void:
	dead = true
	stomp_sound.play()
	hitbox.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.6, 0.12), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.4)
	tween.tween_callback(queue_free)
