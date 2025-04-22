class_name DialogueBubbleControl extends CenterContainer

@onready var choices_container := $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer_Choices
@onready var continue_button := $PanelContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var click_audio := $ClickAudio
const choice_button_scene := preload("res://ui/ink_elements/dialogue_choice_button.tscn")
signal choice_selected(InkChoice)
signal continue_dialogue


func _ready() -> void:
	for _child in choices_container.get_children():
		if _child is Button:
			_child.grab_focus.call_deferred()
			break
	continue_button.pressed.connect(func():
		click_audio.play()
		continue_dialogue.emit()
		accept_event()
	)
	return


func show_choices(_choices: Array) -> void:
	for _child in choices_container.get_children():
		if _child is Button:
			_child.queue_free()

	if len(_choices) == 0:
		return

	continue_button.visible = false

	var i: int = 0
	for _choice: InkChoice in _choices:
		var _button: DialogueChoiceButton = choice_button_scene.instantiate()
		_button.text = _choice.text
		_button.ink_choice = _choice
		choices_container.add_child(_button)
		_button.pressed.connect(func():
			click_audio.play()
			choice_selected.emit(_button.ink_choice)
			accept_event()
		)
		if i == 0:
			_button.grab_focus.call_deferred()
		i += 1

	#if len(_choices) > 1:
		#var _children := choices_container.get_children()
		#var j: int = 0
		#var children_count := len(_children)
		#for _child in _children:
			#if _child is Button:
				#if j == 0:
					#_child.focus_neighbor_top = _children[children_count - 1].get_path()
				#else:
					#_child.focus_neighbor_top = _children[j - 1].get_path()
				#if j >= children_count - 1:
					#_child.focus_neighbor_bottom = _children[0].get_path()
				#else:
					#_child.focus_neighbor_bottom = _children[j + 1].get_path()
			#j += 1

	return


func set_npc_name(_name: String) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/VBoxContainer_Name/NameLabel.text = _name
	return


func show_dialogue(_dialogue: String) -> void:
	$PanelContainer/MarginContainer/VBoxContainer/VBoxContainer_Dialogue/DialogueLabel.text = _dialogue
	continue_button.visible = true
	continue_button.grab_focus.call_deferred()
	return
