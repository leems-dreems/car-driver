extends GPUParticles3D

@export var vehicle : Vehicle

@export var longitudinal_slip_threshold := 0.5
@export var lateral_slip_threshold := 1.0

func _process(delta):
  if is_instance_valid(vehicle):
    for wheel: Wheel in vehicle.wheel_array:
      if absf(wheel.slip_vector.x) > lateral_slip_threshold or absf(wheel.slip_vector.y) > longitudinal_slip_threshold:
        var smoke_transform : Transform3D = wheel.global_transform
        smoke_transform.origin = wheel.last_collision_point
        emit_particle(smoke_transform,  wheel.global_transform.basis * ((wheel.local_velocity * 0.2) - (Vector3.FORWARD * wheel.spin * wheel.tire_radius * 0.2)) * self.global_transform.basis, Color.WHITE, Color.WHITE, 5) #EMIT_FLAG_POSITION + EMIT_FLAG_VELOCITY)
        if not wheel.screechSFX.playing:
          wheel.screechSFX.play()
        wheel.screechSFX.volume_db = linear_to_db(lerpf(db_to_linear(wheel.screechSFX.volume_db), 1, delta * 20))
      else:
        wheel.screechSFX.volume_db = linear_to_db(lerpf(db_to_linear(wheel.screechSFX.volume_db), 0.001, delta * 10))
        if db_to_linear(wheel.screechSFX.volume_db) <= 0.002:
          wheel.screechSFX.stop()
