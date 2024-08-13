extends Area3D

func _on_area_entered(area: Area3D) -> void:
  if area.is_in_group("StopSignal"):
    printt("redLight", name)
    set_collision_layer_value(1, true)


func _on_area_exited(area: Area3D) -> void:
  if area.is_in_group("StopSignal"):
    printt("greenLight", name)
    set_collision_layer_value(1, false)
