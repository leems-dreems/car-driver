extends SettingOptionButton


func apply_value(_index: int) -> void:
	match _index:
		0:
			get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			get_viewport().msaa_3d = Viewport.MSAA_4X
		1:
			get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
			get_viewport().msaa_3d = Viewport.MSAA_4X
		2:
			get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	return
