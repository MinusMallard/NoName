extends Node

@onready var player: CharacterBody2D = $"../player"
@onready var artoriax: CharacterBody2D = $"../Artoriax"

var player_dead = false
var player_won = false

func _process(_delta: float) -> void:
	if player_dead or player_won:
		_return_to_title_screen()

func on_player_hit() -> void:
	if player.is_invincible:
		return
	
	var damage = randi_range(20, 30)
	player.health = max(player.health - damage, 0)
	if player.health == 0:
		player_dead = true

func on_artoriax_hit() -> void:
	var damage = randi_range(10, 15)
	artoriax.health = max(artoriax.health-damage, 0)
	if artoriax.health == 0:
		player_won = true
		
func _return_to_title_screen() -> void:
	await get_tree().create_timer(3.0).timeout  
	var title_screen = load("res://Scene/title_screen.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(title_screen)
	get_tree().current_scene = title_screen  
