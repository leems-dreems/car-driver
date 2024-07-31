class_name DummyCharacterSkin extends Node3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
var moving_blend_path := "parameters/StateMachine/Move/blend_position"
## False : set animation to "idle"
## True : set animation to "move"
var moving : bool = false : set = set_moving
## Blend value between the walk and run cycle
## 0.0 walk - 1.0 run
var move_speed : float = 0.0 : set = set_moving_speed


func _ready() -> void:
  animation_tree.active = true
  animation_player.get_animation("Walking_A").loop_mode = Animation.LOOP_LINEAR
  animation_player.get_animation("Running_A").loop_mode = Animation.LOOP_LINEAR
  animation_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
  animation_player.get_animation("Jump_Idle").loop_mode = Animation.LOOP_LINEAR


func set_moving(value : bool):
  moving = value
  if moving:
    state_machine.travel("Move")
  else:
    state_machine.travel("Idle")


func set_moving_speed(value : float):
  move_speed = clamp(value, 0.0, 1.0)
  animation_tree.set(moving_blend_path, move_speed)


func idle() -> void:
  state_machine.travel("Idle")


func walk() -> void:
  state_machine.travel("Move")


func jump() -> void:
  state_machine.travel("Jump_Start")


func fall() -> void:
  animation_player.play("Jump_Idle")


func land() -> void:
  state_machine.travel("Jump_Land")
