tool
extends EditorPlugin

var edited_object = null
var paint_button = null
var paint_tool = null

func _exit_tree():
	if paint_button != null:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, paint_button)
		paint_button.queue_free()
		paint_button = null
	if paint_tool != null:
		paint_tool.hide()
		paint_tool.queue_free()
		paint_tool = null

func _get_state():
	var s = { paint_button=paint_button, paint_tool=paint_tool, edited_object=edited_object }
	return s

func _set_state(s):
	paint_button = s.paint_button
	paint_tool = s.paint_tool
	edited_object = s.edited_object

func handles(object):
	return object is MeshInstance

func edit(object):
	edited_object = object

func make_visible(b):
	if b:
		paint_button = preload("res://addons/material_spray/paint_button.tscn").instance()
		paint_button.connect("pressed", self, "paint")
		add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, paint_button)
	else:
		edited_object = null
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, paint_button)
		paint_button.free()
		paint_button = null

func paint():
	paint_tool = preload("res://addons/material_spray/paint_window.tscn").instance()
	add_child(paint_tool)
	paint_tool.set_object(edited_object)
	paint_tool.connect("popup_hide", self, "free_paint_tool")
	paint_tool.get_node("PaintTool").connect("update_material", self, "assign_material")
	paint_tool.popup_centered()

func free_paint_tool():
	paint_tool.queue_free()
	paint_tool = null

func assign_material(m):
	var texture
	var editor_file_system = get_editor_interface().get_resource_filesystem()
	editor_file_system.scan()
	editor_file_system.update_file(m.albedo)
	editor_file_system.update_file(m.mr)
	editor_file_system.update_file(m.nm)
	texture = load(m.albedo)
	m.material.albedo_texture = texture
	texture = load(m.mr)
	m.material.metallic_texture = texture
	m.material.roughness_texture = texture
	texture = load(m.nm)
	m.material.normal_texture = texture
	edited_object.set_surface_material(0, m.material)
