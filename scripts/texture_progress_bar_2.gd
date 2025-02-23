extends TextureProgressBar

@export var player_path: NodePath
@onready var player = get_node(player_path)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = player.stamina

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	value = player.stamina
