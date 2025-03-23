class_name SkipArea extends Area3D

signal item_added(item: CarryableItem)
signal item_removed(item: CarryableItem)

@onready var _label: Label3D = $Label3D


func _ready() -> void:
	body_entered.connect(func(_body: Node3D):
		if _body is CarryableItem:
			_label.text = str(len(get_overlapping_bodies()))
			item_added.emit(_body)
	)
	body_exited.connect(func(_body: Node3D):
		if _body is CarryableItem:
			_label.text = str(len(get_overlapping_bodies()))
			item_removed.emit(_body)
	)
	return
