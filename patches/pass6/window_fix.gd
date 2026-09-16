extends Node

var root: Node3D

func _ready() -> void:
	# Run after the existing visual passes so this layer restores openings last.
	for _i in range(5):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_restore_storefront_glass()
	_restore_side_windows()
	_tone_exterior()
	_add_outside_depth()

func _restore_storefront_glass() -> void:
	var glass := _glass_material(Color(0.42,0.66,0.80,0.09),0.035)
	for target in ["GlassL","GlassR","DoorGlass","Glass"]:
		var mesh := _find_first(root,target) as MeshInstance3D
		if mesh:
			mesh.material_override = glass
			mesh.visible = true

func _restore_side_windows() -> void:
	# Hide side-wall/cladding geometry by shape/position instead of generated node names.
	# This preserves collision bodies while removing only the broad visual skin.
	_hide_side_cladding_geometry(root)

	var glass := _glass_material(Color(0.30,0.56,0.76,0.075),0.045)
	var frame := StandardMaterial3D.new()
	frame.albedo_color = Color(0.028,0.038,0.050)
	frame.roughness = 0.28
	frame.metallic = 0.74
	var sill := StandardMaterial3D.new()
	sill.albedo_color = Color(0.07,0.10,0.11)
	sill.roughness = 0.62
	sill.metallic = 0.10

	for side in [-1,1]:
		var x: float = float(side) * 5.03
		_box("WindowKick",Vector3(x,0.35,-0.35),Vector3(0.10,0.70,10.7),sill)
		_box("WindowHeader",Vector3(x,2.67,-0.35),Vector3(0.10,0.24,10.7),frame)
		for i in range(6):
			var z: float = -4.35 + float(i) * 1.62
			_box("SideGlass",Vector3(x,1.53,z),Vector3(0.035,1.78,1.45),glass)
			var frame_z: float = z + 0.77
			_box("SideFrame",Vector3(x - float(side) * 0.012,1.53,frame_z),Vector3(0.075,1.92,0.055),frame)

func _hide_side_cladding_geometry(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var box := instance.mesh as BoxMesh
		if box:
			var p: Vector3 = instance.position
			var s: Vector3 = box.size
			var at_side: bool = absf(p.x) >= 4.95 and absf(p.x) <= 5.35
			var full_wall: bool = s.y >= 2.8 and s.z >= 10.0
			var p6_panel: bool = s.x <= 0.15 and s.y >= 1.8 and s.z >= 1.20 and s.z <= 1.60 and p.y >= 1.20 and p.y <= 1.55
			if at_side and (full_wall or p6_panel):
				instance.visible = false
	for child in node.get_children():
		_hide_side_cladding_geometry(child)

func _tone_exterior() -> void:
	var world := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		env.background_color = Color(0.18,0.36,0.60)
		env.ambient_light_color = Color(0.60,0.69,0.78)
		env.ambient_light_energy = 0.52
		env.adjustment_enabled = true
		env.adjustment_brightness = 0.89
		env.adjustment_contrast = 1.07
		env.adjustment_saturation = 1.03
	var sun := root.get_node_or_null("ExteriorSoftLight") as DirectionalLight3D
	if sun:
		sun.light_energy = 0.44
		sun.light_color = Color(0.73,0.83,0.96)

func _add_outside_depth() -> void:
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.09,0.20,0.11)
	grass.roughness = 0.96
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.29,0.31,0.33)
	concrete.roughness = 0.90
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.045,0.06,0.08)
	dark.roughness = 0.75
	# Give the side windows actual world depth instead of empty sky.
	_box("OutsideGroundL",Vector3(-7.3,-0.13,-0.5),Vector3(4.2,0.18,13.0),grass)
	_box("OutsideGroundR",Vector3(7.3,-0.13,-0.5),Vector3(4.2,0.18,13.0),grass)
	_box("FarRoadEdge",Vector3(0,0.12,13.0),Vector3(16.0,0.22,0.22),concrete)
	for x in [-6.0,-2.7,5.6]:
		_box("RoadsideSilhouette",Vector3(x,0.85,15.5),Vector3(1.6,1.7,0.7),dark)

func _glass_material(color: Color, roughness: float) -> StandardMaterial3D:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = color
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = roughness
	glass.metallic = 0.05
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.emission_enabled = true
	glass.emission = Color(0.025,0.05,0.07)
	glass.emission_energy_multiplier = 0.06
	return glass

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

func _find_first(node: Node, target: String) -> Node:
	if String(node.name) == target:
		return node
	for child in node.get_children():
		var found: Node = _find_first(child,target)
		if found:
			return found
	return null
