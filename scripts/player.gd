extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -480.0
const GRAVITY := 980.0
const MAX_FALL := 1200.0

@onready var visual: Node2D = $Visual

var squash_tween: Tween
var was_on_floor := true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_squash(Vector2(0.6, 1.45))

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	if is_on_floor() and not was_on_floor:
		_squash(Vector2(1.55, 0.45))

	was_on_floor = is_on_floor()

	visual.rotation = lerp_angle(visual.rotation, -direction * 0.25, 12.0 * delta)

func _squash(target: Vector2) -> void:
	if squash_tween:
		squash_tween.kill()
	visual.scale = target
	squash_tween = create_tween()
	squash_tween.tween_property(visual, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
