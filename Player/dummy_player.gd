class_name DummyCharacterSkin extends Node3D

@onready var animation_player := $AnimationPlayer


func idle() -> void:
  animation_player.play("Idle")


func walk() -> void:
  animation_player.play("Walking_A")


func run() -> void:
  animation_player.play("Running_A")


func jump() -> void:
  animation_player.play("Jump_Start")


func fall() -> void:
  animation_player.play("Jump_Idle")
