tool
extends Node

onready var view_to_texture = $View2Texture
onready var view_to_texture_viewport = $View2Texture
onready var view_to_texture_mesh = $View2Texture/PaintedMesh
onready var view_to_texture_camera = $View2Texture/Camera

onready var texture_to_view_viewport = $Texture2View
onready var texture_to_view_mesh = $Texture2View/PaintedMesh
onready var texture_to_view_mesh_white = $Texture2View/PaintedMeshWhite

onready var texture_to_view_lsb_viewport = $Texture2ViewLsb
onready var texture_to_view_lsb_mesh = $Texture2ViewLsb/PaintedMesh

onready var texture_to_view_without_seams_viewport = $Texture2ViewWithoutSeams
onready var texture_to_view_without_seams_rect = $Texture2ViewWithoutSeams/Rect

onready var texture_to_view_lsb_without_seams_viewport = $Texture2ViewLsbWithoutSeams
onready var texture_to_view_lsb_without_seams_rect = $Texture2ViewLsbWithoutSeams/Rect

onready var seams_viewport = $Seams
onready var seams_rect = $Seams/SeamsRect
onready var seams_material = seams_rect.get_material()

onready var albedo_viewport = $AlbedoPaint
onready var albedo_initrect = $AlbedoPaint/InitRect
onready var albedo_paintrect = $AlbedoPaint/PaintRect
onready var albedo_material = albedo_paintrect.get_material()

onready var mr_viewport = $MRPaint
onready var mr_initrect = $MRPaint/InitRect
onready var mr_paintrect = $MRPaint/PaintRect
onready var mr_material = $MRPaint/PaintRect.get_material()

onready var emission_viewport = $EmissionPaint
onready var emission_initrect = $EmissionPaint/InitRect
onready var emission_paintrect = $EmissionPaint/PaintRect
onready var emission_material = $EmissionPaint/PaintRect.get_material()

onready var depth_viewport = $DepthPaint
onready var depth_initrect = $DepthPaint/InitRect
onready var depth_paintrect = $DepthPaint/PaintRect
onready var depth_material = $DepthPaint/PaintRect.get_material()

onready var nm_viewport = $NormalMap
onready var nm_rect = $NormalMap/Rect
onready var nm_material = $NormalMap/Rect.get_material()

var camera
var transform
var viewport_size

var current_brush = null

func _ready():
	# add View2Texture as input of Texture2View (to ignore non-visible parts of the mesh)
	texture_to_view_mesh.get_surface_material(0).set_shader_param("view2texture", view_to_texture_viewport.get_texture())
	texture_to_view_lsb_mesh.get_surface_material(0).set_shader_param("view2texture", view_to_texture_viewport.get_texture())
	# Add Texture2ViewWithoutSeams as input to all painted textures
	albedo_material.set_shader_param("tex2view_tex", texture_to_view_viewport.get_texture())
	albedo_material.set_shader_param("tex2viewlsb_tex", texture_to_view_lsb_viewport.get_texture())
	albedo_material.set_shader_param("seams", seams_viewport.get_texture())
	mr_material.set_shader_param("tex2view_tex", texture_to_view_viewport.get_texture())
	mr_material.set_shader_param("tex2viewlsb_tex", texture_to_view_lsb_viewport.get_texture())
	mr_material.set_shader_param("seams", seams_viewport.get_texture())
	emission_material.set_shader_param("tex2view_tex", texture_to_view_viewport.get_texture())
	emission_material.set_shader_param("tex2viewlsb_tex", texture_to_view_lsb_viewport.get_texture())
	emission_material.set_shader_param("seams", seams_viewport.get_texture())
	depth_material.set_shader_param("tex2view_tex", texture_to_view_viewport.get_texture())
	depth_material.set_shader_param("tex2viewlsb_tex", texture_to_view_lsb_viewport.get_texture())
	depth_material.set_shader_param("seams", seams_viewport.get_texture())
	nm_material.set_shader_param("tex", depth_viewport.get_texture())
	nm_material.set_shader_param("seams", seams_viewport.get_texture())
	# Add Texture2View as input to seams texture
	seams_material.set_shader_param("tex", texture_to_view_viewport.get_texture())
	# Assign all textures to painted mesh
	albedo_viewport.get_texture().flags |= Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER
	mr_viewport.get_texture().flags |= Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER
	emission_viewport.get_texture().flags |= Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER
	depth_viewport.get_texture().flags |= Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER

func update_seams_texture():
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	texture_to_view_viewport.update_worlds()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	seams_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	seams_viewport.update_worlds()

func set_mesh(m : Mesh):
	var mat : Material
	mat = texture_to_view_mesh.get_surface_material(0)
	texture_to_view_mesh.mesh = m
	texture_to_view_mesh.set_surface_material(0, mat)
	mat = texture_to_view_mesh_white.get_surface_material(0)
	texture_to_view_mesh_white.mesh = m
	texture_to_view_mesh_white.set_surface_material(0, mat)
	mat = texture_to_view_lsb_mesh.get_surface_material(0)
	texture_to_view_lsb_mesh.mesh = m
	texture_to_view_lsb_mesh.set_surface_material(0, mat)
	mat = view_to_texture_mesh.get_surface_material(0)
	view_to_texture_mesh.mesh = m
	view_to_texture_mesh.set_surface_material(0, mat)
	update_seams_texture()

