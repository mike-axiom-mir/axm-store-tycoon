extends Node

var root: Node3D

func _ready() -> void:
	for _i in range(11):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_tune_window_transparency(root)
	_hide_stray_upgrade_label(root)
	_build_readable_service_facade()
	_add_service_lighting()

func _tune_window_transparency(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var n := String(mesh.name)
		if n.begins_with("SideGlassBay"):
			var mat := mesh.material_override as ShaderMaterial
			if mat:
				mat.set_shader_parameter("base_alpha",0.095)
				mat.set_shader_parameter("fresnel_alpha",0.24)
	for child in node.get_children():
		_tune_window_transparency(child)

func _hide_stray_upgrade_label(node: Node) -> void:
	if node is Label3D:
		var label := node as Label3D
		if String(label.text).to_upper().contains("UPGRADE"):
			label.visible = false
	for child in node.get_children():
		_hide_stray_upgrade_label(child)

func _build_readable_service_facade() -> void:
	var wall := _plain(Color(0.54,0.50,0.42),0.74,0.01)
	var door := _plain(Color(0.58,0.60,0.58),0.62,0.05)
	var frame := _plain(Color(0.055,0.062,0.070),0.40,0.52)
	var red := _plain(Color(0.46,0.055,0.035),0.42,0.08)
	var orange := _emissive(Color(0.95,0.30,0.08),1.75)
	var warm := _emissive(Color(1.0,0.74,0.40),1.50)
	var van_panel := _plain(Color(0.68,0.64,0.54),0.54,0.04)

	# West-facing facade directly behind the store's right-side windows.
	_box("P9GarageFacade",Vector3(6.73,1.68,1.95),Vector3(0.10,3.10,6.35),wall)
	for z in [0.42,3.48]:
		_box("P9ServiceDoor",Vector3(6.66,1.47,float(z)),Vector3(0.055,2.20,2.25),door)
		for y in [0.68,1.08,1.48,1.88]:
			_box("P9DoorSeam",Vector3(6.625,float(y),float(z)),Vector3(0.025,0.035,2.10),frame)
		_box("P9DoorLamp",Vector3(6.60,2.56,float(z)),Vector3(0.025,0.16,1.25),warm)
	_box("P9GarageHeader",Vector3(6.64,3.06,1.95),Vector3(0.055,0.48,2.85),orange)
	_box("P9GarageKick",Vector3(6.61,0.29,1.95),Vector3(0.035,0.18,6.05),frame)
	_box("P9GarageBand",Vector3(6.60,0.82,1.95),Vector3(0.035,0.12,5.80),red)
	_label("SERVICE GARAGE",Vector3(6.575,3.08,1.95),Vector3(0,-90,0),31,Color(1.0,0.90,0.72))

	# Bright visible side of the existing parked van.
	_box("P9VanSidePanel",Vector3(5.53,0.82,2.55),Vector3(0.035,0.86,2.05),van_panel)
	_box("P9VanStripe",Vector3(5.50,0.73,2.55),Vector3(0.025,0.12,1.85),red)
	_box("P9VanWindow",Vector3(5.49,1.27,2.88),Vector3(0.020,0.38,0.78),_plain(Color(0.075,0.12,0.15),0.20,0.02))

func _add_service_lighting() -> void:
	for z in [0.42,3.48]:
		var light := OmniLight3D.new()
		light.name = "P9GarageBayLight"
		light.position = Vector3(6.15,2.40,float(z))
		light.omni_range = 4.0
		light.light_color = Color(1.0,0.73,0.43)
		light.light_energy = 0.32
		light.shadow_enabled = false
		root.add_child(light)

func _plain(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.20
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
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

func _label(text: String, pos: Vector3, rot: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.modulate = color
	label.outline_size = 6
	label.position = pos
	label.rotation_degrees = rot
	root.add_child(label)
