extends SpringyProp

## Should this object explode when hit?
@export var should_explode := true
## Multiplier for size of initial impulse imparted to bodies hit by explosions.
@export var explosion_impulse_multiplier := 500.0
## Multiplier for sustained explosion force.
@export var explosion_force_multiplier := 500000.0
## How much the explosion Area3D will be scaled up by. For the explosion to work correctly, its
## sphere collider should start with a radius of 1
@export var explosion_scale := 20.0
@export var explosion_duration := 0.2
@export var explosion_delay := 0.3
@onready var explosion_area : Area3D = $ExplosionArea
@onready var explosion_audio : AudioStreamPlayer3D = $ExplosionAudio
## RigidBodies get given an initial impulse when hit by an explosion, and then have a force applied
## each physics step after that. We track those bodies here so we only apply that impulse once.
var impulsed_bodies : Array[RigidBody3D] = []


func _ready() -> void:
  super()
  explosion_area.position.x += randf_range(-0.1, 0.1)
  explosion_area.position.z += randf_range(-0.1, 0.1)
  explosion_area.set_deferred("monitoring", false)
  explosion_area.set_deferred("monitorable", false)
  explosion_area.scale = Vector3(0.01, 0.01, 0.01)
  explosion_area.connect("body_entered", func (_body: Node3D):
    if _body is RigidBody3D:
      if _body.get_parent_node_3d() is SpringyProp:
        if impulsed_bodies.has(_body):
          return
        impulsed_bodies.push_back(_body)
        _body.get_parent_node_3d().detach()
  )
  return


func _physics_process(delta: float) -> void:
  if explosion_area.monitoring:
    for _body: Node3D in explosion_area.get_overlapping_bodies():
      if _body is RigidBody3D:
        apply_explosion_force(_body, delta)
      elif _body is StaticBody3D and _body.is_in_group("ExplosionCatcher"):
        apply_explosion_force(_body.get_parent_node_3d(), delta, _body.position, 2.0)
  super(delta)


func register_scene_with_manager() -> void:
  if get_parent_node_3d().has_method("add_gas_pump_a"):
    springy_props_manager_node = get_parent_node_3d()
  return


func respawn() -> void:
  if springy_props_manager_node != null:
    springy_props_manager_node.add_gas_pump_a(global_position, global_rotation)
  return

## Applies an explosion force to a body. If [local_offset] is unspecified, the force will be offset
## to slightly above the body's center of mass, to impart a bit of top-spin.
func apply_explosion_force(_body: RigidBody3D, delta: float, local_offset: Vector3 = Vector3.INF, multiplier: float = 1.0) -> void:
  var direction_vector: Vector3 = (_body.global_position + _body.center_of_mass) - global_position
  # Compare the explosion's current scale to its max scale to get a strength multiplier
  var fade_multiplier: float = explosion_scale / explosion_area.scale.x
  var force_vector := direction_vector.normalized() * fade_multiplier * explosion_force_multiplier * multiplier
  if local_offset == Vector3.INF:
    # Adjust the target for the force to be above the body's CoM
    var adjusted_target: Vector3 = to_local(to_global(_body.center_of_mass) + Vector3(0, 0.1, 0))
    _body.apply_force(force_vector * (delta / Engine.time_scale), adjusted_target)
  else:
    _body.apply_force(force_vector * (delta / Engine.time_scale), local_offset)
  return


func play_effect() -> void:
  $AudioStreamPlayer3D.play()
  explosion_audio.play()
  #physics_body.apply_central_impulse(Vector3.UP * physics_body.mass * 5)
  if should_explode:
    await get_tree().create_timer(explosion_delay).timeout
    start_explosion()
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = true
  return


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  explosion_audio.stop()
  if should_explode:
    stop_explosion()
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = false
  return


func start_explosion() -> void:
#  Engine.time_scale = 0.02
  explosion_area.set_deferred("monitoring", true)
  explosion_area.set_deferred("monitorable", true)
  var explosion_tween := create_tween()
  explosion_tween.tween_property(explosion_area, "scale", Vector3(explosion_scale, explosion_scale, explosion_scale), explosion_duration)
  explosion_tween.tween_callback(stop_explosion)
  return


func stop_explosion() -> void:
#  Engine.time_scale = 1.0
  explosion_area.set_deferred("monitoring", false)
  explosion_area.set_deferred("monitorable", false)
  explosion_area.scale = Vector3(0.01, 0.01, 0.01)
  return
