extends SettingOptionButton


func apply_value(_index: int) -> void:
	var _scale := get_item_text(_index).to_float()
	get_viewport().scaling_3d_scale = _scale
	return
