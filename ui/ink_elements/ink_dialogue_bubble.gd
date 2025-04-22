class_name DialogueBubble extends Sprite3D

@onready var control: DialogueBubbleControl = $SubViewport/DialogueBubbleControl
@onready var _sub_viewport: SubViewport = $SubViewport


func _unhandled_input(event) -> void:
	_sub_viewport.push_input(event)
	return
