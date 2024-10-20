extends NavigationRegion3D

const uuid_util := preload("res://addons/uuid/uuid.gd")
@export var rebake_interval := 1.0
var time_since_rebake := 0.0
var bounding_area: Area3D = null
@onready var unique_geometry_group_name: String = uuid_util.v4()


func _ready() -> void:
  bounding_area = find_child("BoundingArea")
  if bounding_area:
    bounding_area.collision_mask = 66 # Collide with cars and physics props
    bounding_area.body_entered.connect(_add_to_unique_group)
    bounding_area.body_exited.connect(_remove_from_unique_group)
  self.add_to_group(unique_geometry_group_name)
  navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
  navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
  navigation_mesh.geometry_source_group_name = unique_geometry_group_name
  return


func _physics_process(delta: float) -> void:
  time_since_rebake += delta
  if time_since_rebake > rebake_interval:
    bake_navigation_mesh(true)
    time_since_rebake = 0
  return


func _add_to_unique_group(_node: Node) -> void:
  _node.add_to_group(unique_geometry_group_name)
  return


func _remove_from_unique_group(_node: Node) -> void:
  _node.remove_from_group(unique_geometry_group_name)
  return
