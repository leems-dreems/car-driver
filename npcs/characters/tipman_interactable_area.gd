extends NPCInteractArea

var summon_car_at_end := false


func _ready() -> void:
	if get_parent().get("skip_area"):
		var skip_area: SkipArea = get_parent().skip_area
		skip_area.item_added.connect(func(_item: CarryableItem):
			ink_player.set_variable("items_in_skip", skip_area.total_count)
		)
		skip_area.item_removed.connect(func(_item: CarryableItem):
			ink_player.set_variable("items_in_skip", skip_area.total_count)
		)

	super()
	return


func interact_short_press() -> void:
	dialogue_bubble.visible = true
	dialogue_bubble.control.visible = true
	ink_player.choose_path("standard_dialogue")
	continue_story()
	return


func process_tags(_tags: Array) -> void:
	if _tags.has("SUMMON_CAR"):
		summon_car_at_end = true
	return


func process_end() -> void:
	if summon_car_at_end:
		Game.summon_car()
	summon_car_at_end = false
	return
