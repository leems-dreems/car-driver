extends SpringyProp

func register_scene_with_manager() -> void:
  if get_parent_node_3d().has_method("add_gas_pump_a"):
    springy_props_manager_node = get_parent_node_3d()
  return


func respawn() -> void:
  if springy_props_manager_node != null:
    springy_props_manager_node.add_gas_pump_a(global_position, global_rotation)


func play_effect() -> void:
  $AudioStreamPlayer3D.play()
  physics_body.apply_central_impulse(Vector3.UP * physics_body.mass * 10)
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = true


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  $AudioStreamPlayer3D.seek(0)
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = false
