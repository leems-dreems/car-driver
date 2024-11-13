extends StandaloneSpringyProp

const explosion_scene := preload("res://effects/explosion.tscn")
@export var explosion_delay := 0.2
@export var explosion_position: Vector3
var explosion: Explosion = null


func _ready() -> void:
  super()
  _bodies_scene = preload("res://collidables/standalone_gas_pump_bodies.tscn")
  _bodies = $StandalonePropBodies


func play_effect() -> void:
  $AudioStreamPlayer3D.play()
  await get_tree().create_timer(explosion_delay).timeout
  explosion = explosion_scene.instantiate()
  add_child(explosion)
  explosion.position = explosion_position
  explosion.start_explosion()
  _bodies.play_effect()
  return


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  explosion.stop_explosion()
  remove_child(explosion)
  explosion.queue_free()
  explosion = null
  _bodies.stop_effect()
  return
