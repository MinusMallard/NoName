extends CanvasLayer

# Reference to your CharacterBody2D (or similar) player node
@export var player_path: NodePath
@onready var player = get_node(player_path)

# Shader parameters for the transparent circle effect
@export var glow_radius: float = 850.0
@export var inner_radius: float = 1.0

# Shader material instance
var glow_material: ShaderMaterial

func _ready():
	# Create and load the shader material
	glow_material = ShaderMaterial.new()
	glow_material.shader = load("res://shaders/light_controller.gdshader")
	
	# Set shader parameters (only those used by the shader)
	glow_material.set_shader_parameter("glow_radius", glow_radius)
	glow_material.set_shader_parameter("inner_radius", inner_radius)
	
	# Create a full-screen ColorRect to which the shader is applied
	var screen_effect = ColorRect.new()
	add_child(screen_effect)
	
	# Set the ColorRect to fill the entire viewport
	screen_effect.anchor_right = 1.0
	screen_effect.anchor_bottom = 1.0
	screen_effect.material = glow_material
	screen_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	if player and glow_material:
		var screen_pos = world_to_screen(player.global_position)
		glow_material.set_shader_parameter("player_position", screen_pos)

			
func world_to_screen(world_position: Vector2) -> Vector2:
	var viewport := get_viewport()
	var viewport_size := viewport.get_visible_rect().size
	var camera := viewport.get_camera_2d()
	if camera:
		# If your camera does not rotate, use this conversion:
		return (world_position - camera.global_position) * camera.zoom + viewport_size * 0.5
	return world_position
