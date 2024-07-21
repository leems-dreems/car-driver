class_name MissionsManager extends Node


func get_current_mission() -> Mission:
  for _node: Node in get_children():
    if _node is Mission and not _node.is_done:
      return _node
  return null
