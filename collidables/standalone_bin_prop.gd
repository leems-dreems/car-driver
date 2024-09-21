extends StandaloneSpringyProp


func _ready() -> void:
  super()
  _bodies_scene = preload("res://collidables/standalone_bin_bodies.tscn")
  _bodies = $StandalonePropBodies
