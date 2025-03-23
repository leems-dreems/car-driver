extends InteractableArea

@export var dialogic_timeline: DialogicTimeline


func can_interact_short_press() -> bool:
	return true


func interact_short_press() -> void:
	Dialogic.start(dialogic_timeline)
	return
