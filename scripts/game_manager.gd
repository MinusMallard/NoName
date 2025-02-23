extends Node

@export var player_path : NodePath
@onready var player = get_node(player_path)

@export var artoriax_path : NodePath
@onready var artoriax = get_node(artoriax_path)

var player_dead = false
var player_won = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_dead or player_won:
		_return_to_title_screen()
	
func on_player_hit() -> void:
	player.health = max(0, player.health-25)
	if player.health <= 0:
		pass
		
func on_artoriax_hit() -> void:
	artoriax.health = max(0, artoriax.health-25)
	if artoriax.health <= 0:
		pass
		
func _return_to_title_screen() -> void:
	await get_tree().create_timer(2.0).timeout  
	var title_screen = load("res://Scene/title_screen.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(title_screen)
	get_tree().current_scene = title_screen  
