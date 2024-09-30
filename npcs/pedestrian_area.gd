extends NavigationRegion3D

@export var rebake_interval := 1.0
var time_since_rebake := 0.0


func _physics_process(delta: float) -> void:
  time_since_rebake += delta
  if time_since_rebake > rebake_interval:
    bake_navigation_mesh(true)
    time_since_rebake = 0
  return
