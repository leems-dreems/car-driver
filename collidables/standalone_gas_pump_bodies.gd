extends StandalonePropBodies


func play_effect() -> void:
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = true


func stop_effect() -> void:
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = false
