class_name TrafficLightProp extends StandaloneSpringyProp

enum LIGHT_COLORS { NONE, GREEN, AMBER, RED }
var current_light := LIGHT_COLORS.NONE


func _ready() -> void:
  super()
  _bodies_scene = preload("res://maps/KayKitCity/props/traffic_light_a_bodies.tscn")
  _bodies = $StandalonePropBodies
  return


func respawn() -> void:
  super()
  match current_light:
    LIGHT_COLORS.NONE: _bodies.no_lights()
    LIGHT_COLORS.GREEN: _bodies.green_light()
    LIGHT_COLORS.RED: _bodies.red_light()
  return


func play_effect() -> void:
  $Sparks.emitting = true
  _bodies.no_lights()
  _bodies.prepare_to_break_apart()
  return


func stop_effect() -> void:
  $Sparks.emitting = false
  return


func green_light() -> void:
  current_light = LIGHT_COLORS.GREEN
  if not is_detached:
    _bodies.green_light()
  return


func red_light() -> void:
  current_light = LIGHT_COLORS.RED
  if not is_detached:
    _bodies.red_light()
  return
