class_name CarContactChecker extends RigidBody3D

## If the squared length of the collision velocity is greater than this, play sounds and emitters
@export var minimum_scrape_velocity := 10
const scrape_emitter := preload("res://effects/car_scrape_emitter.tscn")
var vehicle: DriveableVehicle
## Dictionary of "scrape" particle emitters, keyed to the ID of the body being scraped against 
var _scrape_emitters := {}


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
  if not vehicle.is_being_driven:
    return
  var delta := get_physics_process_delta_time()
  var _contact_count := state.get_contact_count()
  var _colliding_bodies := get_colliding_bodies()
  var _contacts_dict := {}
  for i in range(_contact_count):
    var _collider_id := state.get_contact_collider_id(i)
    var _contact_local_velocity = state.get_contact_local_velocity_at_position(i)
    var _contact_collider_velocity = state.get_contact_collider_velocity_at_position(i)
    var _velocity_difference: Vector3 = _contact_local_velocity - _contact_collider_velocity
    if not _contacts_dict.has(_collider_id):
      _contacts_dict[_collider_id] = {
        "velocity_differences": [],
        "contact_positions": [],
        "mean_velocity": null,
        "mean_position": null
      }
    _contacts_dict[_collider_id].velocity_differences.push_back(_velocity_difference)
    _contacts_dict[_collider_id].contact_positions.push_back(state.get_contact_collider_position(i))
  for _collider_id in _contacts_dict:
    var _mean_contact_velocity: Vector3 = _contacts_dict[_collider_id].velocity_differences.reduce(func(_summed_velocity: Vector3, _velocity_difference: Vector3):
      return _summed_velocity + _velocity_difference
    )
    _contacts_dict[_collider_id].mean_velocity = _mean_contact_velocity / len(_contacts_dict[_collider_id].velocity_differences)
    var _mean_contact_position: Vector3 = _contacts_dict[_collider_id].contact_positions.reduce(func(_summed_position: Vector3, _contact_position: Vector3):
      return _summed_position + _contact_position
    )
    _contacts_dict[_collider_id].mean_position = _mean_contact_position / len(_contacts_dict[_collider_id].contact_positions)
    if not _scrape_emitters.has(_collider_id):
      var _new_emitter := scrape_emitter.instantiate()
      add_child(_new_emitter)
      _scrape_emitters[_collider_id] = _new_emitter
      _new_emitter.finished.connect(func():
        if _scrape_emitters.has(_collider_id):
          _scrape_emitters[_collider_id].queue_free()
          _scrape_emitters.erase(_collider_id)
      )
    var _emitter: CarScrapeEmitter = _scrape_emitters[_collider_id]
    _emitter.global_position = _contacts_dict[_collider_id].mean_position
    _emitter.top_level = false
    var _scrape_velocity: float = _contacts_dict[_collider_id].mean_velocity.length_squared()
    if _scrape_velocity > minimum_scrape_velocity:
      _emitter.one_shot = false
      _emitter.emitting = true
      if not _emitter.audio_player.playing:
        _emitter.audio_player.play()
      _emitter.audio_player.volume_db = lerpf(_emitter.audio_player.volume_db, 0, delta)
      _emitter.audio_player.pitch_scale = 1 + (clampf(_scrape_velocity, 0, 1000) / 1000)
    else:
      if _emitter.emitting and not _emitter.one_shot:
        _emitter.emitting = false
        _emitter.one_shot = true
        _emitter.emitting = true
      _emitter.audio_player.volume_db = lerpf(_emitter.audio_player.volume_db, -80, delta)
      if _emitter.audio_player.volume_db < -40:
        _emitter.audio_player.stop()
  for _collider_id in _scrape_emitters:
    if not _contacts_dict.has(_collider_id):
      var _emitter: CarScrapeEmitter = _scrape_emitters[_collider_id]
      _emitter.audio_player.volume_db = lerpf(_emitter.audio_player.volume_db, -80, delta)
      _emitter.top_level = true
      if _emitter.emitting and not _emitter.one_shot:
        _emitter.emitting = false
        _emitter.one_shot = true
        _emitter.emitting = true
  return
