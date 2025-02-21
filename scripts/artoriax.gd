extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = $"../player"

const SPEED = 100.0
var prev_direction_name = "_left"

func _physics_process(_delta):
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction: Vector2 = (player.global_position - global_position).normalized()
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	prev_direction_name = get_direction_name(direction)
	var new_state = ("run" if direction != Vector2.ZERO else "idle") + prev_direction_name
	change_animation_state(new_state)

func change_animation_state(new_state: String) -> void:
	if sprite.animation == new_state:
		return

	var current_anim = sprite.animation
	var current_frame = sprite.frame
	var total_frames = sprite.sprite_frames.get_frame_count(current_anim)
	var fraction := 0.0
	if total_frames > 0:
		fraction = float(current_frame) / float(total_frames)

	sprite.play(new_state)
	var new_total_frames = sprite.sprite_frames.get_frame_count(new_state)
	sprite.frame = clamp(int(new_total_frames * fraction), 0, new_total_frames - 1)

func get_direction_name(direction: Vector2) -> String:
	var angle = direction.angle()
	if abs(direction.x) < 0.1 and abs(direction.y) < 0.1:
		return prev_direction_name
	elif angle >= -PI/8 and angle < PI/8:
		return "_right"
	elif angle >= PI/8 and angle < 3*PI/8:
		return "_right_down"
	elif angle >= 3*PI/8 and angle < 5*PI/8:
		return "_down"
	elif angle >= 5*PI/8 and angle < 7*PI/8:
		return "_left_down"
	elif angle >= 7*PI/8 or angle < -7*PI/8:
		return "_left"
	elif angle >= -7*PI/8 and angle < -5*PI/8:
		return "_left_up"
	elif angle >= -5*PI/8 and angle < -3*PI/8:
		return "_up"
	elif angle >= -3*PI/8 and angle < -PI/8:
		return "_right_up"
	return prev_direction_name
