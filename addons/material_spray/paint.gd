tool
extends ViewportContainer

const MODE_FREE       = 0
const MODE_LINE       = 1
const MODE_LINE_STRIP = 2

var current_tool = MODE_FREE

var texture_scale = 2.0

var previous_position = null
var painting = false
var next_paint_to = null

var key_rotate = Vector2(0.0, 0.0)

var object_name = null

onready var painter = $Painter

onready var brush = $Brush
onready var brush_material = $Brush/Brush.get_material()

const MATERIAL_OPTIONS = [ "none", "bricks", "metal_pattern", "rusted_metal", "wooden_floor" ]

signal update_material

func _ready():
	# Assign all textures to painted mesh
	$MainView/PaintedMesh.set_surface_material(0, SpatialMaterial.new())
	# Updated Texture2View wrt current camera position
	update_view()
	# Set size of painted textures
	set_texture_size(2048)
	# Disable physics process so we avoid useless updates of tex2view textures
	set_physics_process(false)
	set_current_tool(MODE_FREE)

func set_object(o):
	object_name = o.name
	var mat = o.get_surface_material(0)
	if mat == null:
		mat = o.mesh.surface_get_material(0)
	if mat == null:
		mat = SpatialMaterial.new()
	var new_mat = SpatialMaterial.new()
	new_mat.albedo_texture = painter.get_albedo_texture()
	new_mat.metallic = 1.0
	new_mat.metallic_texture = painter.get_mr_texture()
	new_mat.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	new_mat.roughness = 1.0
	new_mat.roughness_texture = painter.get_mr_texture()
	new_mat.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
	new_mat.emission_enabled = true
	new_mat.emission = Color(0.0, 0.0, 0.0, 0.0)
	new_mat.emission_texture = painter.get_emission_texture()
	new_mat.normal_enabled = true
	new_mat.normal_texture = painter.get_normal_map()
	new_mat.depth_enabled = true
	new_mat.depth_deep_parallax = true
	new_mat.depth_texture = painter.get_depth_texture()
	$MainView/PaintedMesh.mesh = o.mesh
	$MainView/PaintedMesh.set_surface_material(0, new_mat)
	painter.set_mesh(o.mesh)
	update_view()
	painter.init_textures(mat)

func set_texture_size(s):
	painter.set_texture_size(s)

func set_current_tool(m):
	current_tool = m
	for i in $Tools.get_child_count():
		$Tools.get_child(i).pressed = (i == m)

func _physics_process(delta):
	$MainView/CameraStand.rotate($MainView/CameraStand/Camera.global_transform.basis.x.normalized(), -key_rotate.y*delta)
	$MainView/CameraStand.rotate(Vector3(0, 1, 0), -key_rotate.x*delta)
	update_view()

func _input(ev):
	if ev is InputEventKey:
		if ev.scancode == KEY_CONTROL:
			$Brush.show_pattern(ev.pressed)
		elif ev.scancode == KEY_LEFT or ev.scancode == KEY_RIGHT or ev.scancode == KEY_UP or ev.scancode == KEY_DOWN:
			key_rotate = Vector2(0.0, 0.0)
			if Input.is_key_pressed(KEY_UP):
				key_rotate.y -= 1.0
			if Input.is_key_pressed(KEY_DOWN):
				key_rotate.y += 1.0
			if Input.is_key_pressed(KEY_LEFT):
				key_rotate.x -= 1.0
			if Input.is_key_pressed(KEY_RIGHT):
				key_rotate.x += 1.0
			set_physics_process(key_rotate != Vector2(0.0, 0.0))

