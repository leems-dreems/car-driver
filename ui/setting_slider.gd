class_name SettingSlider extends HSlider

@export var update_immediately := false
@onready var _update_timer := $UpdateTimer
@onready var step_audio: AudioStreamPlayer = $StepAudio
@onready var click_audio: AudioStreamPlayer = $ClickAudio


func _ready() -> void:
	_update_timer.timeout.connect(func():
		apply_value()
	)

	drag_started.connect(func(): click_audio.play())
	focus_entered.connect(func(): step_audio.play())

	if update_immediately:
		drag_ended.connect(func(_new_value: float): click_audio.play())
		value_changed.connect(func(_new_value: float): 
			step_audio.play()
			apply_value()
		)
	else:
		drag_ended.connect(func(_new_value: float):
			click_audio.play()
			if not _update_timer.is_stopped():
				_update_timer.stop()
				apply_value()
		)
		value_changed.connect(func(_new_value: float): 
			step_audio.play()
			_update_timer.start()
		)

	return

## Apply this setting using the current value of this slider
func apply_value() -> void:
	return
