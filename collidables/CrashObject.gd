class_name DetachableProp extends Node3D

@export var reset_time := 5.0
@onready var physics_body : RigidBody3D = $RigidBody3D
@onready var unfreeze_area : Area3D = $Area3D
var reset_timer : SceneTreeTimer = null
var has_been_hit := false

func _ready() -> void:
  unfreeze_area.connect("body_entered", unfreeze_prop)
  physics_body.connect("body_entered", func (body: Node3D):
    if has_been_hit: return
    has_been_hit = true
    play_effect(body)
  )

## If a body that can detach this prop enters the [unfreeze_area], unfreeze the prop. This prevents
## snagging when a fast-moving car hits a detachable prop. TODO: Look into moving this collider
## onto the car instead, and tying its radius to the car's velocity or something.
func unfreeze_prop(body: Node3D) -> void:
  if physics_body.freeze and body.is_in_group("CanCrash"):
    physics_body.freeze = false
    if reset_timer == null:
      reset_timer = get_tree().create_timer(reset_time)
      await reset_timer.timeout
      reset()

## Resets [physics_body] to its default position and freezes it
func reset() -> void:
  physics_body.freeze = true
  physics_body.position = Vector3.ZERO
  physics_body.rotation = Vector3.ZERO
  has_been_hit = false
  reset_timer = null
  stop_effect()

## Can be overridden to play effects etc when something collides with [physics_body]
func play_effect(body: Node3D) -> void:
  pass

func stop_effect() -> void:
  pass
