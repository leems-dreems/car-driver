class_name Explosion extends Node3D

signal finished
## Multiplier for sustained explosion force.
@export var explosion_force_multiplier := 500000.0
## How much the explosion Area3D will be scaled up by. For the explosion to work correctly, its
## sphere collider should start with a radius of 1
@export var explosion_scale := 20.0
@export var explosion_duration := 0.2
@export var explosion_delay := 0.3
@export var damage_multiplier := 0.1
@onready var explosion_area : Area3D = $ExplosionArea
@onready var explosion_audio : AudioStreamPlayer3D = $ExplosionAudio
@onready var debris_emitter := $DebrisEmitter
@onready var fire_emitter := $FireEmitter
@onready var smoke_emitter := $SmokeEmitter
## RigidBodies get given an initial impulse when hit by an explosion, and then have a force applied
## each physics step after that. We track those bodies here so we only apply that impulse once.
var impulsed_bodies : Array[RigidBody3D] = []


func _ready() -> void:
  explosion_area.position.x += randf_range(-0.1, 0.1)
  explosion_area.position.z += randf_range(-0.1, 0.1)
  explosion_area.set_deferred("monitoring", false)
  explosion_area.set_deferred("monitorable", false)
  explosion_area.scale = Vector3(0.01, 0.01, 0.01)
  explosion_area.connect("body_entered", func (_body: Node3D):
    if _body is RigidBody3D:
      var _parent := _body.get_parent_node_3d()
      if _parent is SpringyProp and not _parent.is_detached:
        _body.get_parent_node_3d().detach()
  )
  return


func _physics_process(delta: float) -> void:
  if explosion_area.monitoring:
    for _body: Node3D in explosion_area.get_overlapping_bodies():
      if _body.has_method("go_limp"):
        _body.go_limp()
      elif _body is PlayerPhysicalBone:
        _body.target_linear_velocity += calculate_force_vector_for_body(_body) / 1000
      if _body is RigidBody3D:
        apply_explosion_force(_body, delta)
      elif _body is StaticBody3D and _body.is_in_group("ExplosionCatcher"):
        apply_explosion_force(_body.get_parent_node_3d(), delta, _body.position, 2.0)


## Applies an explosion force to a body. If [local_offset] is unspecified, the force will be offset
## to slightly above the body's center of mass, to impart a bit of top-spin.
func apply_explosion_force(_body: RigidBody3D, delta: float, local_offset: Vector3 = Vector3.INF, multiplier: float = 1.0) -> void:
  var force_vector := calculate_force_vector_for_body(_body) * multiplier
  if local_offset == Vector3.INF:
    # Adjust the target for the force to be above the body's CoM
    var adjusted_target: Vector3 = to_local(to_global(_body.center_of_mass) + Vector3(0, 0.1, 0))
    _body.apply_force(force_vector * (delta / Engine.time_scale), adjusted_target)
  else:
    _body.apply_force(force_vector * (delta / Engine.time_scale), local_offset)
  if _body is DriveableVehicle:
    _body.current_hit_points -= (explosion_area.scale.x / explosion_scale) * damage_multiplier
  return


func calculate_force_vector_for_body(_body: Node3D) -> Vector3:
  var direction_vector: Vector3
  if _body is RigidBody3D:
    direction_vector = (_body.global_position + _body.center_of_mass) - explosion_area.global_position
  else:
    direction_vector = (_body.global_position) - explosion_area.global_position
  # Compare the explosion's current scale to its max scale to get a strength multiplier
  var fade_multiplier: float = explosion_scale / explosion_area.scale.x
  var force_vector := direction_vector.normalized() * fade_multiplier * explosion_force_multiplier
  return force_vector


func start_explosion() -> void:
#  Engine.time_scale = 0.02
  explosion_area.set_deferred("monitoring", true)
  explosion_area.set_deferred("monitorable", true)
  debris_emitter.emitting = true
  fire_emitter.emitting = true
  smoke_emitter.emitting = true
  var explosion_tween := create_tween()
  explosion_tween.tween_property(explosion_area, "scale", Vector3(explosion_scale, explosion_scale, explosion_scale), explosion_duration)
  explosion_tween.tween_callback(stop_explosion)
  explosion_audio.play()
  return


func stop_explosion() -> void:
#  Engine.time_scale = 1.0
  debris_emitter.emitting = false
  fire_emitter.emitting = false
  smoke_emitter.emitting = false
  explosion_area.set_deferred("monitoring", false)
  explosion_area.set_deferred("monitorable", false)
  explosion_area.scale = Vector3(0.01, 0.01, 0.01)
  finished.emit()
  return
