extends StandaloneSpringyProp


func _ready() -> void:
  super()
  _bodies_scene = preload("res://collidables/standalone_bin_bodies.tscn")
  _bodies = $StandalonePropBodies


func play_effect() -> void:
  $AudioStreamPlayer3D.play()


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  $AudioStreamPlayer3D.seek(0)