func calculate_mask(value : float, channel : int) -> Color:
	if (channel == SpatialMaterial.TEXTURE_CHANNEL_RED):
		return Color(value, 0, 0, 0)
	elif (channel == SpatialMaterial.TEXTURE_CHANNEL_GREEN):
		return Color(0, value, 0, 0)
	elif (channel == SpatialMaterial.TEXTURE_CHANNEL_BLUE):
		return Color(0, 0, value, 0)
	elif (channel == SpatialMaterial.TEXTURE_CHANNEL_ALPHA):
		return Color(0, 0, 0, value)
	return Color(0, 0, 0, 0)

func init_textures(m : SpatialMaterial):
	albedo_initrect.show()
	albedo_initrect.material.set_shader_param("col", m.albedo_color)
	albedo_initrect.material.set_shader_param("tex", m.albedo_texture)
	albedo_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	albedo_viewport.update_worlds()
	mr_initrect.show()
	mr_initrect.material.set_shader_param("metallic", m.metallic_texture)
	mr_initrect.material.set_shader_param("metallic_mask", calculate_mask(m.metallic, m.metallic_texture_channel))
	mr_initrect.material.set_shader_param("roughness", m.roughness_texture)
	mr_initrect.material.set_shader_param("roughness_mask", calculate_mask(m.roughness, m.roughness_texture_channel))
	mr_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	mr_viewport.update_worlds()
	emission_initrect.show()
	if m.emission_enabled:
		emission_initrect.material.set_shader_param("col", m.emission)
		emission_initrect.material.set_shader_param("tex", m.emission_texture)
	else:
		emission_initrect.material.set_shader_param("col", Color(0.0, 0.0, 0.0))
		emission_initrect.material.set_shader_param("tex", null)
	emission_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	emission_viewport.update_worlds()
	if m.depth_enabled:
		depth_initrect.material.set_shader_param("col", Color(1.0, 1.0, 1.0))
		depth_initrect.material.set_shader_param("tex", m.depth_texture)
	else:
		depth_initrect.material.set_shader_param("col", Color(0.0, 0.0, 0.0))
		depth_initrect.material.set_shader_param("tex", null)
	depth_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	depth_viewport.update_worlds()
	depth_initrect.show()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	albedo_initrect.hide()
	mr_initrect.hide()
	emission_initrect.hide()
	depth_initrect.hide()
	nm_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	nm_viewport.update_worlds()

func set_texture_size(s : float):
	texture_to_view_viewport.size = Vector2(s, s)
	texture_to_view_lsb_viewport.size = Vector2(s, s)
	albedo_viewport.size = Vector2(s, s)
	albedo_paintrect.rect_size = Vector2(s, s)
	albedo_initrect.rect_size = Vector2(s, s)
	mr_viewport.size = Vector2(s, s)
	mr_paintrect.rect_size = Vector2(s, s)
	mr_initrect.rect_size = Vector2(s, s)
	emission_viewport.size = Vector2(s, s)
	emission_paintrect.rect_size = Vector2(s, s)
	emission_initrect.rect_size = Vector2(s, s)
	depth_viewport.size = Vector2(s, s)
	depth_paintrect.rect_size = Vector2(s, s)
	depth_initrect.rect_size = Vector2(s, s)
	nm_viewport.size = Vector2(s, s)
	nm_rect.rect_size = Vector2(s, s)

func update_view(c, t, s):
	camera = c
	transform = t
	viewport_size = s
	update_tex2view()

func update_tex2view():
	var aspect = viewport_size.x/viewport_size.y
	view_to_texture_viewport.size = 2.0*viewport_size
	view_to_texture_camera.transform = camera.global_transform
	view_to_texture_camera.fov = camera.fov
	view_to_texture_camera.near = camera.near
	view_to_texture_camera.far = camera.far
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
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
		viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		viewport.update_worlds()

