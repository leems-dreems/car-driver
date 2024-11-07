class_name CarGameParticles extends GPUParticles3D

var _default_interpolate_setting: bool


func _ready() -> void:
  _default_interpolate_setting = interpolate
  return


func _notification(what: int) -> void:
  match what:
    NOTIFICATION_PAUSED:
      interpolate = false
    NOTIFICATION_UNPAUSED:
      interpolate = _default_interpolate_setting
  return
