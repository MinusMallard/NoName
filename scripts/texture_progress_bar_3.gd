extends TextureProgressBar

@export var artoriax_path: NodePath
@onready var artoriax = get_node(artoriax_path)

func _ready() -> void:
	value = artoriax.health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	value = artoriax.health
