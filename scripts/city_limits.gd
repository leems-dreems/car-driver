extends Area3D
## The bounding area of the city. Used to clean up objects that go out of bounds.

func destroyExitingNode (exitingNode: Node3D) -> void:
  if exitingNode.has_method('respawn'):
    exitingNode.respawn()
