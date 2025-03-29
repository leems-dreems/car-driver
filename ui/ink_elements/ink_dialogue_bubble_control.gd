class_name DialogueBubbleControl extends CenterContainer

@onready var choices_container := $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer_Choices
const choice_button_scene := preload("res://ui/ink_elements/dialogue_choice_button.tscn")


func _ready() -> void:
	for _child in choices_container.get_children():
		if _child is Button:
			_child.grab_focus.call_deferred()
			break
	return


func show_choices(_choices: Array) -> void:
	for _child in choices_container.get_children():
		if _child is Button:
			_child.queue_free()

	var i: int = 0
	for _choice: InkChoice in _choices:
		var _button := choice_button_scene.instantiate()
		_button.text = _choice.text
		choices_container.add_child(_button)
		if i == 0:
			_button.grab_focus.call_deferred()
		i += 1

	if len(_choices) > 1:
		var _children := choices_container.get_children()
		var j: int = 0
		var children_count := len(_children)
		for _child in _children:
			if _child is Button:
				if j == 0:
					_child.focus_neighbor_top = _children[children_count - 1].get_path()
				else:
					_child.focus_neighbor_top = _children[j - 1].get_path()
				if j >= children_count - 1:
					_child.focus_neighbor_bottom = _children[0].get_path()
				else:
					_child.focus_neighbor_bottom = _children[j + 1].get_path()
			j += 1

	return


func set_npc_name(_name: String) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/VBoxContainer_Name/NameLabel.text = _name
	return


func show_dialogue(_dialogue: String) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/VBoxContainer_Dialogue/DialogueLabel.text = _dialogue
	return
