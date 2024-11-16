extends CarGameParticles

@export var vehicle : Vehicle
@export var longitudinal_slip_threshold := 0.5
@export var lateral_slip_threshold := 1.0
@export var skidmark_length := 1.0
## Old skidmark decals will be freed up when this many decals have been added
@export var max_skidmark_decals: int = 100
const skidmark_decal_scene := preload("res://cars/skidmark_decal.tscn")
## Array of skidmark decals, so we can queue_free the oldest when adding a new one
var skidmark_decals: Array[Decal] = []


func _ready() -> void:
  super()
  for wheel: Wheel in vehicle.wheel_array:
    wheel.squeal_audio.unit_size = 0


func _process(delta: float):
  if is_instance_valid(vehicle):
    for wheel: Wheel in vehicle.wheel_array:
      if absf(wheel.slip_vector.x) > lateral_slip_threshold or absf(wheel.slip_vector.y) > longitudinal_slip_threshold:
        # Update skidmark decals
        if wheel.skidmark_start == Transform3D.IDENTITY:
          wheel.skidmark_start = Transform3D(wheel.global_transform)
        var distance_from_last_decal := wheel.global_position.distance_to(wheel.skidmark_start.origin)
        if distance_from_last_decal > skidmark_length:
          var smoke_transform : Transform3D = wheel.global_transform
          smoke_transform.origin = wheel.last_collision_point
          emit_particle(smoke_transform, wheel.global_transform.basis * ((wheel.local_velocity * 0.2) - (Vector3.FORWARD * wheel.spin * wheel.tire_radius * 0.2)) * self.global_transform.basis, Color.WHITE, Color.WHITE, 5) #EMIT_FLAG_POSITION + EMIT_FLAG_VELOCITY)
          var new_skidmark := skidmark_decal_scene.instantiate()
          new_skidmark.top_level = true
          new_skidmark.position = wheel.last_collision_point
          new_skidmark.transform.basis = wheel.global_transform.looking_at(wheel.skidmark_start.origin).basis
          new_skidmark.size.z = distance_from_last_decal / skidmark_length
          skidmark_decals.push_front(new_skidmark)
          add_child(new_skidmark)
          wheel.skidmark_start = Transform3D(wheel.global_transform)
          if len(skidmark_decals) > max_skidmark_decals:
            var oldest_skidmark: Decal = skidmark_decals.pop_back()
            oldest_skidmark.queue_free()

        # Adjust volumes of audio players
        if not wheel.squeal_audio.playing:
          wheel.squeal_audio.play()
        if not wheel.rumble_audio.playing:
          wheel.rumble_audio.play()
        #if not wheel.skid_audio.playing:
          #wheel.skid_audio.play()

        var squeal_amount := clampf(pow(absf(wheel.slip_vector.y), 1), 0, 1.0)
        var skid_amount := clampf(pow(absf(wheel.slip_vector.x), 1), 0, 1.0)

        if wheel.last_collider.is_in_group("Road"):
          wheel.squeal_audio.unit_size = lerpf(wheel.squeal_audio.unit_size, maxf(squeal_amount, skid_amount), delta * 10)
          wheel.squeal_audio.pitch_scale = lerpf(wheel.squeal_audio.pitch_scale, 1.0 - (skid_amount / 4), delta * 10)
          wheel.rumble_audio.unit_size = lerpf(wheel.rumble_audio.unit_size, 0, delta * 10)
        else:
          wheel.rumble_audio.unit_size = lerpf(wheel.rumble_audio.unit_size, maxf(squeal_amount, skid_amount), delta * 10)
          wheel.rumble_audio.pitch_scale = lerpf(wheel.rumble_audio.pitch_scale, 2.0 - (skid_amount / 4), delta * 10)
          wheel.squeal_audio.unit_size = lerpf(wheel.squeal_audio.unit_size, 0, delta * 10)
      else:
        wheel.skidmark_start = Transform3D.IDENTITY
        wheel.squeal_audio.unit_size = lerpf(wheel.squeal_audio.unit_size, 0, delta * 10)
        wheel.squeal_audio.pitch_scale = lerpf(wheel.squeal_audio.pitch_scale, 1.0, delta * 10)
        wheel.rumble_audio.unit_size = lerpf(wheel.rumble_audio.unit_size, 0, delta * 10)
        wheel.rumble_audio.pitch_scale = lerpf(wheel.rumble_audio.pitch_scale, 2.0, delta * 10)
        #wheel.skid_audio.unit_size = lerpf(wheel.skid_audio.unit_size, 0, delta * 10)
        if wheel.squeal_audio.unit_size <= 0.002:
          wheel.squeal_audio.stop()
        if wheel.rumble_audio.unit_size <= 0.002:
          wheel.rumble_audio.stop()
