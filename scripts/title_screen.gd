extends Control


func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	var game_scene = load("res://Scene/game.tscn").instantiate()
	get_tree().current_scene.queue_free()  
	get_tree().root.add_child(game_scene)
	get_tree().current_scene = game_scene 

func _on_quit_pressed() -> void:
	get_tree().quit()
