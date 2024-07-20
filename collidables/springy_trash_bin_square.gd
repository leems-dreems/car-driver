extends SpringyProp

func register_scene_with_manager() -> void:
  if get_parent_node_3d().has_method("add_trash_bin_square"):
    springy_props_manager_node = get_parent_node_3d()
  return


func respawn() -> void:
  if springy_props_manager_node != null:
    springy_props_manager_node.add_trash_bin_square(global_position, global_rotation)


func play_effect() -> void:
  $AudioStreamPlayer3D.play()


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  $AudioStreamPlayer3D.seek(0)
