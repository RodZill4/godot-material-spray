tool
extends Control

var current_brush = {
	size     = 50.0,
	strength = 0.5
}
var albedo_texture_filename = null

onready var brush_material = $Brush.material

signal material_changed(new_material)
signal brush_changed(new_brush)

func _ready():
	update_material()

func update_material():
	current_brush.has_albedo = $VBoxContainer/Albedo.pressed
	current_brush.albedo_color = $VBoxContainer/AlbedoColor.color
	current_brush.albedo_texture_mode = $VBoxContainer/AlbedoTextureMode.selected
	current_brush.albedo_texture_file_name = albedo_texture_filename
	current_brush.albedo_texture = $VBoxContainer/AlbedoTexture.material.get_shader_param("tex")
	current_brush.has_metallic = $VBoxContainer/Metallic.pressed
	current_brush.metallic = $VBoxContainer/MetallicValue.value
	current_brush.has_roughness = $VBoxContainer/Roughness.pressed
	current_brush.roughness = $VBoxContainer/RoughnessValue.value
	emit_signal("material_changed", current_brush)

func _on_Checkbox_pressed():
	update_material()

func _on_Color_color_changed(color):
	update_material()

func _on_HSlider_value_changed(value):
	update_material()

func _on_OptionButton_item_selected(ID):
	update_material()

func _on_AlbedoTexture_gui_input(event):
	if event is InputEventMouseButton:
		var dialog = FileDialog.new()
		add_child(dialog)
		dialog.rect_min_size = Vector2(500, 500)
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.mode = FileDialog.MODE_OPEN_FILE
		dialog.add_filter("*.png;PNG image")
		dialog.connect("file_selected", self, "do_load_albedo_texture")
		dialog.popup_centered()

func do_load_albedo_texture(filename):
	albedo_texture_filename = filename
	$VBoxContainer/AlbedoTexture.material.set_shader_param("tex", load(filename))
	update_material()

func change_size(s):
	print(current_brush)
	current_brush.size += s.x*0.1
	current_brush.size = clamp(current_brush.size, 0.0, 250.0)
	current_brush.strength += s.y*0.01
	current_brush.strength = clamp(current_brush.strength, 0.0, 0.999)
	update_brush()

func update_brush():
	var brush_size_vector = Vector2(current_brush.size, current_brush.size)/rect_size
	if brush_material != null:
		brush_material.set_shader_param("brush_size", brush_size_vector)
		brush_material.set_shader_param("brush_strength", current_brush.strength)
	emit_signal("material_changed", current_brush)

func _on_Brush_resized():
	update_brush()

