extends SpringyProp

func register_scene_with_manager() -> void:
  if get_parent_node_3d().has_method("add_traffic_light_a"):
    springy_props_manager_node = get_parent_node_3d()
  return


func respawn() -> void:
  if springy_props_manager_node != null:
    springy_props_manager_node.add_traffic_light_a(global_position, global_rotation)


func play_effect() -> void:
  $Sparks.emitting = true
  $AudioStreamPlayer3D.play()


func stop_effect() -> void:
  $Sparks.emitting = false
  $AudioStreamPlayer3D.stop()
  $AudioStreamPlayer3D.seek(0)
