extends CharacterBody2D

@onready var game_manager: Node = %GameManager
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = $"../player"

# Enemy state definitions.
enum State { IDLE, WALK, RUN, ATTACK_SWIPE, ATTACK_JUMP, DEATH }
const WALK_SPEED = 100.0
const RUN_SPEED = 200
const JUMP_SPEED = 250.0

# AI parameters.
const DETECTION_RANGE = 600.0
const ATTACK_RANGE = 200.0
const DECISION_INTERVAL = 1.5
const JUMP_DISTANCE = 150.0

var health = 100
var current_state: State = State.IDLE
var input_direction: Vector2 = Vector2.ZERO
var last_direction: String = "_left"
# attack_directions is updated via hitbox signals.
var attack_directions := []
var can_damage_player = true

var decision_timer: float = 0.0

# ––– PHYSICS PROCESS –––
func _physics_process(delta: float) -> void:
	# Always update the direction toward the player.
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	
	if current_state == State.DEATH:
		velocity = Vector2.ZERO
	elif current_state == State.ATTACK_SWIPE:
		velocity = Vector2.ZERO
	elif current_state == State.ATTACK_JUMP:
		var progress: float = get_animation_progress()
		if progress > 0.1 and progress < 0.45:
			velocity = input_direction * JUMP_SPEED
		else:
			velocity = Vector2.ZERO
	else:
		input_direction = to_player.normalized() if dist > 0 else Vector2.ZERO
		# Not attacking: choose movement based on distance.
		if dist > DETECTION_RANGE:
			current_state = State.IDLE
			velocity = Vector2.ZERO
		elif dist > ATTACK_RANGE:
			current_state = State.RUN
			velocity = input_direction * RUN_SPEED
		else:
			decision_timer -= delta
			if decision_timer <= 0.0:
				current_state = decide_next_action(dist)
				decision_timer = DECISION_INTERVAL
			# In WALK state, move toward the player.
			if current_state == State.WALK:
				velocity = input_direction * WALK_SPEED
			else:
				velocity = Vector2.ZERO
	move_and_slide()

# ––– DECISION MAKING –––
func decide_next_action(dist: float) -> State:
	# Randomly choose an action when within attack range:
	# 40% chance to keep walking, 30% chance for a jump attack, 30% chance for a swipe attack.
	var RNG := randf()
	if RNG < 0.4:
		return State.WALK
	elif RNG < 0.7:
		# Only use jump attack if the player is far enough.
		if dist >= JUMP_DISTANCE:
			sprite.play("attack_jump" + get_direction_name())
			return State.ATTACK_JUMP
		else:
			sprite.play("attack_swipe" + get_direction_name())
			return State.ATTACK_SWIPE
	else:
		sprite.play("attack_swipe" + get_direction_name())
		return State.ATTACK_SWIPE

# ––– PROCESS (ANIMATION & DAMAGE CHECK) –––
func _process(_delta: float) -> void:
	# Check for death first.
	if health <= 0:
		if current_state != State.DEATH:
			sprite.play("death_left")
			current_state = State.DEATH
		return

	# While attacking, lock other inputs but check if damage should be applied.
	if current_state == State.ATTACK_SWIPE or current_state == State.ATTACK_JUMP:
		if can_damage_player:
			if last_direction in attack_directions:
				var progress = get_animation_progress()
				if progress > 0.40 and progress < 0.60:
					game_manager.on_player_hit()
					can_damage_player = false
		return

	# (Optional manual attack override for testing.)
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

# ––– ANIMATION FINISH CALLBACK –––
func _on_animated_sprite_2d_animation_finished() -> void:
	if current_state == State.DEATH:
		return
	can_damage_player = true
	if current_state == State.ATTACK_SWIPE or current_state == State.ATTACK_JUMP:
		current_state = State.IDLE

# ––– SMOOTH TRANSITION –––
func smooth_transition(new_state: String) -> void:
	if sprite.animation == new_state:
		return
	var progress: float = get_animation_progress()
	sprite.play(new_state)
	var new_total_frames: int = sprite.sprite_frames.get_frame_count(new_state)
	sprite.frame = clamp(int(new_total_frames * progress), 0, new_total_frames - 1)

# ––– DIRECTION & ANIMATION PROGRESS –––
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

func get_animation_progress() -> float:
	var total_frames: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	return float(sprite.frame) / total_frames

# ––– ATTACK HITBOX SIGNALS –––
func _on_hitbox_jump_down_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_down")
func _on_hitbox_jump_down_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_down")
func _on_hitbox_jump_up_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_up")
func _on_hitbox_jump_up_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_up")
func _on_hitbox_jump_left_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_left")
func _on_hitbox_jump_left_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_left")
func _on_hitbox_jump_right_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_right")
func _on_hitbox_jump_right_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_right")
func _on_hitbox_jump_right_up_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_right_up")
func _on_hitbox_jump_right_up_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_right_up")
func _on_hitbox_jump_right_down_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_right_down")
func _on_hitbox_jump_right_down_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_right_down")
func _on_hitbox_jump_left_up_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_left_up")
func _on_hitbox_jump_left_up_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_left_up")
func _on_hitbox_jump_left_down_body_entered(body: Node2D) -> void:
	if body == player:
		attack_directions.append("_left_down")
func _on_hitbox_jump_left_down_body_exited(body: Node2D) -> void:
	if body == player:
		attack_directions.erase("_left_down")
