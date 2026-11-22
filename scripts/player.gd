extends CharacterBody2D

signal form_changed(kind: String)

const SPEED := 300.0
const JUMP_VELOCITY := -480.0
const GRAVITY := 980.0
const MAX_FALL := 1200.0
const MAX_JUMPS := 2
const BOUNCE_VELOCITY := -420.0
const FIREBALL := preload("res://scenes/fireball.tscn")
const FORM_COLORS := {
	"base": Color(0.95, 0.35, 0.4),
	"knight": Color(0.4, 0.6, 1.0),
	"wizard": Color(0.7, 0.35, 0.9),
}

@onready var visual: Node2D = $Visual
@onready var spin: Node2D = $Visual/Spin
@onready var body_node: ColorRect = $Visual/Spin/Body
@onready var weapon: Node2D = $Visual/Spin/Weapon
@onready var weapon_hit: Area2D = $Visual/Spin/Weapon/WeaponHit
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var double_jump_sound: AudioStreamPlayer = $DoubleJumpSound
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var cast_sound: AudioStreamPlayer = $CastSound

var squash_tween: Tween
var spin_tween: Tween
var weapon_tween: Tween
var blink_tween: Tween
var jumps_left := MAX_JUMPS
var was_on_floor := true
var form := "base"
var facing := 1.0
var attack_cooldown := 0.0
var attack_time := 0.0
var attacked := {}
var invulnerable := false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)

	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		if was_on_floor:
			jump_sound.play()
			_squash(Vector2(0.6, 1.45))
		else:
			double_jump_sound.play()
			_squash(Vector2(0.5, 1.5))
			_spin()

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if attack_time > 0.0:
		attack_time -= delta
		for body in weapon_hit.get_overlapping_bodies():
			if body.has_method("take_hit") and not attacked.has(body):
				attacked[body] = true
				body.take_hit(1, global_position)
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		if form == "knight":
			_slash()
		elif form == "wizard":
			_cast()

	move_and_slide()

	if is_on_floor():
		jumps_left = MAX_JUMPS
		if not was_on_floor:
			_squash(Vector2(1.55, 0.45))
	elif was_on_floor and jumps_left == MAX_JUMPS:
		jumps_left = MAX_JUMPS - 1

	was_on_floor = is_on_floor()

	if direction:
		facing = signf(direction)
		spin.scale.x = facing

	visual.rotation = lerp_angle(visual.rotation, -direction * 0.25, 12.0 * delta)

func bounce(strength: float = BOUNCE_VELOCITY) -> void:
	velocity.y = strength
	jumps_left = MAX_JUMPS - 1
	_squash(Vector2(0.6, 1.4))

func reset(pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	jumps_left = MAX_JUMPS
	_squash(Vector2(1.6, 0.4))

func apply_form(kind: String) -> void:
	form = kind
	body_node.color = FORM_COLORS.get(kind, FORM_COLORS["base"])
	if form != "knight" and weapon_tween:
		weapon_tween.kill()
		weapon.visible = false
	_squash(Vector2(1.4, 0.6))
	form_changed.emit(kind)

func make_invulnerable(duration: float) -> void:
	invulnerable = true
	if blink_tween:
		blink_tween.kill()
	blink_tween = create_tween()
	for i in int(duration / 0.15):
		blink_tween.tween_property(self, "modulate:a", 0.25, 0.07)
		blink_tween.tween_property(self, "modulate:a", 1.0, 0.08)
	blink_tween.tween_callback(func() -> void:
		invulnerable = false
		modulate.a = 1.0)

func _slash() -> void:
	attack_cooldown = 0.35
	attack_time = 0.14
	attacked.clear()
	slash_sound.play()
	weapon.visible = true
	weapon.modulate.a = 1.0
	weapon.rotation = -1.9
	if weapon_tween:
		weapon_tween.kill()
	weapon_tween = create_tween()
	weapon_tween.tween_property(weapon, "rotation", 1.3, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	weapon_tween.tween_property(weapon, "modulate:a", 0.0, 0.15)
	weapon_tween.tween_callback(func() -> void: weapon.visible = false)
	_squash(Vector2(0.8, 1.2))

func _cast() -> void:
	attack_cooldown = 0.5
	cast_sound.play()
	var fireball := FIREBALL.instantiate()
	fireball.direction = facing
	get_parent().add_child(fireball)
	fireball.global_position = global_position + Vector2(facing * 18.0, -6.0)
	_squash(Vector2(1.2, 0.8))

func _spin() -> void:
	if spin_tween:
		spin_tween.kill()
	spin.rotation = 0.0
	spin_tween = create_tween()
	spin_tween.tween_property(spin, "rotation", TAU, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _squash(target: Vector2) -> void:
	if squash_tween:
		squash_tween.kill()
	visual.scale = target
	squash_tween = create_tween()
	squash_tween.tween_property(visual, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
