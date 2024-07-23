class_name SpringyPropsManager extends Node3D

var base_springy_prop_scene := preload("res://collidables/springy_prop.tscn")


func _ready() -> void:
  for child: Node in get_children():
    if child is SpringyProp:
      child.springy_props_manager_node = self
  return

func add_base_springy_prop(_position: Vector3, _rotation: Vector3) -> void:
  var replacement_prop := base_springy_prop_scene.instantiate()
  add_child(replacement_prop)
  replacement_prop.global_position = _position
  replacement_prop.global_rotation = _rotation
  return
