tool
extends Node

onready var view_to_texture = $View2Texture
onready var view_to_texture_viewport = $View2Texture/Viewport
onready var view_to_texture_mesh = $View2Texture/Viewport/PaintedMesh
onready var view_to_texture_camera = $View2Texture/Viewport/Camera

onready var texture_to_view = $Texture2View
onready var texture_to_view_viewport = $Texture2View/Viewport
onready var texture_to_view_mesh = $Texture2View/Viewport/PaintedMesh

onready var texture_to_view_lsb = $Texture2ViewLsb
onready var texture_to_view_lsb_viewport = $Texture2ViewLsb/Viewport
onready var texture_to_view_lsb_mesh = $Texture2ViewLsb/Viewport/PaintedMesh

onready var albedo_viewport = $AlbedoPaint/Viewport
onready var albedo_initrect = $AlbedoPaint/Viewport/InitRect
onready var albedo_paintrect = $AlbedoPaint/Viewport/PaintRect
onready var albedo_material = albedo_paintrect.get_material()

onready var mr_viewport = $MRPaint/Viewport
onready var mr_initrect = $MRPaint/Viewport/InitRect
onready var mr_paintrect = $MRPaint/Viewport/PaintRect
onready var mr_material = $MRPaint/Viewport/PaintRect.get_material()

var camera
var transform
var viewport_size

var current_material = null

func _ready():
	# add View2Texture as input of Texture2View (to ignore non-visible parts of the mesh)
	texture_to_view_mesh.get_surface_material(0).set_shader_param("view2texture", view_to_texture_viewport.get_texture())
	texture_to_view_lsb_mesh.get_surface_material(0).set_shader_param("view2texture", view_to_texture_viewport.get_texture())
	# Add Texture2View as input to all painted textures
	albedo_material.set_shader_param("tex2view_tex", texture_to_view_viewport.get_texture())
	mr_material.set_shader_param("tex2view_tex", texture_to_view_viewport.get_texture())
	albedo_material.set_shader_param("tex2viewlsb_tex", texture_to_view_lsb_viewport.get_texture())
	mr_material.set_shader_param("tex2viewlsb_tex", texture_to_view_lsb_viewport.get_texture())
	# Assign all textures to painted mesh
	albedo_viewport.get_texture().flags |= Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER
	mr_viewport.get_texture().flags |= Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER

func set_mesh(m):
	var mat
	mat = texture_to_view_mesh.get_surface_material(0)
	texture_to_view_mesh.mesh = m
	texture_to_view_mesh.set_surface_material(0, mat)
	mat = texture_to_view_lsb_mesh.get_surface_material(0)
	texture_to_view_lsb_mesh.mesh = m
	texture_to_view_lsb_mesh.set_surface_material(0, mat)
	mat = view_to_texture_mesh.get_surface_material(0)
	view_to_texture_mesh.mesh = m
	view_to_texture_mesh.set_surface_material(0, mat)

func set_texture_size(s):
	texture_to_view_viewport.size = Vector2(s, s)
	texture_to_view_lsb_viewport.size = Vector2(s, s)
	albedo_viewport.size = Vector2(s, s)
	albedo_paintrect.rect_size = Vector2(s, s)
	albedo_initrect.rect_size = Vector2(s, s)
	mr_viewport.size = Vector2(s, s)
	mr_paintrect.rect_size = Vector2(s, s)
	mr_initrect.rect_size = Vector2(s, s)

func change_material(m):
	current_material = m

func update_view(c, t, s):
	camera = c
	transform = t
	viewport_size = s
	update_tex2view()

func update_tex2view():
	var aspect = viewport_size.x/viewport_size.y
	view_to_texture_viewport.size = viewport_size
	view_to_texture_camera.transform = camera.global_transform
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	view_to_texture_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	for material in [ texture_to_view_mesh.get_surface_material(0), texture_to_view_lsb_mesh.get_surface_material(0) ]:
		material.set_shader_param("model_transform", transform)
		material.set_shader_param("fovy_degrees", camera.fov)
		material.set_shader_param("z_near", camera.near)
		material.set_shader_param("z_far", camera.far)
		material.set_shader_param("aspect", aspect)
	for viewport in [ texture_to_view_viewport, texture_to_view_lsb_viewport ]:
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	texture_to_view_lsb_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED

func material_changed(new_material):
	print(new_material)
	current_material = new_material
	albedo_material.set_shader_param("brush_color", current_material.albedo_color)
	var alpha = current_material.albedo_color.a
	albedo_material.set_shader_param("brush_channelmask", Color(alpha, alpha, alpha))
	mr_material.set_shader_param("brush_color", Color(current_material.metallic, current_material.roughness, 0.0))
	mr_material.set_shader_param("brush_channelmask", Color(1.0 if current_material.has_metallic else 0.0, 1.0 if current_material.has_roughness else 0.0, 0.0))

func do_paint(position, prev_position):
	if current_material.has_albedo:
		albedo_material.set_shader_param("brush_pos", position)
		albedo_material.set_shader_param("brush_ppos", prev_position)
		albedo_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		albedo_viewport.update_worlds()
	if current_material.has_metallic or current_material.has_roughness:
		mr_material.set_shader_param("brush_pos", position)
		mr_material.set_shader_param("brush_ppos", prev_position)
		mr_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		mr_viewport.update_worlds()

func get_albedo_texture():
	return albedo_viewport.get_texture()

func get_mr_texture():
	return mr_viewport.get_texture()

func debug_get_texture(ID):
	if ID == 1:
		return view_to_texture_viewport.get_texture()
	elif ID == 2:
		return texture_to_view_viewport.get_texture()
	elif ID == 3:
		return texture_to_view_lsb_viewport.get_texture()
	elif ID == 4:
		return $FixSeams/Viewport.get_texture()
	elif ID == 5:
		return albedo_viewport.get_texture()
	elif ID == 6:
		return mr_viewport.get_texture()
	return null

