class_name TrafficSpawnPoint extends PathFollow3D

@onready var collision_area: Area3D = $Area3D
var time_last_seen: float


func highlight() -> void:
  $AnimationPlayer.play("highlight")
  return
