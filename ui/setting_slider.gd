class_name SettingSlider extends HSlider

@export var update_immediately := false
@onready var _update_timer := $UpdateTimer


func _ready() -> void:
	_update_timer.timeout.connect(func():
		apply_value()
	)

	drag_started.connect(func(): $ClickAudio.play())

	if update_immediately:
		drag_ended.connect(func(_new_value: float): $ClickAudio.play())
		value_changed.connect(func(_new_value: float): 
			$StepAudio.play()
			apply_value()
		)
	else:
		drag_ended.connect(func(_new_value: float):
			$ClickAudio.play()
			if not _update_timer.is_stopped():
				_update_timer.stop()
				apply_value()
		)
		value_changed.connect(func(_new_value: float): 
			$StepAudio.play()
			_update_timer.start()
		)

	return

## Apply this setting using the current value of this slider
func apply_value() -> void:
	return
