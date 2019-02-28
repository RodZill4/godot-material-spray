tool
extends VBoxContainer

const MODE_FREE         = 0
const MODE_LINE         = 1
const MODE_LINE_STRIP   = 2
const MODE_COLOR_PICKER = 3
const MODE_COUNT        = 4

var current_tool = MODE_FREE

var previous_position = null
var painting = false
var next_paint_to = null

var key_rotate = Vector2(0.0, 0.0)

var object_name = null

onready var main_view = $View/MainView
onready var camera = $View/MainView/CameraStand/Camera
onready var camera_stand = $View/MainView/CameraStand
onready var painted_mesh = $View/MainView/PaintedMesh
onready var painter = $View/Painter
onready var tools = $View/Tools
onready var layers = $View/Layers
onready var brush = $View/Brush

signal update_material

const MENU = [
	{ menu="File", command="load_project", shortcut="Control+O", description="Load project" },
	{ menu="File", command="save_project", shortcut="Control+S", description="Save project" },
	{ menu="File", command="save_project_as", shortcut="Control+Shift+S", description="Save project as..." },
	{ menu="File" },
	{ menu="File", command="export_material", shortcut="Control+E", description="Export textures" },
]

func _ready():
	# Assign all textures to painted mesh
	painted_mesh.set_surface_material(0, SpatialMaterial.new())
	# Updated Texture2View wrt current camera position
	update_view()
	# Set size of painted textures
	set_texture_size(2048)
	# Disable physics process so we avoid useless updates of tex2view textures
	set_physics_process(false)
	set_current_tool(MODE_FREE)
	for m in $Menu.get_children():
		var menu = m.get_popup()
		create_menu(menu, m.name)
		m.connect("about_to_show", self, "on_menu_about_to_show", [ m.name, menu ])

func create_menu(menu, menu_name):
	menu.clear()
	menu.connect("id_pressed", self, "on_menu_item")
	for i in MENU.size():
		if MENU[i].has("standalone_only") and MENU[i].standalone_only and Engine.editor_hint:
			continue
		if MENU[i].menu != menu_name:
			continue
		if MENU[i].has("submenu"):
			var submenu = PopupMenu.new()
			var submenu_function = "create_menu_"+MENU[i].submenu
			if has_method(submenu_function):
				call(submenu_function, submenu)
			else:
				create_menu(submenu, MENU[i].submenu)
			menu.add_child(submenu)
			menu.add_submenu_item(MENU[i].description, submenu.get_name())
		elif MENU[i].has("description"):
			var shortcut = 0
			if MENU[i].has("shortcut"):
				for s in MENU[i].shortcut.split("+"):
					if s == "Alt":
						shortcut |= KEY_MASK_ALT
					elif s == "Control":
						shortcut |= KEY_MASK_CTRL
					elif s == "Shift":
						shortcut |= KEY_MASK_SHIFT
					else:
						shortcut |= OS.find_scancode_from_string(s)
			menu.add_item(MENU[i].description, i, shortcut)
		else:
			menu.add_separator()
	return menu

func on_menu_about_to_show(name, menu):
	for i in MENU.size():
		if MENU[i].menu != name:
			continue
		if MENU[i].has("submenu"):
			pass
		elif MENU[i].has("command"):
			var command_name = MENU[i].command+"_is_disabled"
			if has_method(command_name):
				var is_disabled = call(command_name)
				menu.set_item_disabled(menu.get_item_index(i), is_disabled)

func on_menu_item(id):
	if MENU[id].has("command"):
		var command = MENU[id].command
		if has_method(command):
			call(command)

func set_object(o):
	object_name = o.name
	var mat = o.get_surface_material(0)
	if mat == null:
		mat = o.mesh.surface_get_material(0)
	if mat == null:
		mat = SpatialMaterial.new()
	var new_mat = SpatialMaterial.new()
	new_mat.albedo_texture = layers.get_albedo_texture()
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
	painted_mesh.mesh = o.mesh
	painted_mesh.set_surface_material(0, new_mat)
	painter.set_mesh(o.mesh)
	update_view()
	painter.init_textures(mat)

func set_texture_size(s):
	layers.set_texture_size(s)
	painter.set_texture_size(s)

func set_current_tool(m):
	current_tool = m
	for i in range(MODE_COUNT):
		tools.get_child(i).pressed = (i == m)

func _physics_process(delta):
	camera_stand.rotate(camera.global_transform.basis.x.normalized(), -key_rotate.y*delta)
	camera_stand.rotate(Vector3(0, 1, 0), -key_rotate.x*delta)
	update_view()

