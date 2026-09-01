class_name DeliverQuest extends Quest


func _init(
		_quest_name: String = "Unnamed Quest",
		_quest_giver: NPC = null,
		_target_markers: Array[InteractableArea] = [],
		_item_types: Array[Globals.Item_Types] = [],
		_items: Array[CarryableItem] = [],
		_target_npcs: Array[NPC] = [],
		_target_vehicles: Array[DriveableVehicle] = []
		) -> void:
	quest_name = _quest_name
	quest_giver = _quest_giver
	target_markers = _target_markers
	item_types = _item_types
	items = _items
	target_npcs = _target_npcs
	target_vehicles = _target_vehicles
	return
