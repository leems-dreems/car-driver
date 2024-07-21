class_name Mission extends Node3D

@export var start_area: ObjectiveArea = null
@export var objectives: Array[ObjectiveArea] = []
var is_done := false


func _physics_process(_delta: float) -> void:
  var uncompleted_objectives := objectives.filter(func(objective: ObjectiveArea):
    return not objective.is_completed
  )
  if len(uncompleted_objectives) == 0:
    is_done = true
  else:
    uncompleted_objectives[0].activate()