func _input(ev : InputEvent):
	if ev is InputEventKey:
		if ev.scancode == KEY_CONTROL:
			brush.show_pattern(ev.pressed)
			accept_event()
		elif ev.scancode == KEY_LEFT or ev.scancode == KEY_RIGHT or ev.scancode == KEY_UP or ev.scancode == KEY_DOWN:
			var new_key_rotate = Vector2(0.0, 0.0)
			if Input.is_key_pressed(KEY_UP):
				key_rotate.y -= 1.0
			if Input.is_key_pressed(KEY_DOWN):
				key_rotate.y += 1.0
			if Input.is_key_pressed(KEY_LEFT):
				key_rotate.x -= 1.0
			if Input.is_key_pressed(KEY_RIGHT):
				key_rotate.x += 1.0
			if new_key_rotate != key_rotate:
				key_rotate = new_key_rotate
				set_physics_process(key_rotate != Vector2(0.0, 0.0))
				accept_event()
	elif ev is InputEventMouseButton:
		var zoom = 0.0
		if ev.button_index == BUTTON_WHEEL_UP:
			zoom -= 1.0
		elif ev.button_index == BUTTON_WHEEL_DOWN:
			zoom += 1.0
		if zoom != 0.0:
			camera.translate(Vector3(0.0, 0.0, zoom*(1.0 if ev.shift else 0.1)))
			update_view()
			accept_event()

func _on_MaterialSpray_gui_input(ev : InputEvent):
	if ev is InputEventMouseMotion:
		if current_tool == MODE_COLOR_PICKER:
			brush.show_brush(null, null)
		else:
			brush.show_brush(ev.position, previous_position)
		if ev.button_mask & BUTTON_MASK_RIGHT != 0:
			if ev.shift:
				camera_stand.translate(-0.2*ev.relative.x*camera.transform.basis.x)
				camera_stand.translate(0.2*ev.relative.y*camera.transform.basis.y)
			else:
				camera_stand.rotate(camera.global_transform.basis.x.normalized(), -0.01*ev.relative.y)
				camera_stand.rotate(Vector3(0, 1, 0), -0.01*ev.relative.x)
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
				elif current_tool == MODE_COLOR_PICKER:
					painter.pick_color(pos)
				elif current_tool != MODE_LINE_STRIP:
					paint(pos)
					previous_position = null
		if !ev.pressed and ev.button_index == BUTTON_RIGHT:
			update_view()

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
	painter.paint(position, prev_position)
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
	var mesh_instance = painted_mesh
	var mesh_aabb = mesh_instance.get_aabb()
	var mesh_center = mesh_aabb.position+0.5*mesh_aabb.size
	var mesh_size = 0.5*mesh_aabb.size.length()
	var cam_to_center = (camera.global_transform.origin-mesh_center).length()
	camera.near = max(0.2, 0.5*(cam_to_center-mesh_size))
	camera.far = 2.0*(cam_to_center+mesh_size)
	var transform = camera.global_transform.affine_inverse()*painted_mesh.global_transform
	if painter != null:
		painter.update_view(camera, transform, main_view.size)

func _on_resized():
	update_view()

func dump_texture(texture, filename):
	var image = texture.get_data()
	image.save_png(filename)

func show_file_dialog(mode, filter, callback):
	var dialog = FileDialog.new()
	add_child(dialog)
	dialog.rect_min_size = Vector2(500, 500)
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = mode
	dialog.add_filter(filter)
	dialog.connect("file_selected", self, callback)
	dialog.popup_centered()

func load_project():
	show_file_dialog(FileDialog.MODE_OPEN_FILE, "*.masp;Material Spray project", "do_load_project")

func do_load_project(file_name):
	layers.load(file_name)

func save_project():
	show_file_dialog(FileDialog.MODE_SAVE_FILE, "*.masp;Material Spray project", "do_save_project")

func do_save_project(file_name):
	layers.save(file_name)

func export_material():
	show_file_dialog(FileDialog.MODE_SAVE_FILE, "*.tres;Spatial material", "do_export_material")

func do_export_material(file_name):
	var prefix = file_name.replace(".tres", "")
	var mat = painted_mesh.get_surface_material(0).duplicate()
	dump_texture(layers.get_albedo_texture(), prefix+"_albedo.png")
	dump_texture(painter.get_mr_texture(), prefix+"_mr.png")
	dump_texture(painter.get_emission_texture(), prefix+"_emission.png")
	dump_texture(painter.get_normal_map(), prefix+"_nm.png")
	dump_texture(painter.get_depth_texture(), prefix+"_depth.png")
	emit_signal("update_material", { material=mat, material_file=file_name, albedo=prefix+"_albedo.png", mr=prefix+"_mr.png", emission=prefix+"_emission.png", nm=prefix+"_nm.png", depth=prefix+"_depth.png" })

func _on_DebugSelect_item_selected(ID, t):
	var texture = [$View/Debug/Texture1, $View/Debug/Texture2][t]
	texture.visible = (ID != 0)
	texture.texture = painter.debug_get_texture(ID)
