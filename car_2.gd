class_name Car extends RigidBody3D

var isOnGround := false


func _physics_process (delta: float) -> void:
  if isOnGround:
    apply_central_force(Vector3.BACK * 10)

  if linear_velocity.length() > 1:
    linear_velocity += linear_velocity * delta * 10

  $Speedo.text = str(int(linear_velocity.length()))
  return

func _on_body_entered (collidingBody: Node) -> void:
  if collidingBody.get('collision_layer') and collidingBody.collision_layer == 1:
    isOnGround = true
  return

func _on_body_exited(collidingBody: Node) -> void:
  if collidingBody.get('collision_layer') and collidingBody.collision_layer == 1:
    if not get_colliding_bodies().any(func (collidingBody: Node3D):
      return collidingBody.get('collision_layer') and collidingBody.collision_layer == 1
    ): isOnGround = false
  return
