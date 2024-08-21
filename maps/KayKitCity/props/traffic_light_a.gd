class_name TrafficLightProp extends StandaloneSpringyProp

enum LIGHT_COLORS { NONE, GREEN, AMBER, RED }
var current_light := LIGHT_COLORS.NONE


func _ready() -> void:
  super()
  _bodies_scene = preload("res://maps/KayKitCity/props/traffic_light_a_bodies.tscn")
  _bodies = $StandalonePropBodies


func respawn() -> void:
  super()
  match current_light:
    LIGHT_COLORS.NONE: _bodies.no_lights()
    LIGHT_COLORS.GREEN: _bodies.green_light()
    LIGHT_COLORS.RED: _bodies.red_light()


func play_effect() -> void:
  $Sparks.emitting = true
  $AudioStreamPlayer3D.play()
  _bodies.no_lights()


func stop_effect() -> void:
  $Sparks.emitting = false
  $AudioStreamPlayer3D.stop()
  $AudioStreamPlayer3D.seek(0)


func green_light() -> void:
  current_light = LIGHT_COLORS.GREEN
  if not is_detached:
    _bodies.green_light()


func red_light() -> void:
  current_light = LIGHT_COLORS.RED
  if not is_detached:
    _bodies.red_light()
