tool
extends WindowDialog

func _ready():
	pass

func set_project_path(p):
	window_title = "Material Spray - "+p

func set_object(o):
	$PaintTool.set_object(o)
