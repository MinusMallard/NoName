extends TextureProgressBar

@export var player_path: NodePath
@onready var player = get_node(player_path)# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	value = player.health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value = player.health

func increase_health(hp: int) -> void:
	player.on_health_increased(hp)
	value = player.health
	
func decrease_health(hp: int) -> void:
	player.on_health_decreased(hp)
	value = player.health
