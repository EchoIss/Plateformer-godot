extends CharacterBody2D

signal health_changed(current: int, max_hp: int)
signal player_hit(from_pos: Vector2)
signal slammed(pos: Vector2)
signal defeated

const GRAVITY := 1400.0
const MAX_HP := 8
const ENEMY := preload("res://scenes/enemy.tscn")

@onready var visual: Node2D = $Visual
@onready var hitbox: Area2D = $Hitbox
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var slam_sound: AudioStreamPlayer = $SlamSound

var hp := MAX_HP
var dead := false
var slamming := false
var was_on_floor := true
var jump_cooldown := 1.5
var slam_count := 0
var _time := 0.0
var _contact_cooldown := 0.0

func _physics_process(delta: float) -> void:
	if dead:
		return
	_time += delta
	visual.scale = Vector2(1.0 + sin(_time * 3.0) * 0.05, 1.0 + sin(_time * 3.0 + 0.4) * 0.05)

	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 1400.0)
	else:
		velocity.y = 0.0
		if slamming:
			_do_slam()
		else:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)

	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player and is_on_floor() and not slamming:
		jump_cooldown -= delta
		if jump_cooldown <= 0.0:
			var f := signf(player.global_position.x - global_position.x)
			velocity.y = -750.0
			velocity.x = f * (240.0 if hp > MAX_HP / 2 else 330.0)
			slamming = true

	move_and_slide()
	was_on_floor = is_on_floor()

	_contact_cooldown = maxf(_contact_cooldown - delta, 0.0)
	if _contact_cooldown <= 0.0:
		for body in hitbox.get_overlapping_bodies():
			if not body is CharacterBody2D or not body.is_in_group("player"):
				continue
			if body.global_position.y < global_position.y - 30.0:
				take_hit(2, global_position)
				if body.has_method("bounce"):
					body.bounce(-520.0)
			else:
				player_hit.emit(global_position)
			_contact_cooldown = 0.5
			break

func _do_slam() -> void:
	slamming = false
	slam_sound.play()
	slammed.emit(global_position)
	slam_count += 1
	jump_cooldown = 1.4 if hp > MAX_HP / 2 else 0.9
	if hp <= MAX_HP / 2 and slam_count % 2 == 0:
		_spawn_minion()

func _spawn_minion() -> void:
	var blob := ENEMY.instantiate()
	blob.direction = 1.0 if slam_count % 4 == 0 else -1.0
	get_parent().add_child(blob)
	blob.global_position = global_position + Vector2(60.0 * (1.0 if slam_count % 4 == 0 else -1.0), -30.0)

func take_hit(damage: int, from_pos: Vector2) -> void:
	if dead:
		return
	hp -= damage
	hit_sound.play()
	health_changed.emit(hp, MAX_HP)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(8.0, 8.0, 8.0, 1.0), 0.06)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.25)
	if hp <= 0:
		_die()

func _die() -> void:
	dead = true
	defeated.emit()
	velocity = Vector2.ZERO
	hitbox.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.9, 0.12), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	tween.tween_callback(queue_free)
