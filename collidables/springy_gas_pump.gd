extends SpringyProp

@export var explosion: Explosion
## Should this object explode when hit?
@export var should_explode := true
## Delay before exploding
@export var explosion_delay := 0.3


func register_scene_with_manager() -> void:
  if get_parent_node_3d().has_method("add_gas_pump_a"):
    springy_props_manager_node = get_parent_node_3d()
  return


func respawn() -> void:
  if springy_props_manager_node != null:
    springy_props_manager_node.add_gas_pump_a(global_position, global_rotation)
  return


func play_effect() -> void:
  $AudioStreamPlayer3D.play()
  if should_explode:
    await get_tree().create_timer(explosion_delay).timeout
    explosion.start_explosion()
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = true
  return


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  if should_explode:
    explosion.stop_explosion()
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = false
  return
