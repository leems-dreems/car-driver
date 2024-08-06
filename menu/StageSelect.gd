extends Node2D

@onready var stage_list: ItemList = %StageList

#you just have to manually name levels and put paths here
var stages_dictionary = {
    OG_City = "res://city_scene.tscn",
    Kay_Kit_City = "res://maps/KayKitCity/kay_kit_city.tscn"
}

func _ready() -> void:
    stage_list.select_mode = 0 #set single select only
    for stage in stages_dictionary:
        var i = stage_list.add_item(stage)
        stage_list.set_item_metadata(i, stages_dictionary[stage])


func _on_load_button_pressed() -> void:
    var selectedItemIndex = stage_list.get_selected_items()[0]
    var filePath = stage_list.get_item_metadata(selectedItemIndex)
    get_tree().change_scene_to_file(filePath)


func _on_cancel_button_pressed() -> void:
    queue_free()
