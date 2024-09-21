extends StandaloneSpringyProp

@export var explosion_delay := 0.2
@onready var explosion := $Explosion


func _ready() -> void:
  super()
  _bodies_scene = preload("res://collidables/standalone_gas_pump_bodies.tscn")
  _bodies = $StandalonePropBodies


func play_effect() -> void:
  $AudioStreamPlayer3D.play()
  await get_tree().create_timer(explosion_delay).timeout
  explosion.start_explosion()
  _bodies.play_effect()
  return


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  explosion.stop_explosion()
  _bodies.stop_effect()
  return
