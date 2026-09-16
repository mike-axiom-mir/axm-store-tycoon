extends Node

var root: Node3D

func _ready() -> void:
	for _i in range(17):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_hide_old_floor_grid(root)
	_build_retail_floor()
	_add_floor_wear()
	_add_soft_fill_lighting()
	_repair_hud_hierarchy(root)

func _hide_old_floor_grid(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var n := String(mesh.name)
		if n == "FloorVisual" or n.begins_with("TileLineX") or n.begins_with("TileLineZ"):
			mesh.visible = false
	for child in node.get_children():
		_hide_old_floor_grid(child)

func _build_retail_floor() -> void:
	var base := _material(Color(0.185,0.195,0.198),0.54,0.015)
	var seam := _material(Color(0.145,0.152,0.154),0.72,0.0)
	var edge := _material(Color(0.075,0.085,0.090),0.78,0.16)
	var mat := _material(Color(0.085,0.095,0.098),0.91,0.0)
	# One calm continuous retail surface replaces the giant checkerboard.
	_box("P12RetailFloor",Vector3(0,-0.085,-0.15),Vector3(10.55,0.18,12.25),base)
	# Large, low-contrast slab joints: enough scale detail without taking over the frame.
	for x in [-3.60,-1.80,0.0,1.80,3.60]:
		_box("P12FloorJointX",Vector3(float(x),0.010,-0.15),Vector3(0.018,0.018,11.90),seam)
	for z in [-4.60,-2.30,0.0,2.30,4.60]:
		_box("P12FloorJointZ",Vector3(0,0.011,float(z)),Vector3(10.20,0.018,0.018),seam)
	# Dark perimeter trim helps the walls feel seated on the floor.
	_box("P12FloorEdgeL",Vector3(-5.08,0.035,-0.15),Vector3(0.08,0.07,11.95),edge)
	_box("P12FloorEdgeR",Vector3(5.08,0.035,-0.15),Vector3(0.08,0.07,11.95),edge)
	_box("P12FloorEdgeBack",Vector3(0,0.035,-6.08),Vector3(10.10,0.07,0.08),edge)
	# Anti-slip entrance runner gives the door area a practical retail cue.
	_box("P12EntryRunner",Vector3(0,0.025,4.52),Vector3(2.55,0.028,1.45),mat)
	for z in [4.05,4.38,4.71,5.04]:
		_box("P12RunnerGroove",Vector3(0,0.043,float(z)),Vector3(2.30,0.012,0.018),edge)

func _add_floor_wear() -> void:
	var scuff := _material(Color(0.115,0.122,0.124),0.82,0.0)
	var warm_scuff := _material(Color(0.20,0.17,0.13),0.86,0.0)
	var marks: Array[Vector4] = [
		Vector4(-2.5,-2.7,0.62,0.055),Vector4(1.4,-3.6,0.48,0.045),Vector4(3.2,-1.2,0.72,0.05),
		Vector4(-1.1,1.4,0.58,0.045),Vector4(2.1,2.9,0.50,0.04),Vector4(-3.1,3.2,0.64,0.05)
	]
	for i in range(marks.size()):
		var m := marks[i]
		_box("P12Scuff",Vector3(m.x,0.031,m.y),Vector3(m.z,0.012,m.w),warm_scuff if i % 3 == 0 else scuff)

func _add_soft_fill_lighting() -> void:
	_add_omni("P12EntryFill",Vector3(0.2,2.05,4.25),Color(1.0,0.78,0.56),0.19,4.7)
	_add_omni("P12CounterFill",Vector3(2.65,1.95,1.65),Color(1.0,0.84,0.66),0.15,4.1)
	_add_omni("P12WindowFill",Vector3(3.95,1.85,-0.30),Color(0.58,0.72,0.90),0.12,4.4)

func _repair_hud_hierarchy(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if label.text.contains("BACK ROOM"):
			label.add_theme_font_size_override("font_size",14)
			label.size = Vector2(252,78)
			label.position = Vector2(9,7)
			var panel := label.get_parent() as PanelContainer
			if panel:
				panel.visible = true
				panel.position = Vector2(-286,18)
				panel.size = Vector2(268,94)
				panel.add_theme_stylebox_override("panel",_hud_style(Color(0.028,0.034,0.034,0.74),Color(0.58,0.24,0.10,0.62)))
		elif absf(label.size.x - 720.0) < 8.0 and absf(label.size.y - 60.0) < 8.0:
			# Center toast remains readable but stops competing with the scene.
			label.add_theme_font_size_override("font_size",16)
			label.modulate = Color(1.0,0.94,0.77,0.83)
	for child in node.get_children():
		_repair_hud_hierarchy(child)

func _hud_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style

func _add_omni(node_name: String, pos: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	root.add_child(light)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _box(node_name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	root.add_child(instance)
	return instance
