class_name DummyCharacterSkin extends Node3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var skeleton : Skeleton3D = $Rig/Skeleton3D
@onready var step_sound: AudioStreamPlayer3D = $StepSound
var moving_blend_path := "parameters/StateMachine/Move/blend_position"
## False : set animation to "idle"
## True : set animation to "move"
var moving : bool = false : set = set_moving
## Blend value between the walk and run cycle
## 0.0 walk - 1.0 run
var move_speed : float = 0.0 : set = set_moving_speed


func _ready() -> void:
  animation_tree.active = true
  animation_player.get_animation("DummySkin/Walking_A").loop_mode = Animation.LOOP_LINEAR
  animation_player.get_animation("DummySkin/Running_A").loop_mode = Animation.LOOP_LINEAR
  animation_player.get_animation("DummySkin/Idle").loop_mode = Animation.LOOP_LINEAR
  animation_player.get_animation("DummySkin/Jump_Idle").loop_mode = Animation.LOOP_LINEAR
  animation_player.get_animation("DummySkin/T-Pose").loop_mode = Animation.LOOP_LINEAR


func play_step_sound() -> void:
  step_sound.play()


func set_moving(value : bool):
  moving = value
  if moving:
    state_machine.travel("Move")
  else:
    state_machine.travel("DummySkin_Idle")


func set_moving_speed(value : float):
  move_speed = clamp(value, 0.0, 1.0)
  animation_tree.set(moving_blend_path, move_speed)


func idle() -> void:
  state_machine.travel("DummySkin_Idle")


func walk() -> void:
  state_machine.travel("Move")


func jump() -> void:
  state_machine.travel("DummySkin_Jump_Start")


func fall() -> void:
  state_machine.travel("DummySkin_Jump_Idle")


func land() -> void:
  state_machine.travel("DummySkin_Jump_Land")


func ragdoll() -> void:
  if state_machine.is_playing():
    state_machine.stop()
  #state_machine.travel("DummySkin_T-Pose")
