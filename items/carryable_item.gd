class_name CarryableItem extends RigidBody3D

@export var item_name: String
var is_highlighted := false


func highlight() -> void:
  $AnimationPlayer.play("highlight")
  is_highlighted = true
  print("highlighting")
  return


func unhighlight() -> void:
  $AnimationPlayer.play("un_highlight")
  is_highlighted = false
  return
