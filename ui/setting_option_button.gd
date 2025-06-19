class_name SettingOptionButton extends OptionButton

@onready var click_audio := $ClickAudio
@onready var step_audio := $StepAudio


func _ready() -> void:
	item_selected.connect(func(_id: int):
		click_audio.play()
		apply_value(_id)
	)
	item_focused.connect(func(_id: int):
		step_audio.play()
	)
	pressed.connect(func():
		click_audio.play()
	)
	focus_entered.connect(func():
		step_audio.play()
	)

	return

## Apply this setting using the currently selected option
func apply_value(_index: int) -> void:
	return
