extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = $"../player"

# Enemy state definitions.
enum State { IDLE, WALK, RUN, ATTACK_SWIPE, ATTACK_JUMP }
const WALK_SPEED = 120.0
const RUN_SPEED = 180.0
const JUMP_SPEED = 250.0

var current_state: State = State.IDLE
var input_direction: Vector2 = Vector2.ZERO
var last_direction: String = "_left"

# Updates movement based on input and current state.
func _physics_process(_delta: float) -> void:
	if current_state == State.ATTACK_SWIPE:
		velocity = Vector2.ZERO
	elif current_state == State.ATTACK_JUMP:
		var progress: float = get_animation_progress()
		if progress > 0.1 and progress < 0.45:
			velocity = input_direction * JUMP_SPEED
		else:
			velocity = Vector2.ZERO
	else:
		# Get movement input.
		input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input_direction != Vector2.ZERO:
			if Input.is_action_pressed("shift"):
				current_state = State.RUN
				velocity = input_direction * RUN_SPEED
			else:
				current_state = State.WALK
				velocity = input_direction * WALK_SPEED
		else:
			current_state = State.IDLE
			velocity = Vector2.ZERO
	move_and_slide()

# Updates animation and handles attack input.
func _process(_delta: float) -> void:
	# Block input changes during an attack.
	if current_state == State.ATTACK_SWIPE or current_state == State.ATTACK_JUMP:
		return

	# Attack inputs.
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK_SWIPE
		sprite.play("attack_swipe" + get_direction_name())
		return
	elif Input.is_action_just_pressed("ui_accept") and input_direction != Vector2.ZERO:
		current_state = State.ATTACK_JUMP
		sprite.play("attack_jump" + get_direction_name())
		return

	# Update animation based on movement state.
	var anim_name: String = ""
	match current_state:
		State.IDLE:
			anim_name = "idle" + get_direction_name()
		State.WALK:
			anim_name = "walk" + get_direction_name()
		State.RUN:
			anim_name = "run" + get_direction_name()
		_:
			return
	smooth_transition(anim_name)

# Resets state to idle when an attack animation finishes.
func _on_animated_sprite_2d_animation_finished() -> void:
	if current_state in [State.ATTACK_SWIPE, State.ATTACK_JUMP]:
		current_state = State.IDLE

# Smoothly transitions to a new animation while preserving frame progress.
func smooth_transition(new_state: String) -> void:
	if sprite.animation == new_state:
		return
	var progress: float = get_animation_progress()
	sprite.play(new_state)
	var new_total_frames: int = sprite.sprite_frames.get_frame_count(new_state)
	sprite.frame = clamp(int(new_total_frames * progress), 0, new_total_frames - 1)

# Returns a direction suffix based on input angle, preserving the last known direction.
func get_direction_name() -> String:
	if input_direction.length() < 0.1:
		return last_direction
	var angle: float = input_direction.angle()
	if angle >= -PI/8 and angle < PI/8:
		last_direction = "_right"
	elif angle >= PI/8 and angle < 3 * PI/8:
		last_direction = "_right_down"
	elif angle >= 3 * PI/8 and angle < 5 * PI/8:
		last_direction = "_down"
	elif angle >= 5 * PI/8 and angle < 7 * PI/8:
		last_direction = "_left_down"
	elif angle >= 7 * PI/8 or angle < -7 * PI/8:
		last_direction = "_left"
	elif angle >= -7 * PI/8 and angle < -5 * PI/8:
		last_direction = "_left_up"
	elif angle >= -5 * PI/8 and angle < -3 * PI/8:
		last_direction = "_up"
	elif angle >= -3 * PI/8 and angle < -PI/8:
		last_direction = "_right_up"
	return last_direction

# Calculates the current animation progress (0.0 to 1.0).
func get_animation_progress() -> float:
	var total_frames: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	return float(sprite.frame) / total_frames
