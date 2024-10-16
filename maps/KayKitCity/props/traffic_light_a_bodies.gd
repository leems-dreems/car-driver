class_name TrafficLightBodies extends StandalonePropBodies

var green_light_energy := 2.0
var red_light_energy := 2.0
var light_fade_time := 0.2


func no_lights() -> void:
  var _tween = get_tree().create_tween()
  _tween.tween_property($RigidBody3D/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/GreenLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/RedLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/RedLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  return


func green_light() -> void:
  var _tween = get_tree().create_tween()
  _tween.tween_property($RigidBody3D/GreenLight, "light_energy", green_light_energy, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/GreenLight/MeshInstance3D, "transparency", 0.0, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/RedLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/RedLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  return


func red_light() -> void:
  var _tween = get_tree().create_tween()
  _tween.tween_property($RigidBody3D/GreenLight, "light_energy", 0.0, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/GreenLight/MeshInstance3D, "transparency", 1.0, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/RedLight, "light_energy", red_light_energy, light_fade_time)
  _tween.parallel().tween_property($RigidBody3D/RedLight/MeshInstance3D, "transparency", 0.0, light_fade_time)
  return
