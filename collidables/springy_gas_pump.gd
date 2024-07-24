extends SpringyProp

@export var should_explode := true
@export var explosion_force := 5000.0
## How much the explosion Area3D will be scaled up by. For the explosion to work correctly, its
## sphere collider should start with a radius of 1
@export var explosion_scale := 10.0
@onready var explosion_area : Area3D = $ExplosionArea
@onready var explosion_audio : AudioStreamPlayer3D = $ExplosionAudio


func _ready() -> void:
  explosion_area.set_deferred("monitoring", false)
  explosion_area.set_deferred("monitorable", false)
  explosion_area.scale = Vector3(0.01, 0.01, 0.01)
  explosion_area.connect("body_entered", func (_body: Node3D):
    if _body is RigidBody3D:
      var impulse_vector := _body.global_position - global_position
      var aim_basis := global_transform.looking_at(_body.global_position)
      var body_distance := global_transform.origin.distance_to(_body.global_position)
      _body.apply_central_impulse(impulse_vector.normalized() * (explosion_force * (body_distance - scale.x)))
  )


func register_scene_with_manager() -> void:
  if get_parent_node_3d().has_method("add_gas_pump_a"):
    springy_props_manager_node = get_parent_node_3d()
  return


func respawn() -> void:
  if springy_props_manager_node != null:
    springy_props_manager_node.add_gas_pump_a(global_position, global_rotation)


func play_effect() -> void:
  $AudioStreamPlayer3D.play()
  explosion_audio.play()
  physics_body.apply_central_impulse(Vector3.UP * physics_body.mass * 5)
  start_explosion()
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = true


func stop_effect() -> void:
  $AudioStreamPlayer3D.stop()
  explosion_audio.stop()
  stop_explosion()
  for emitter: Node in $RigidBody3D/Emitters.get_children():
    if emitter is GPUParticles3D:
      emitter.emitting = false


func start_explosion() -> void:
  explosion_area.set_deferred("monitoring", true)
  explosion_area.set_deferred("monitorable", true)
  var explosion_tween := create_tween()
  explosion_tween.tween_property(explosion_area, "scale", Vector3(explosion_scale, explosion_scale, explosion_scale), 0.5)
  explosion_tween.tween_callback(stop_explosion)

func stop_explosion() -> void:
  explosion_area.set_deferred("monitoring", false)
  explosion_area.set_deferred("monitorable", false)
  # explosion_area.scale = Vector3(0.01, 0.01, 0.01)
