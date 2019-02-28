tool
extends Control

export(NodePath) var painter = null

onready var tree = $VBoxContainer/Tree
onready var albedo = $Albedo
onready var painter_node = get_node(painter) if painter != null else null

func _ready():
	tree.create_layer()

func set_texture_size(s : float):
	albedo.size = Vector2(s, s)

func get_albedo_texture():
	return albedo.get_texture()

func get_mr_texture():
	return painter_node.get_mr_texture()

func get_emission_texture():
	return painter_node.get_emission_texture()

func get_normal_map():
	return painter_node.get_normal_map()
	
func get_depth_texture():
	return painter_node.get_depth_texture()

func _on_Add_pressed():
	tree.create_layer()

func _on_Update_pressed():
	pass

func _on_Tree_selection_changed(old_selected : TreeItem, new_selected : TreeItem):
	if painter_node == null:
		painter_node = get_node(painter)
	if old_selected != null:
		var old_texture : Texture = old_selected.get_meta("albedo")
		var new_texture = ImageTexture.new()
		if old_texture != null:
			new_texture.create_from_image(old_texture.get_data())
		old_selected.set_meta("albedo", new_texture)
	if new_selected != null:
		if new_selected.has_meta("albedo"):
			painter_node.init_albedo_texture(Color(1.0, 1.0, 1.0, 1.0), new_selected.get_meta("albedo"))
		else:
			painter_node.init_albedo_texture()
		new_selected.set_meta("albedo", painter_node.get_albedo_texture())

func _on_Tree_layers_changed(layers : Array):
	while albedo.get_child_count() > 0:
		albedo.remove_child(albedo.get_child(0))
	for l in layers:
		var texture_rect : TextureRect = TextureRect.new()
		texture_rect.texture = l.get_meta("albedo")
		texture_rect.rect_size = albedo.size
		albedo.add_child(texture_rect)

func load(file_name):
	var dir_name = file_name.left(file_name.rfind("."))
	var file : File = File.new()
	if file.open(file_name, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		tree.load_layers(data, dir_name)
		file.close()

func save(file_name):
	var dir_name = file_name.left(file_name.rfind("."))
	var dir = Directory.new()
	dir.make_dir(dir_name)
	var data = {}
	tree.save_layers(data, tree.get_root(), 0, dir_name)
	var file = File.new()
	if file.open(file_name, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()