func brush_changed(new_brush):
	current_brush = new_brush
	# AMR
	albedo_material.set_shader_param("brush_color", current_brush.albedo_color)
	var alpha = current_brush.albedo_color.a
	albedo_material.set_shader_param("brush_channelmask", Color(alpha, alpha, alpha))
	albedo_material.set_shader_param("brush_texture", current_brush.albedo_texture)
	albedo_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
	albedo_material.set_shader_param("texture_angle", current_brush.texture_angle)
	albedo_material.set_shader_param("stamp_mode", current_brush.albedo_texture_mode == 1)
	albedo_material.set_shader_param("texture_mask", Color(1.0, 1.0, 1.0, 1.0))
	mr_material.set_shader_param("brush_color", Color(current_brush.metallic, current_brush.roughness, 0.0))
	mr_material.set_shader_param("brush_channelmask", Color(1.0 if current_brush.has_metallic else 0.0, 1.0 if current_brush.has_roughness else 0.0, 1.0))
	mr_material.set_shader_param("brush_texture", current_brush.albedo_texture)
	mr_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
	mr_material.set_shader_param("texture_angle", current_brush.texture_angle)
	mr_material.set_shader_param("stamp_mode", current_brush.albedo_texture_mode == 1)
	mr_material.set_shader_param("texture_mask", Color(0.0, 0.0, 0.0, 1.0))
	# Emission
	emission_material.set_shader_param("brush_color", current_brush.emission_color)
	alpha = current_brush.emission_color.a
	emission_material.set_shader_param("brush_channelmask", Color(alpha, alpha, alpha))
	emission_material.set_shader_param("brush_texture", current_brush.emission_texture)
	emission_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
	emission_material.set_shader_param("texture_angle", current_brush.texture_angle)
	emission_material.set_shader_param("stamp_mode", current_brush.emission_texture_mode == 1)
	emission_material.set_shader_param("texture_mask", Color(1.0, 1.0, 1.0, 1.0))
	# Depth
	depth_material.set_shader_param("brush_color", current_brush.depth_color)
	alpha = current_brush.depth_color.a
	depth_material.set_shader_param("brush_channelmask", Color(alpha, alpha, alpha))
	depth_material.set_shader_param("brush_texture", current_brush.depth_texture)
	depth_material.set_shader_param("pattern_scale", current_brush.pattern_scale)
	depth_material.set_shader_param("texture_angle", current_brush.texture_angle)
	depth_material.set_shader_param("stamp_mode", current_brush.depth_texture_mode == 1)
	depth_material.set_shader_param("texture_mask", Color(1.0, 1.0, 1.0, 1.0))
	if viewport_size != null:
		var brush_size_vector = Vector2(current_brush.size, current_brush.size)/viewport_size
		if albedo_material != null:
			albedo_material.set_shader_param("brush_size", brush_size_vector)
			albedo_material.set_shader_param("brush_strength", current_brush.strength)
		if mr_material != null:
			mr_material.set_shader_param("brush_size", brush_size_vector)
			mr_material.set_shader_param("brush_strength", current_brush.strength)
		if emission_material != null:
			emission_material.set_shader_param("brush_size", brush_size_vector)
			emission_material.set_shader_param("brush_strength", current_brush.strength)
		if depth_material != null:
			depth_material.set_shader_param("brush_size", brush_size_vector)
			depth_material.set_shader_param("brush_strength", current_brush.strength)

func do_paint(position, prev_position):
	if current_brush.has_albedo:
		albedo_material.set_shader_param("brush_pos", position)
		albedo_material.set_shader_param("brush_ppos", prev_position)
		albedo_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		albedo_viewport.update_worlds()
	if current_brush.has_metallic or current_brush.has_roughness:
		mr_material.set_shader_param("brush_pos", position)
		mr_material.set_shader_param("brush_ppos", prev_position)
		mr_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		mr_viewport.update_worlds()
	if current_brush.has_emission:
		emission_material.set_shader_param("brush_pos", position)
		emission_material.set_shader_param("brush_ppos", prev_position)
		emission_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		emission_viewport.update_worlds()
	if current_brush.has_depth:
		depth_material.set_shader_param("brush_pos", position)
		depth_material.set_shader_param("brush_ppos", prev_position)
		depth_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		depth_viewport.update_worlds()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		nm_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		nm_viewport.update_worlds()


func get_albedo_texture():
	return albedo_viewport.get_texture()

func get_mr_texture():
	return mr_viewport.get_texture()

func get_emission_texture():
	return emission_viewport.get_texture()

func get_normal_map():
	return nm_viewport.get_texture()
	
func get_depth_texture():
	return depth_viewport.get_texture()

func save_viewport(v : Viewport, f : String):
	v.get_texture().get_data().save_png(f)

func debug_save_textures():
	save_viewport(view_to_texture_viewport, "v2t.png")
	save_viewport(texture_to_view_viewport, "t2v.png")
	save_viewport(texture_to_view_lsb_viewport, "t2vlsb.png")
	save_viewport(seams_viewport, "seams.png")

func debug_get_texture(ID):
	if ID == 1:
		return view_to_texture_viewport.get_texture()
	elif ID == 2:
		return texture_to_view_viewport.get_texture()
	elif ID == 3:
		return texture_to_view_lsb_viewport.get_texture()
	elif ID == 4:
		return seams_viewport.get_texture()
	elif ID == 5:
		return albedo_viewport.get_texture()
	elif ID == 6:
		return mr_viewport.get_texture()
	elif ID == 7:
		return emission_viewport.get_texture()
	elif ID == 8:
		return depth_viewport.get_texture()
	elif ID == 9:
		return nm_viewport.get_texture()
	return null
