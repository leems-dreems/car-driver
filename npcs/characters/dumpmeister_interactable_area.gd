extends NPCInteractArea

var summon_car_at_end := false


func process_tags(_tags: Array) -> void:
	if _tags.has("SUMMON_CAR"):
		summon_car_at_end = true
	return


func process_end() -> void:
	if summon_car_at_end:
		Game.summon_car()
	summon_car_at_end = false
	return
