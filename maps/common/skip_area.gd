class_name SkipArea extends Area3D

signal item_added(item: CarryableItem)
signal item_removed(item: CarryableItem)

@onready var _label: Label3D = $Label3D
var total_count := 0


func _ready() -> void:
	body_entered.connect(func(_body: Node3D):
		if _body is CarryableBinBag:
			total_count += _body.total_count
			_label.text = str(total_count)
			item_added.emit(_body)
		elif _body is CarryableItem:
			total_count += 1
			_label.text = str(total_count)
			item_added.emit(_body)
	)
	body_exited.connect(func(_body: Node3D):
		if _body is CarryableBinBag:
			total_count -= _body.total_count
			_label.text = str(total_count)
			item_removed.emit(_body)
		elif _body is CarryableItem:
			total_count -= 1
			_label.text = str(total_count)
			item_removed.emit(_body)
	)
	return