func _on_MaterialSpray_gui_input(ev):
	if ev is InputEventMouseMotion:
		show_brush(ev.position, previous_position)
		if ev.button_mask & BUTTON_MASK_RIGHT != 0:
			if ev.shift:
				$MainView/CameraStand.translate(-0.2*ev.relative.x*$MainView/CameraStand/Camera.transform.basis.x)
				$MainView/CameraStand.translate(0.2*ev.relative.y*$MainView/CameraStand/Camera.transform.basis.y)
			else:
				$MainView/CameraStand.rotate($MainView/CameraStand/Camera.global_transform.basis.x.normalized(), -0.01*ev.relative.y)
				$MainView/CameraStand.rotate(Vector3(0, 1, 0), -0.01*ev.relative.x)
		if ev.button_mask & BUTTON_MASK_LEFT != 0:
			if ev.control:
				previous_position = null
				brush.edit_pattern(ev.relative)
			elif ev.shift:
				previous_position = null
				brush.edit_brush(ev.relative)
			elif current_tool == MODE_FREE:
				paint(ev.position)
		elif current_tool != MODE_LINE_STRIP:
			previous_position = null
	elif ev is InputEventMouseButton:
		var pos = ev.position
		if !ev.control and !ev.shift:
			if ev.button_index == BUTTON_LEFT:
				if ev.pressed:
					if current_tool == MODE_LINE_STRIP && previous_position != null:
						paint(pos)
						if ev.doubleclick:
							pos = null
					previous_position = pos
				elif current_tool != MODE_LINE_STRIP:
					paint(pos)
					previous_position = null
		var zoom = 0.0
		if ev.button_index == BUTTON_WHEEL_UP:
			zoom -= 1.0
		elif ev.button_index == BUTTON_WHEEL_DOWN:
			zoom += 1.0
		if zoom != 0.0:
			$MainView/CameraStand/Camera.translate(Vector3(0.0, 0.0, zoom*(1.0 if ev.shift else 0.1)))
			update_view()
		if !ev.pressed and ev.button_index == BUTTON_RIGHT:
			update_view()

func show_brush(p, op = null):
	if op == null:
		op = p
	var position = p/rect_size
	var old_position = op/rect_size
	brush_material.set_shader_param("brush_pos", position)
	brush_material.set_shader_param("brush_ppos", old_position)

func paint(p):
	if painting:
		# if not available for painting, record a paint order
		next_paint_to = p
		return
	painting = true
	if previous_position == null:
		previous_position = p
	var position = p/rect_size
	var prev_position = previous_position/rect_size
	painter.do_paint(position, prev_position)
	previous_position = p
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	painting = false
	# execute recorded paint order if any
	if next_paint_to != null:
		p = next_paint_to
		next_paint_to = null
		paint(p)

func update_view():
	var mesh_instance = $MainView/PaintedMesh
	var mesh_aabb = mesh_instance.get_aabb()
	var mesh_center = mesh_aabb.position+0.5*mesh_aabb.size
	var mesh_size = 0.5*mesh_aabb.size.length()
	var camera = $MainView/CameraStand/Camera
	var cam_to_center = (camera.global_transform.origin-mesh_center).length()
	camera.near = max(1.0, cam_to_center-mesh_size)
	camera.far = cam_to_center+mesh_size
	var transform = camera.global_transform.affine_inverse()*$MainView/PaintedMesh.global_transform
	if painter != null:
		painter.update_view(camera, transform, $MainView.size)

func load_material():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.add_filter("*.paintmat;Paint material")
	dialog.connect("file_selected", self, "do_load_material")
	dialog.popup_centered()

func do_load_material(filename):
	pass

func _on_resized():
	update_view()

func dump_texture(texture, filename):
	var image = texture.get_data()
	image.save_png(filename)

func save():
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.add_filter("*.tres;Spatial material")
	dialog.connect("file_selected", self, "do_save")
	dialog.popup_centered()

func do_save(file_name):
	var prefix = file_name.replace(".tres", "")
	var mat = $MainView/PaintedMesh.get_surface_material(0).duplicate()
	dump_texture(painter.get_albedo_texture(), prefix+"_albedo.png")
	dump_texture(painter.get_mr_texture(), prefix+"_mr.png")
	dump_texture(painter.get_emission_texture(), prefix+"_emission.png")
	dump_texture(painter.get_normal_map(), prefix+"_nm.png")
	dump_texture(painter.get_depth_texture(), prefix+"_depth.png")
	emit_signal("update_material", { material=mat, material_file=file_name, albedo=prefix+"_albedo.png", mr=prefix+"_mr.png", emission=prefix+"_emission.png", nm=prefix+"_nm.png", depth=prefix+"_depth.png" })

func _on_DebugSelect_item_selected(ID, t):
	var texture = [$Debug/Texture1, $Debug/Texture2][t]
	texture.visible = (ID != 0)
	texture.texture = $Painter.debug_get_texture(ID)
