extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -480.0
const GRAVITY := 980.0
const MAX_FALL := 1200.0
const MAX_JUMPS := 2
const BOUNCE_VELOCITY := -420.0

@onready var visual: Node2D = $Visual
@onready var body_node: Node2D = $Visual/Body
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var double_jump_sound: AudioStreamPlayer = $DoubleJumpSound

var squash_tween: Tween
var spin_tween: Tween
var jumps_left := MAX_JUMPS
var was_on_floor := true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

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

	move_and_slide()

	if is_on_floor():
		jumps_left = MAX_JUMPS
		if not was_on_floor:
			_squash(Vector2(1.55, 0.45))
	elif was_on_floor and jumps_left == MAX_JUMPS:
		jumps_left = MAX_JUMPS - 1

	was_on_floor = is_on_floor()

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

func _squash(target: Vector2) -> void:
	if squash_tween:
		squash_tween.kill()
	visual.scale = target
	squash_tween = create_tween()
	squash_tween.tween_property(visual, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _spin() -> void:
	if spin_tween:
		spin_tween.kill()
	body_node.rotation = 0.0
	spin_tween = create_tween()
	spin_tween.tween_property(body_node, "rotation", TAU, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
