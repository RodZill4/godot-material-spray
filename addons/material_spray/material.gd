tool
extends VBoxContainer

var current_material = { }

signal material_changed(new_material)

func _ready():
	update_material()

func update_material():
	current_material.has_albedo = $Albedo.pressed
	current_material.albedo_color = $AlbedoColor.color
	current_material.albedo_texture_mode = $AlbedoTextureMode.selected
	#current_material.albedo_texture_file_name = ???
	current_material.albedo_texture = $AlbedoTexture.material.get_shader_param("tex")
	current_material.has_metallic = $Metallic.pressed
	current_material.metallic = $MetallicValue.value
	current_material.has_roughness = $Roughness.pressed
	current_material.roughness = $RoughnessValue.value
	emit_signal("material_changed", current_material)

func _on_Checkbox_pressed():
	update_material()

func _on_Color_color_changed(color):
	update_material()

func _on_HSlider_value_changed(value):
	update_material()
