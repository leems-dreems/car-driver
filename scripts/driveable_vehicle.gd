class_name DriveableVehicle extends Vehicle

var is_being_driven := false

func _ready () -> void:
  super()
  $EnterCarCollider.vehicle = self
  return
