class_name SpringyPropsManager extends Node3D

var base_springy_prop_scene := preload("res://collidables/springy_prop.tscn")
var traffic_light_a_scene := preload("res://maps/KayKitCity/props/traffic_light_a.tscn")
var trash_bin_square_scene := preload("res://collidables/springy_trash_bin_square.tscn")
var trash_bin_round_scene := preload("res://collidables/springy_trash_can_round.tscn")
var gas_pump_a_scene := preload("res://collidables/springy_gas_pump.tscn")


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


func add_traffic_light_a(_position: Vector3, _rotation: Vector3) -> void:
  var replacement_prop := traffic_light_a_scene.instantiate()
  add_child(replacement_prop)
  replacement_prop.global_position = _position
  replacement_prop.global_rotation = _rotation
  return


func add_trash_bin_square(_position: Vector3, _rotation: Vector3) -> void:
  var replacement_prop := trash_bin_square_scene.instantiate()
  add_child(replacement_prop)
  replacement_prop.global_position = _position
  replacement_prop.global_rotation = _rotation
  return


func add_trash_bin_round(_position: Vector3, _rotation: Vector3) -> void:
  var replacement_prop := trash_bin_round_scene.instantiate()
  add_child(replacement_prop)
  replacement_prop.global_position = _position
  replacement_prop.global_rotation = _rotation
  return


func add_gas_pump_a(_position: Vector3, _rotation: Vector3) -> void:
  var replacement_prop := gas_pump_a_scene.instantiate()
  add_child(replacement_prop)
  replacement_prop.global_position = _position
  replacement_prop.global_rotation = _rotation
  return
