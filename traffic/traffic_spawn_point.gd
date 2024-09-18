class_name TrafficSpawnPoint extends PathFollow3D

@onready var collision_area: Area3D = $Area3D


func highlight() -> void:
  $AnimationPlayer.play("highlight")
  return
