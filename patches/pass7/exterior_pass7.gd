extends Node

var root: Node3D

func _ready() -> void:
	for _i in range(7):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_reframe_camera()
	_build_side_garage()
	_build_forecourt_cluster()
	_build_visible_depth_props()

func _reframe_camera() -> void:
	var player := root.get_node_or_null("Player") as CharacterBody3D
	if player:
		player.position = Vector3(3.35,0,-4.45)
		player.rotation_degrees = Vector3(0,156,0)
		var camera := player.get_node_or_null("Camera3D") as Camera3D
		if camera:
			camera.fov = 78.0

func _build_side_garage() -> void:
	var wall := _plain(Color(0.17,0.19,0.20),0.82,0.02)
	var wall_light := _plain(Color(0.34,0.33,0.29),0.78,0.01)
	var frame := _plain(Color(0.045,0.052,0.060),0.38,0.58)
	var door := _plain(Color(0.44,0.46,0.45),0.64,0.05)
	var rubber := _plain(Color(0.018,0.020,0.023),0.96,0.0)
	var van_body := _plain(Color(0.44,0.42,0.36),0.56,0.05)
	var glass := _glass_material(Color(0.055,0.09,0.12,1.0),0.26,0.24)
	var orange := _emissive(Color(0.92,0.28,0.07),1.45)
	var warm := _emissive(Color(1.0,0.70,0.34),1.6)

	# The west facade sits directly outside the store's right windows.
	var garage := Node3D.new()
	garage.name = "P7NeighborGarage"
	garage.position = Vector3(8.35,0,1.95)
	root.add_child(garage)
	_box_local(garage,"GarageBody",Vector3(0,1.65,0),Vector3(3.1,3.3,7.2),wall)
	_box_local(garage,"GarageRoof",Vector3(0,3.39,0),Vector3(3.4,0.20,7.5),frame)
	_box_local(garage,"GarageFrontBand",Vector3(-1.58,2.92,0.55),Vector3(0.08,0.36,5.8),wall_light)
	# Two sectional doors facing the store.
	for z in [-1.55,1.55]:
		_box_local(garage,"ServiceDoor",Vector3(-1.61,1.42,float(z)),Vector3(0.07,2.25,2.35),door)
		for y in [0.62,1.08,1.54,2.00]:
			_box_local(garage,"DoorSeam",Vector3(-1.66,float(y),float(z)),Vector3(0.025,0.035,2.22),frame)
		_box_local(garage,"DoorTopLight",Vector3(-1.68,2.52,float(z)),Vector3(0.025,0.16,1.50),warm)
	# Vertical corner frame and bright garage sign.
	_box_local(garage,"GarageCorner",Vector3(-1.69,1.72,-3.23),Vector3(0.10,3.25,0.10),frame)
	_box_local(garage,"GarageCorner",Vector3(-1.69,1.72,3.23),Vector3(0.10,3.25,0.10),frame)
	_box_local(garage,"GarageSign",Vector3(-1.70,3.02,0),Vector3(0.055,0.42,2.20),orange)
	_label("SERVICE  •  TYRES  •  REPAIR",Vector3(6.62,3.04,1.95),Vector3(0,-90,0),26,Color(1.0,0.82,0.62))

	# A van immediately outside the middle/right windows gives scale and believable obstruction.
	var van := Node3D.new()
	van.name = "P7ParkedVan"
	van.position = Vector3(6.20,0,2.55)
	van.rotation.y = 0.10
	root.add_child(van)
	_box_local(van,"VanBody",Vector3(0,0.67,0),Vector3(1.30,1.20,2.65),van_body)
	_box_local(van,"VanRoof",Vector3(0,1.37,-0.18),Vector3(1.24,0.24,2.05),van_body)
	_box_local(van,"VanWindshield",Vector3(0,1.15,1.17),Vector3(1.04,0.48,0.035),glass)
	_box_local(van,"VanRearGlass",Vector3(0,1.08,-1.34),Vector3(0.96,0.38,0.035),glass)
	_box_local(van,"VanStripe",Vector3(-0.67,0.76,0),Vector3(0.035,0.14,2.20),orange)
	for x in [-0.69,0.69]:
		for z in [-0.88,0.88]:
			_box_local(van,"VanWheel",Vector3(float(x),0.30,float(z)),Vector3(0.18,0.52,0.52),rubber)

	# Dumpster + safety bollards stop the side lot feeling empty.
	_box("P7Dumpster",Vector3(6.55,0.55,-1.45),Vector3(1.25,1.10,0.95),_plain(Color(0.10,0.24,0.18),0.82,0.02))
	_box("P7DumpsterLid",Vector3(6.55,1.14,-1.45),Vector3(1.32,0.10,1.02),frame)
	for z in [-0.55,0.55]:
		_box("P7Bollard",Vector3(5.78,0.48,float(z)+1.0),Vector3(0.14,0.96,0.14),_plain(Color(0.82,0.43,0.06),0.58,0.02))

