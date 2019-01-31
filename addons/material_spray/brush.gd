tool
extends Control

var current_brush = {
	size          = 50.0,
	strength      = 0.5,
	pattern_scale = 10.0,
	texture_angle = 0.0
}
var albedo_texture_filename = null
var albedo_texture = null

onready var brush_material = $Brush.material
onready var pattern_material = $Pattern.material

signal brush_changed(new_brush)

func _ready():
	$BrushUI/AlbedoTexture.material = $BrushUI/AlbedoTexture.material.duplicate()
	update_material()

func edit_brush(s):
	current_brush.size += s.x*0.1
	current_brush.size = clamp(current_brush.size, 0.0, 250.0)
	if current_brush.albedo_texture_mode == 1:
		current_brush.texture_angle += fmod(s.y*0.01, 2.0*PI)
	else:
		current_brush.strength += s.y*0.01
		current_brush.strength = clamp(current_brush.strength, 0.0, 0.999)
	update_brush()

func show_pattern(b):
	$Pattern.visible = b and ($BrushUI/AlbedoTextureMode.selected == 2)

func edit_pattern(s):
	current_brush.pattern_scale += s.x*0.1
	current_brush.pattern_scale = clamp(current_brush.pattern_scale, 0.1, 25.0)
	current_brush.texture_angle += fmod(s.y*0.01, 2.0*PI)
	update_brush()

func update_brush():
	if current_brush.albedo_texture_mode != 2:
		$Pattern.visible = false
	var brush_size_vector = Vector2(current_brush.size, current_brush.size)/rect_size
	if brush_material != null:
		brush_material.set_shader_param("brush_size", brush_size_vector)
		brush_material.set_shader_param("brush_strength", current_brush.strength)
		brush_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
		brush_material.set_shader_param("texture_angle", current_brush.texture_angle)
		brush_material.set_shader_param("brush_texture", current_brush.albedo_texture)
		brush_material.set_shader_param("stamp_mode", current_brush.albedo_texture_mode == 1)
	if pattern_material != null:
		pattern_material.set_shader_param("brush_size", brush_size_vector)
		pattern_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
		pattern_material.set_shader_param("texture_angle", current_brush.texture_angle)
		pattern_material.set_shader_param("brush_texture", current_brush.albedo_texture)
	emit_signal("brush_changed", current_brush)

func update_material():
	current_brush.has_albedo = $BrushUI/Albedo.pressed
	current_brush.albedo_color = $BrushUI/AlbedoColor.color
	current_brush.albedo_texture_mode = $BrushUI/AlbedoTextureMode.selected
	if current_brush.albedo_texture_mode != 0:
		current_brush.albedo_texture = albedo_texture
		current_brush.albedo_texture_file_name = albedo_texture_filename
	else:
		current_brush.albedo_texture = null
		current_brush.albedo_texture_file_name = null
	current_brush.has_metallic = $BrushUI/Metallic.pressed
	current_brush.metallic = $BrushUI/MetallicValue.value
	current_brush.has_roughness = $BrushUI/Roughness.pressed
	current_brush.roughness = $BrushUI/RoughnessValue.value
	update_brush()

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
	albedo_texture = load(filename)
	$BrushUI/AlbedoTexture.material.set_shader_param("tex", albedo_texture)
	update_material()

func _on_Brush_resized():
	update_brush()

