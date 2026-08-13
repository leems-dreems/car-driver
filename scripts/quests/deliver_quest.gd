class_name DeliverQuest extends Quest

@export var item_types: Array[Globals.Item_Types]:
	set(value):
		item_types = value
		if is_node_ready():
			changed.emit()
@export var items: Array[CarryableItem]:
	set(value):
		items = value
		if is_node_ready():
			changed.emit()
@export var target_npcs: Array[NPC]:
	set(value):
		target_npcs = value
		if is_node_ready():
			changed.emit()


func _init(
		_quest_name: String = "Unnamed Quest",
		_quest_giver: NPC = null,
		_sub_quests: Array[Quest] = [],
		_target_markers: Array[InteractableArea] = [],
		_item_types: Array[Globals.Item_Types] = [],
		_items: Array[CarryableItem] = [],
		_target_npcs: Array[NPC] = [],
		_target_vehicles: Array[DriveableVehicle] = []
		) -> void:
	quest_name = _quest_name
	quest_giver = _quest_giver
	sub_quests = _sub_quests
	target_markers = _target_markers
	item_types = _item_types
	items = _items
	target_npcs = _target_npcs
	return
