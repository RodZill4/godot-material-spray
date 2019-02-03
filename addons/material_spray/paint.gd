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
	var mat = $MainView/PaintedMesh.get_surface_material(0)
	mat.albedo_texture = painter.get_albedo_texture()
	mat.metallic = 1.0
	mat.metallic_texture = painter.get_mr_texture()
	mat.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
	mat.roughness = 1.0
	mat.roughness_texture = painter.get_mr_texture()
	mat.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.0, 0.0, 0.0)
	mat.emission_texture = painter.get_emission_texture()
	mat.normal_enabled = true
	mat.normal_texture = painter.get_normal_map()
	mat.depth_enabled = true
	mat.depth_deep_parallax = true
	mat.depth_texture = painter.get_depth_texture()
	$MainView/PaintedMesh.mesh = o.mesh
	$MainView/PaintedMesh.set_surface_material(0, mat)
	painter.set_mesh(o.mesh)
	update_view()
	painter.init_textures(o.get_surface_material(0))

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
	elif ev is InputEventMouseButton and !ev.control and !ev.shift:
		var pos = ev.position
		if ev.pressed:
			var zoom = 0.0
			if ev.button_index == BUTTON_WHEEL_UP:
				zoom -= 0.1
				$MainView/CameraStand/Camera.translate(Vector3(0.0, 0.0, zoom))
				update_view()
			elif ev.button_index == BUTTON_WHEEL_DOWN:
				zoom += 0.1
				$MainView/CameraStand/Camera.translate(Vector3(0.0, 0.0, zoom))
				update_view()
			elif ev.button_index == BUTTON_LEFT:
				if current_tool == MODE_LINE_STRIP && previous_position != null:
					paint(pos)
					if ev.doubleclick:
						pos = null
				previous_position = pos
		else:
			if ev.button_index == BUTTON_RIGHT:
				update_view()
			elif ev.button_index == BUTTON_LEFT:
				if current_tool != MODE_LINE_STRIP:
					paint(pos)
					previous_position = null

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
	var camera = $MainView/CameraStand/Camera
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
	var mat = $MainView/PaintedMesh.get_surface_material(0).duplicate()
	dump_texture(painter.get_albedo_texture(), object_name+"_albedo.png")
	dump_texture(painter.get_mr_texture(), object_name+"_mr.png")
	dump_texture(painter.get_emission_texture(), object_name+"_emission.png")
	dump_texture(painter.get_normal_map(), object_name+"_nm.png")
	dump_texture(painter.get_depth_texture(), object_name+"_depth.png")
	emit_signal("update_material", { material=mat, albedo=object_name+"_albedo.png", mr=object_name+"_mr.png", emission=object_name+"_emission.png", nm=object_name+"_nm.png", depth=object_name+"_depth.png" })

func _on_DebugSelect_item_selected(ID, t):
	var texture = [$Debug/Texture1, $Debug/Texture2][t]
	texture.visible = (ID != 0)
	texture.texture = $Painter.debug_get_texture(ID)


