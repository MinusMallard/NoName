extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

var health = 100

# Movement parameters
const speed = 100
const roll_speed = 600
const run_speed = 300
var cooldown = 0

# State tracking
var rolling = false
var roll_vector = Vector2.ZERO
var jump_buffer = []  # Stack to store jump timestamps
var attacking = false
var attack_buffer = []
var current_animation = ""  # Current playing animation (used for roll)
var current_idle = "idle_right"   # Default idle animation

func _ready() -> void:
	Engine.max_fps = 60

func _physics_process(delta):
	var input_dir = get_input_direction()  # Get raw input vector
	var move_dir = Vector2.ZERO
	
	
	# If we're not in a cooldown (roll in progress)
	if cooldown <= 0:
		rolling = false
		attacking = false
		
		var current_time = Time.get_ticks_msec()
		while jump_buffer.size() > 0 and current_time-jump_buffer[0] >= 400:
			var x = jump_buffer.pop_front()
			print("deleted")
			print(x)
		
		if (Input.is_action_just_pressed("attack") or attack_buffer.size() > 0):
			move_dir = Vector2.ZERO
			attack_buffer.pop_back()
			start_attack(current_idle)
		# If roll is triggered and there is directional input, start rolling
		elif (Input.is_action_just_pressed("ui_select") or jump_buffer.size() > 0) and input_dir != Vector2.ZERO:
			jump_buffer.pop_back()
			if input_dir.x < 0:
				input_dir.x -= 5
			if input_dir.x > 0:
				input_dir.x += 5
			if input_dir.y < 0:
				input_dir.y -= 5
			if input_dir.y > 0:
				input_dir.y += 5
			start_roll(input_dir)
			move_dir = roll_vector
		else:
			# Normal walking movement
			move_dir = input_dir
			if move_dir != Vector2.ZERO:
				var walk_anim = get_walk_animation(move_dir)
				current_idle = get_idle_animation(move_dir)
				if anim.animation != walk_anim:
					anim.play(walk_anim)
			else:
				# Not moving: play idle animation (from last movement)
				anim.play(current_idle)
	else:
		# During roll cooldown, continue moving in the roll direction
		cooldown -= 1
		move_dir = roll_vector
		anim.play(current_animation)
		# When cooldown expires, rolling is finished
		if cooldown <= 0:
			rolling = false
			attacking = false
			
	if Input.is_action_just_pressed("ui_select"):
		jump_buffer.append(Time.get_ticks_msec())
		print(jump_buffer[0])
	
	# Set the velocity based on movement mode (roll or normal)
	var current_speed = 0
	if rolling:
		current_speed = roll_speed
	else:
		current_speed = speed
	
		
	if Input.is_action_pressed("shift"):
		current_speed = run_speed
	else:
		current_speed = speed
		
	velocity = move_dir.normalized() * current_speed
	
	if (!attacking):
		move_and_slide()

# Returns a Vector2 based on input actions.
func get_input_direction() -> Vector2:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	return dir

# Returns the walk animation based on the movement direction.
func get_walk_animation(direction: Vector2) -> String:
	# Diagonals first
	if direction.x > 0 and direction.y > 0:
		if Input.is_action_pressed("shift"):
			return "run_right_down"
		else:
			return "walk_right_down"
	elif direction.x > 0 and direction.y < 0:
		if Input.is_action_pressed("shift"):
			return "run_right_up"
		else:
			return "walk_right_up"
	elif direction.x < 0 and direction.y > 0:
		if Input.is_action_pressed("shift"):
			return "run_left_down"
		else: 
			return "walk_left_down"
	elif direction.x < 0 and direction.y < 0:
		if Input.is_action_pressed("shift"):
			return "run_left_up"
		else:
			return "walk_left_up"
	elif direction.x > 0:
		if Input.is_action_pressed("shift"):
			return "run_right"
		else:
			return "walk_right"
	elif direction.x < 0:
		if Input.is_action_pressed("shift"):
			return "run_left"
		else:
			return "walk_left"
	elif direction.y > 0:
		if Input.is_action_pressed("shift"):
			return "run_down"
		else:
			return "walk_down"
	elif direction.y < 0:
		if Input.is_action_pressed("shift"):
			return "run_up"
		else:
			return "walk_up"
	return "idle"

# Returns the idle animation based on the last movement direction.
func get_idle_animation(direction: Vector2) -> String:
	if direction.x > 0 and direction.y > 0:
		return "idle_right_down"
	elif direction.x > 0 and direction.y < 0:
		return "idle_right_up"
	elif direction.x < 0 and direction.y > 0:
		return "idle_left_down"
	elif direction.x < 0 and direction.y < 0:
		return "idle_left_up"
	elif direction.x > 0:
		return "idle_right"
	elif direction.x < 0:
		return "idle_left"
	elif direction.y > 0:
		return "idle_down"
	elif direction.y < 0:
		return "idle_up"
	return "idle_up"
	

# Returns the roll animation name based on the roll direction.
func get_roll_animation(direction: Vector2) -> String:
	if direction.x > 0 and direction.y > 0:
		return "roll_right_down"
	elif direction.x > 0 and direction.y < 0:
		return "roll_right_up"
	elif direction.x < 0 and direction.y > 0:
		return "roll_left_down"
	elif direction.x < 0 and direction.y < 0:
		return "roll_left_up"
	elif direction.x > 0:
		return "roll_right"
	elif direction.x < 0:
		return "roll_left"
	elif direction.y > 0:
		return "roll_down"
	else:
		return "roll_up"
	  # fallback in case no direction is found
func get_attack_animation(direction: String) -> String:
	if direction == "idle_right_down":
		return "attack1_right_down"
	elif direction == "idle_right_up":
		return "attack1_right_up"
	elif direction == "idle_left_down":
		return "attack1_left_down"
	elif direction == "idle_left_up":
		return "attack1_left_up"
	elif direction == "idle_right":
		return "attack1_right"
	elif direction == "idle_left":
		return "attack1_left"
	elif direction == "idle_down":
		return "attack1_down"
	else:
		return "attack1_up"

# Initializes the roll action.
func start_roll(direction: Vector2) -> void:
	rolling = true
	roll_vector = direction.normalized()
	current_animation = get_roll_animation(direction)
	current_idle = get_idle_animation(direction)
	anim.play(current_animation)
	cooldown = 30 # Duration of the roll in frames
	
func start_attack(direction: String) -> void:
	attacking = true
	current_animation = get_attack_animation(direction)
	anim.play(current_animation)
	cooldown = 30 # Duration of attack in frames
