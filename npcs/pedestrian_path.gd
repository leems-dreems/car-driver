class_name PedestrianPath extends Path3D
## Supports [PedestrianAgent] nodes, which spawn & control pedestrian NPCs

#
#func _ready() -> void:
  #if Engine.is_editor_hint():
    #var entrance_label := Label3D.new()
    #entrance_label.text = name
    #var _baked_curve_points := curve.get_baked_points()
    #entrance_label.position = _baked_curve_points[len(_baked_curve_points) / 2]
    #entrance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    #entrance_label.font_size = 180
    #add_child(entrance_label)
  #else:
    #if spawn_vehicles:
      #TrafficManager.traffic_paths.push_back(self)
    #path_length = curve.get_baked_length()
  #return
