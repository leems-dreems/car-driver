class_name Mission extends Node3D

@export var mission_name := 'newmission'
@export var objectives: Array[ObjectiveArea] = []
var is_done := false


func _ready() -> void:
  for objective in objectives:
    objective.deactivate()


func _physics_process(_delta: float) -> void:
  var uncompleted_objectives := objectives.filter(func(objective: ObjectiveArea):
    return not objective.is_completed
  )
  if len(uncompleted_objectives) == 0:
    is_done = true
  else:
    uncompleted_objectives[0].activate()


func get_current_objective() -> ObjectiveArea:
  var uncompleted_objectives := objectives.filter(func(objective: ObjectiveArea):
    return not objective.is_completed
  )
  if len(uncompleted_objectives) > 0:
    return uncompleted_objectives[0]
  return null
