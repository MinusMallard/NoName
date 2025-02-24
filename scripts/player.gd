extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var game_manager: Node = %GameManager
@onready var artoriax: CharacterBody2D = $"../Artoriax"

# Player state definitions.
enum State { IDLE, WALK, RUN, ATTACK, ROLL, DEATH }
const WALK_SPEED = 150.0
const RUN_SPEED = 250.0
const ROLL_SPEED = 300.0

# Stamina settings.
var stamina: float = 100.0
const RUN_STAMINA_COST : float = 0.5
const MAX_STAMINA: float = 100.0
const ROLL_STAMINA_COST: float = 20.0
const ATTACK_STAMINA_COST: float = 20.0
const STAMINA_REGEN: float = 10.0

var health = 100
var current_state: State = State.IDLE
var input_direction: Vector2 = Vector2.ZERO
var last_direction: String = "_right"

var is_invincible = false
var can_damage_artoriax = false

# Define an attack range within which damage will register.
const ATTACK_RANGE = 100.0

# ––– PHYSICS PROCESS –––
func _physics_process(delta: float) -> void:
	if health <= 0:
		if current_state != State.DEATH:
			current_state = State.DEATH
			sprite.play("die" + get_direction_name())
		velocity = Vector2.ZERO
		return

	# Regenerate stamina.
	if stamina < MAX_STAMINA and not Input.is_action_pressed("shift"):
		stamina = min(stamina + STAMINA_REGEN * delta, MAX_STAMINA)
	
	# While attacking or rolling, ignore new movement input.
	if current_state in [State.ATTACK, State.ROLL]:
		if current_state == State.ROLL:
			velocity = input_direction * ROLL_SPEED
		else:
			velocity = Vector2.ZERO
	else:
		process_input()
	
	move_and_slide()

# ––– PROCESS (Animation Update) –––
func _process(_delta: float) -> void:
	if current_state == State.ATTACK and can_damage_artoriax:
		game_manager.on_artoriax_hit()
		can_damage_artoriax = false
	update_animation()

# ––– INPUT HANDLING –––
func process_input() -> void:
	# Read and normalize movement input.
	input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
		last_direction = get_direction_name()
	
	# Set movement state.
	if Input.is_action_pressed("shift") and stamina > 0:
		stamina -= RUN_STAMINA_COST
		velocity = input_direction * RUN_SPEED
		current_state = State.RUN
	elif input_direction.length() > 0:
		velocity = input_direction * WALK_SPEED
		current_state = State.WALK
	else:
		velocity = Vector2.ZERO
		current_state = State.IDLE

	# Roll action.
	if Input.is_action_just_pressed("roll") and stamina > 0:
		stamina -= ROLL_STAMINA_COST
		current_state = State.ROLL
		sprite.play("roll" + last_direction)
		is_invincible = true
		return

	# Attack action.
	if Input.is_action_just_pressed("attack") and stamina > 0:
		stamina -= ATTACK_STAMINA_COST
		current_state = State.ATTACK
		sprite.play("attack1" + last_direction)
		return

# ––– ANIMATION UPDATE –––
func update_animation() -> void:
	# If dead, let the death animation play uninterrupted.
	if health <= 0:
		return

	# When attacking or rolling, do not change the animation.
	if current_state in [State.ATTACK, State.ROLL]:
		return

	var anim_name: String = ""
	match current_state:
		State.IDLE:
			anim_name = "idle" + last_direction
		State.WALK:
			anim_name = "walk" + last_direction
		State.RUN:
			anim_name = "run" + last_direction
		_:
			anim_name = "idle" + last_direction

	if sprite.animation != anim_name:
		sprite.play(anim_name)

# ––– DIRECTION HELPER –––
func get_direction_name() -> String:
	if input_direction.length() < 0.1:
		return last_direction
	var angle: float = input_direction.angle()
	if angle >= -PI/8 and angle < PI/8:
		return "_right"
	elif angle >= PI/8 and angle < 3 * PI/8:
		return "_right_down"
	elif angle >= 3 * PI/8 and angle < 5 * PI/8:
		return "_down"
	elif angle >= 5 * PI/8 and angle < 7 * PI/8:
		return "_left_down"
	elif angle >= 7 * PI/8 or angle < -7 * PI/8:
		return "_left"
	elif angle >= -7 * PI/8 and angle < -5 * PI/8:
		return "_left_up"
	elif angle >= -5 * PI/8 and angle < -3 * PI/8:
		return "_up"
	elif angle >= -3 * PI/8 and angle < -PI/8:
		return "_right_up"
	return last_direction

# ––– ANIMATION FINISH CALLBACK –––
func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		State.ATTACK, State.ROLL:
			if current_state == State.ROLL:
				is_invincible = false
			current_state = State.IDLE
		State.DEATH:
			pass

# ––– ATTACK HITBOX SIGNALS –––
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == artoriax:
		can_damage_artoriax = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == artoriax:
		can_damage_artoriax = false
