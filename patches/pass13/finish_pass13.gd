extends Node

var root: Node3D

func _ready() -> void:
	for _i in range(20):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_replace_floor_language(root)
	_rebuild_ceiling_light_language(root)
	_tune_environment()
	_refine_event_hud(root)
	_add_fixture_softening()

func _replace_floor_language(node: Node) -> void:
	# Pass 12 proved the calmer palette, but its slab grid was still too visually loud.
	# Hide every previous floor overlay and replace it with one continuous manufactured surface.
	_hide_floor_nodes(node)
	var floor_mat := _material(Color(0.115,0.125,0.128),0.43,0.025)
	var joint_mat := _material(Color(0.075,0.082,0.084),0.78,0.0)
	var wear_mat := _material(Color(0.145,0.138,0.125),0.86,0.0)
	var runner_mat := _material(Color(0.055,0.063,0.066),0.94,0.0)
	_box("P13ContinuousFloor",Vector3(0,0.038,-0.15),Vector3(10.34,0.042,12.04),floor_mat)
	# Only two long expansion joints remain; they guide the eye rather than forming a checkerboard.
	_box("P13JointX",Vector3(0,0.063,-0.15),Vector3(0.016,0.010,11.72),joint_mat)
	_box("P13JointZ",Vector3(0,0.064,0.55),Vector3(10.02,0.010,0.016),joint_mat)
	# Small practical entrance runner, intentionally low contrast.
	_box("P13EntryRunner",Vector3(0,0.069,4.48),Vector3(2.35,0.016,1.22),runner_mat)
	# Irregular traffic wear, not repeated decoration.
	for mark in [Vector4(-2.8,-2.5,0.85,0.035),Vector4(2.2,-3.7,0.58,0.030),Vector4(-0.8,1.7,0.72,0.032),Vector4(2.9,2.65,0.62,0.028)]:
		_box("P13TrafficWear",Vector3(mark.x,0.071,mark.y),Vector3(mark.z,0.009,mark.w),wear_mat)

func _hide_floor_nodes(node: Node) -> void:
	if node is MeshInstance3D:
		var m := node as MeshInstance3D
		var n := String(m.name)
		if n == "FloorVisual" or n.begins_with("P4Tile") or n.begins_with("P12RetailFloor") or n.begins_with("P12FloorJoint") or n.begins_with("P12Scuff") or n.begins_with("P12EntryRunner") or n.begins_with("P12RunnerGroove"):
			m.visible = false
	for child in node.get_children():
		_hide_floor_nodes(child)

func _rebuild_ceiling_light_language(node: Node) -> void:
	# Remove the overbright line-light overlays that were reading like sci-fi strips.
	_hide_named_prefix(node,"P4CeilingGlow")
	_hide_named_prefix(node,"P4CeilingRail")
	# Cap earlier ceiling/fill lights so new panels control the room instead of stacking brightness.
	_cap_ceiling_omnis(node)
	var frame := _material(Color(0.055,0.065,0.072),0.36,0.24)
	var diffuser := _emissive(Color(1.0,0.82,0.62),0.50)
	for z in [-3.55,-0.65,2.30]:
		_box("P13LightFrame",Vector3(0,2.945,float(z)),Vector3(3.55,0.075,0.58),frame)
		_box("P13LightDiffuser",Vector3(0,2.900,float(z)),Vector3(3.20,0.022,0.40),diffuser)
		_add_omni(Vector3(0,2.63,float(z)),Color(1.0,0.83,0.66),0.24,4.4)
	# A small entrance/counter fill is enough; no giant bloom source.
	_add_omni(Vector3(2.55,2.15,1.9),Color(1.0,0.78,0.58),0.12,3.5)

func _hide_named_prefix(node: Node, prefix: String) -> void:
	if node is GeometryInstance3D and String(node.name).begins_with(prefix):
		(node as GeometryInstance3D).visible = false
	for child in node.get_children():
		_hide_named_prefix(child,prefix)

func _cap_ceiling_omnis(node: Node) -> void:
	if node is OmniLight3D:
		var light := node as OmniLight3D
		if light.position.y > 2.35 and not String(light.name).begins_with("P13"):
			light.light_energy = minf(light.light_energy,0.32)
	for child in node.get_children():
		_cap_ceiling_omnis(child)

func _tune_environment() -> void:
	var world := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		env.glow_enabled = true
		env.glow_intensity = 0.035
		env.adjustment_enabled = true
		env.adjustment_brightness = 0.91
		env.adjustment_contrast = 1.05
		env.adjustment_saturation = 0.95
		env.ambient_light_energy = 0.50

func _refine_event_hud(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if label.text.begins_with("Opening week"):
			label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			label.position = Vector2(-565,18)
			label.size = Vector2(540,40)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.add_theme_font_size_override("font_size",16)
			label.modulate = Color(1.0,0.86,0.54,0.86)
	for child in node.get_children():
		_refine_event_hud(child)

func _add_fixture_softening() -> void:
	# Curved manufactured cues break the remaining cube language without replacing working fixtures.
	var dark := _material(Color(0.045,0.055,0.062),0.33,0.48)
	var warm := _material(Color(0.42,0.18,0.07),0.40,0.16)
	var cream := _material(Color(0.72,0.70,0.65),0.52,0.02)
	var counter := _find_first(root,"CheckoutCounter") as Node3D
	if counter:
		_cylinder_local(counter,"P13CounterCornerL",Vector3(-1.05,0.98,-0.39),0.085,0.90,dark)
		_cylinder_local(counter,"P13CounterCornerR",Vector3(1.05,0.98,-0.39),0.085,0.90,dark)
		_box_local(counter,"P13CounterNose",Vector3(0,1.07,-0.49),Vector3(1.88,0.045,0.055),warm)
		_box_local(counter,"P13BagWell",Vector3(-0.78,0.94,0.18),Vector3(0.44,0.035,0.36),cream)
	var feature := _find_first(root,"FeatureStand") as Node3D
	if feature:
		for x in [-0.34,0.34]:
			_cylinder_local(feature,"P13StandPost",Vector3(x,0.72,0),0.035,0.92,dark)
		_box_local(feature,"P13StandRail",Vector3(0,0.58,-0.43),Vector3(0.72,0.035,0.04),warm)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.34
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

func _box_local(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance

func _cylinder_local(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
	return instance

func _add_omni(pos: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = "P13SoftLight"
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	root.add_child(light)

func _find_first(node: Node, target: String) -> Node:
	if String(node.name) == target:
		return node
	for child in node.get_children():
		var found := _find_first(child,target)
		if found:
			return found
	return null