func _build_forecourt_cluster() -> void:
	var body := _plain(Color(0.78,0.76,0.68),0.55,0.03)
	var red := _plain(Color(0.47,0.055,0.035),0.44,0.08)
	var dark := _plain(Color(0.035,0.045,0.055),0.42,0.55)
	var rubber := _plain(Color(0.018,0.020,0.023),0.96,0.0)
	var glass := _glass_material(Color(0.05,0.08,0.11,1.0),0.25,0.22)
	var cyan := _emissive(Color(0.10,0.72,0.84),1.25)
	var warm := _emissive(Color(1.0,0.68,0.30),1.55)

	# A second pump sits left-of-centre so it is visible through the door/front panes.
	var pump := Node3D.new()
	pump.name = "P7FrontPump"
	pump.position = Vector3(-1.65,0,7.15)
	root.add_child(pump)
	_box_local(pump,"PumpBase",Vector3(0,0.10,0),Vector3(0.95,0.20,0.88),rubber)
	_box_local(pump,"PumpBody",Vector3(0,1.00,0),Vector3(0.72,1.75,0.62),body)
	_box_local(pump,"PumpBand",Vector3(0,1.10,-0.33),Vector3(0.66,0.16,0.035),red)
	_box_local(pump,"PumpFace",Vector3(0,1.38,-0.33),Vector3(0.42,0.38,0.035),cyan)
	_box_local(pump,"PumpTop",Vector3(0,1.94,0),Vector3(0.90,0.18,0.78),dark)
	_box_local(pump,"PumpLamp",Vector3(0,2.06,-0.05),Vector3(0.48,0.07,0.26),warm)

	# Forecourt car is deliberately low and offset, not blocking the entrance.
	var car := Node3D.new()
	car.name = "P7ForecourtCar"
	car.position = Vector3(-3.55,0,8.10)
	car.rotation.y = -0.16
	root.add_child(car)
	_box_local(car,"CarBody",Vector3(0,0.40,0),Vector3(2.55,0.52,1.24),red)
	_box_local(car,"CarCabin",Vector3(-0.15,0.78,0),Vector3(1.35,0.50,1.08),red)
	_box_local(car,"FrontGlass",Vector3(0.48,0.83,0),Vector3(0.035,0.38,0.96),glass)
	for x in [-0.82,0.82]:
		for z in [-0.63,0.63]:
			_box_local(car,"CarWheel",Vector3(float(x),0.23,float(z)),Vector3(0.44,0.44,0.16),rubber)

	# Lower price/brand pylon that is readable through the front panes.
	_box("P7PylonPost",Vector3(4.75,1.15,7.05),Vector3(0.14,2.30,0.14),dark)
	_box("P7PylonFace",Vector3(4.75,2.12,7.05),Vector3(1.15,0.72,0.16),red)
	_box("P7PylonGlow",Vector3(4.75,2.12,6.95),Vector3(0.82,0.12,0.025),warm)

func _build_visible_depth_props() -> void:
	var dark := _plain(Color(0.045,0.055,0.065),0.82,0.02)
	var fence := _plain(Color(0.18,0.19,0.18),0.84,0.08)
	var leaf := _plain(Color(0.055,0.17,0.075),0.94,0.0)
	var trunk := _plain(Color(0.15,0.085,0.045),0.92,0.0)
	# Fence and trees directly behind the garage create layers through the side windows.
	for z in [-4.2,-2.8,-1.4,0.0,1.4,2.8,4.2]:
		_box("P7FencePost",Vector3(10.25,0.75,float(z)),Vector3(0.10,1.50,0.10),fence)
	_box("P7FenceRail",Vector3(10.25,0.55,0),Vector3(0.08,0.08,9.4),fence)
	_box("P7FenceRail",Vector3(10.25,1.05,0),Vector3(0.08,0.08,9.4),fence)
	for z in [-3.5,4.6]:
		_box("P7TreeTrunk",Vector3(11.2,1.0,float(z)),Vector3(0.34,2.0,0.34),trunk)
		_box("P7TreeCrown",Vector3(11.2,2.6,float(z)),Vector3(1.65,1.65,1.65),leaf)
		_box("P7TreeCrown",Vector3(10.75,3.15,float(z)+0.25),Vector3(1.25,1.20,1.25),leaf)
	# Tall dark forms beyond the forecourt make the front horizon less empty.
	_box("P7DistantBlock",Vector3(-8.6,2.0,18.6),Vector3(4.5,4.0,3.0),dark)
	_box("P7DistantBlock",Vector3(8.9,2.6,19.4),Vector3(5.0,5.2,3.6),dark)

func _plain(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.22
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _glass_material(tint: Color, base_alpha: float, fresnel_alpha: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;
uniform vec4 tint_color : source_color = vec4(0.08,0.12,0.16,1.0);
uniform float base_alpha = 0.24;
uniform float fresnel_alpha = 0.22;
void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)),0.0,1.0);
	float fresnel = pow(1.0-facing,5.0);
	ALBEDO = mix(tint_color.rgb,vec3(0.34,0.40,0.46),fresnel*0.18);
	ROUGHNESS = 0.12 + fresnel*0.12;
	SPECULAR = 0.60;
	ALPHA = clamp(base_alpha + fresnel*fresnel_alpha,0.0,0.68);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint_color",tint)
	material.set_shader_parameter("base_alpha",base_alpha)
	material.set_shader_parameter("fresnel_alpha",fresnel_alpha)
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

func _label(text: String, pos: Vector3, rot: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.modulate = color
	label.outline_size = 5
	label.position = pos
	label.rotation_degrees = rot
	root.add_child(label)
