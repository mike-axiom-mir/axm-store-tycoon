extends Node

const TILE_COUNT: float = 3.0
const TILE_DARK_FRAME: int = 0
const TILE_AGED_IVORY: int = 1

var root: Node3D
var atlas_base: Texture2D
var atlas_normal: Texture2D
var atlas_rough: Texture2D
var atlas_metal: Texture2D

func _ready() -> void:
	# Run after the other visual passes and rebuild the openings/world last.
	for _i in range(5):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_load_native_atlas()
	_restore_storefront_glass()
	_rebuild_side_wall_bays()
	_tone_exterior()
	_add_outside_depth()

func _load_native_atlas() -> void:
	atlas_base = load("res://assets/pass6/material-atlas_basecolor.png") as Texture2D
	atlas_normal = load("res://assets/pass6/material-atlas_normal.png") as Texture2D
	atlas_rough = load("res://assets/pass6/material-atlas_roughness.png") as Texture2D
	atlas_metal = load("res://assets/pass6/material-atlas_metallic.png") as Texture2D

func _restore_storefront_glass() -> void:
	var glass: ShaderMaterial = _glass_material(Color(0.15,0.23,0.29,1.0),0.14,0.28)
	for target in ["GlassL","GlassR","DoorGlass","Glass"]:
		var mesh := _find_first(root,target) as MeshInstance3D
		if mesh:
			mesh.material_override = glass
			mesh.visible = true

	# Add depth to the broad front panes so they read as framed glazing, not blue cards.
	var frame: StandardMaterial3D = _native_material(TILE_DARK_FRAME,Color(0.34,0.38,0.43),0.62)
	for x in [-4.70,-3.15,-1.18,1.18,3.15,4.70]:
		_box("FrontMullion",Vector3(float(x),1.60,5.82),Vector3(0.075,2.10,0.10),frame)
	_box("FrontSill",Vector3(0,0.91,5.82),Vector3(9.35,0.09,0.12),frame)

func _rebuild_side_wall_bays() -> void:
	# Remove the previous giant wall/skin meshes. Collision bodies remain untouched.
	_hide_side_cladding_geometry(root)

	var wall: StandardMaterial3D = _native_material(TILE_AGED_IVORY,Color(0.77,0.73,0.65),0.54)
	var frame: StandardMaterial3D = _native_material(TILE_DARK_FRAME,Color(0.29,0.33,0.38),0.70)
	var glass: ShaderMaterial = _glass_material(Color(0.12,0.19,0.24,1.0),0.16,0.34)
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(0.34,0.075,0.045)
	accent.roughness = 0.48
	accent.metallic = 0.08

	# A convenience store should have windows, not aquarium walls: solid rear service wall,
	# three inset bays toward the front, proper lower wall, head, reveals, mullions and sills.
	var bay_centers: Array[float] = [-0.05,1.88,3.81]
	for side in [-1,1]:
		var sidef: float = float(side)
		var x_wall: float = sidef * 5.03
		var x_glass: float = sidef * 4.985
		_box("SideLowerWall",Vector3(x_wall,0.52,-0.18),Vector3(0.14,1.04,10.70),wall)
		_box("SideUpperWall",Vector3(x_wall,2.60,-0.18),Vector3(0.14,0.64,10.70),wall)
		_box("SideRearWall",Vector3(x_wall,1.64,-3.25),Vector3(0.14,1.58,4.35),wall)
		_box("SideFrontPier",Vector3(x_wall,1.64,5.22),Vector3(0.14,1.58,0.92),wall)

		for z in bay_centers:
			_box("SideGlassBay",Vector3(x_glass,1.65,z),Vector3(0.028,1.25,1.52),glass)
			_box("SideWindowSill",Vector3(x_wall - sidef * 0.035,1.015,z),Vector3(0.18,0.085,1.68),frame)
			_box("SideWindowHead",Vector3(x_wall - sidef * 0.035,2.285,z),Vector3(0.18,0.085,1.68),frame)
			_box("SideWindowJambA",Vector3(x_wall - sidef * 0.035,1.65,z - 0.80),Vector3(0.18,1.34,0.085),frame)
			_box("SideWindowJambB",Vector3(x_wall - sidef * 0.035,1.65,z + 0.80),Vector3(0.18,1.34,0.085),frame)

		_box("SideAccentBand",Vector3(x_wall - sidef * 0.078,0.94,2.00),Vector3(0.035,0.10,6.60),accent)

func _hide_side_cladding_geometry(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var box := instance.mesh as BoxMesh
		if box:
			var p: Vector3 = instance.position
			var s: Vector3 = box.size
			var at_side: bool = absf(p.x) >= 4.92 and absf(p.x) <= 5.36
			var full_wall: bool = s.y >= 2.75 and s.z >= 9.5
			var old_panel: bool = s.x <= 0.18 and s.y >= 1.70 and s.z >= 1.15 and s.z <= 1.70 and p.y >= 1.15 and p.y <= 1.60
			var old_window_piece: bool = String(instance.name).begins_with("SideGlass") or String(instance.name).begins_with("SideFrame") or String(instance.name).begins_with("WindowKick") or String(instance.name).begins_with("WindowHeader")
			if at_side and (full_wall or old_panel or old_window_piece):
				instance.visible = false
	for child in node.get_children():
		_hide_side_cladding_geometry(child)

func _tone_exterior() -> void:
	var world := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		var env := world.environment
		env.background_color = Color(0.12,0.24,0.38)
		env.ambient_light_color = Color(0.54,0.62,0.70)
		env.ambient_light_energy = 0.48
		env.adjustment_enabled = true
		env.adjustment_brightness = 0.88
		env.adjustment_contrast = 1.08
		env.adjustment_saturation = 0.94
	var sun := root.get_node_or_null("ExteriorSoftLight") as DirectionalLight3D
	if sun:
		sun.light_energy = 0.46
		sun.light_color = Color(0.78,0.85,0.95)

func _add_outside_depth() -> void:
	# Pass 7 roadside world: foreground forecourt, readable road, midground props,
	# then distant buildings/trees so the glazing has believable parallax and scale.
	var grass := _plain(Color(0.055,0.13,0.065),0.98,0.0)
	var concrete := _plain(Color(0.29,0.30,0.31),0.88,0.0)
	var concrete_light := _plain(Color(0.42,0.43,0.42),0.86,0.0)
	var asphalt := _plain(Color(0.032,0.038,0.046),0.96,0.0)
	var line_white := _plain(Color(0.72,0.71,0.64),0.68,0.0)
	var line_yellow := _plain(Color(0.78,0.54,0.14),0.62,0.0)
	var dark_metal := _plain(Color(0.035,0.045,0.055),0.42,0.55)
	var tire := _plain(Color(0.022,0.024,0.027),0.96,0.0)
	var red := _plain(Color(0.36,0.055,0.035),0.52,0.08)
	var cream := _plain(Color(0.55,0.50,0.42),0.72,0.0)
	var blue := _plain(Color(0.055,0.15,0.24),0.50,0.06)
	var glass_car: ShaderMaterial = _glass_material(Color(0.06,0.10,0.14,1.0),0.28,0.26)
	var warm_glow := _emissive(Color(1.0,0.72,0.36),2.2)
	var cool_glow := _emissive(Color(0.46,0.68,1.0),1.35)

	# Grounds and road hierarchy.
	_box("OutsideGroundL",Vector3(-8.2,-0.16,1.0),Vector3(6.0,0.20,17.0),grass)
	_box("OutsideGroundR",Vector3(8.2,-0.16,1.0),Vector3(6.0,0.20,17.0),grass)
	_box("FrontParking",Vector3(0,-0.10,8.2),Vector3(13.0,0.12,4.3),asphalt)
	_box("FrontCurb",Vector3(0,0.02,9.85),Vector3(13.0,0.18,0.25),concrete_light)
	_box("Road",Vector3(0,-0.11,12.1),Vector3(20.0,0.14,4.2),asphalt)
	_box("FarSidewalk",Vector3(0,-0.02,14.45),Vector3(20.0,0.18,1.0),concrete)
	for x in [-5.0,-2.5,0.0,2.5,5.0]:
		_box("ParkingStripe",Vector3(float(x),0.015,8.1),Vector3(0.075,0.025,2.4),line_white)
	for x in [-6.2,-2.1,2.0,6.1]:
		_box("RoadDash",Vector3(float(x),0.01,12.10),Vector3(1.65,0.025,0.10),line_yellow)
	_box("RoadEdgeNear",Vector3(0,0.01,10.35),Vector3(18.0,0.025,0.08),line_white)
	_box("RoadEdgeFar",Vector3(0,0.01,13.85),Vector3(18.0,0.025,0.08),line_white)

	# Two parked vehicles establish human scale and break up the forecourt.
	_build_car(Vector3(-3.35,0.0,8.25),red,glass_car,tire,dark_metal,-0.04)
	_build_car(Vector3(3.45,0.0,13.05),blue,glass_car,tire,dark_metal,0.03)

	# Streetlights and utility poles give vertical landmarks outside the glass.
	_build_streetlight(Vector3(-4.7,0.0,9.55),dark_metal,warm_glow,Color(1.0,0.70,0.34))
	_build_streetlight(Vector3(4.9,0.0,9.55),dark_metal,warm_glow,Color(1.0,0.70,0.34))
	_build_utility_pole(Vector3(-7.4,0.0,12.8),dark_metal)
	_build_utility_pole(Vector3(7.6,0.0,14.0),dark_metal)

	# Roadside sign near the forecourt; layered blocks read as a real pylon even without text.
	_box("RoadSignPost",Vector3(6.3,1.65,8.65),Vector3(0.16,3.30,0.16),dark_metal)
	_box("RoadSignPanel",Vector3(6.3,3.08,8.65),Vector3(1.65,0.92,0.18),cream)
	_box("RoadSignAccent",Vector3(6.3,3.16,8.54),Vector3(1.35,0.16,0.03),red)
	_box("RoadSignGlow",Vector3(6.3,2.88,8.54),Vector3(1.00,0.12,0.03),cool_glow)

	# Across-road buildings: enough facade detail to look inhabited, not random boxes.
	_build_roadside_building(Vector3(-4.9,0.0,17.1),Vector3(6.2,3.3,2.6),_plain(Color(0.25,0.22,0.18),0.82,0.0),dark_metal,warm_glow,false)
	_build_roadside_building(Vector3(3.2,0.0,17.4),Vector3(7.2,4.1,2.9),_plain(Color(0.18,0.22,0.25),0.78,0.0),dark_metal,cool_glow,true)
	_box("FarWarehouse",Vector3(10.2,1.65,20.0),Vector3(7.5,3.3,5.0),_plain(Color(0.12,0.14,0.15),0.88,0.0))

	# Vegetation and depth silhouettes. Box-built on purpose: cheap, readable, deterministic.
	_build_tree(Vector3(-8.6,0.0,4.3),1.05)
	_build_tree(Vector3(8.5,0.0,5.2),1.20)
	_build_tree(Vector3(-9.2,0.0,15.8),1.45)
	_build_tree(Vector3(9.4,0.0,17.2),1.55)
	_build_tree(Vector3(-1.2,0.0,20.2),1.55)
	_build_tree(Vector3(7.0,0.0,21.0),1.35)

	# Distant skyline breaks the horizon without pretending it is detailed geometry.
	var far_dark := _plain(Color(0.055,0.070,0.085),0.92,0.0)
	for item in [Vector4(-10.0,1.3,23.5,2.6),Vector4(-6.8,1.8,24.0,3.6),Vector4(-2.9,1.1,23.6,2.2),Vector4(1.0,1.7,24.5,3.4),Vector4(5.1,1.2,23.8,2.4),Vector4(9.2,1.9,24.2,3.8)]:
		_box("FarBuilding",Vector3(item.x,item.y * 0.5,item.z),Vector3(2.6,item.y,1.8),far_dark)

func _build_car(pos: Vector3, body: Material, glass: Material, wheel: Material, trim: Material, yaw: float) -> void:
	var car := Node3D.new()
	car.name = "RoadCar"
	car.position = pos
	car.rotation.y = yaw
	root.add_child(car)
	_box_local(car,"CarLower",Vector3(0,0.38,0),Vector3(2.75,0.52,1.32),body)
	_box_local(car,"CarCabin",Vector3(-0.12,0.78,-0.02),Vector3(1.55,0.55,1.18),body)
	_box_local(car,"Windshield",Vector3(0.54,0.83,-0.01),Vector3(0.035,0.42,1.04),glass)
	_box_local(car,"RearGlass",Vector3(-0.80,0.82,-0.01),Vector3(0.035,0.38,1.00),glass)
	_box_local(car,"FrontBumper",Vector3(1.42,0.28,0),Vector3(0.10,0.20,1.18),trim)
	_box_local(car,"RearBumper",Vector3(-1.42,0.28,0),Vector3(0.10,0.20,1.18),trim)
	for x in [-0.92,0.92]:
		for z in [-0.68,0.68]:
			_box_local(car,"Wheel",Vector3(float(x),0.23,float(z)),Vector3(0.48,0.48,0.18),wheel)

func _build_streetlight(pos: Vector3, metal: Material, lamp: Material, light_color: Color) -> void:
	_box("StreetlightPole",pos + Vector3(0,1.95,0),Vector3(0.12,3.90,0.12),metal)
	_box("StreetlightArm",pos + Vector3(0.38,3.76,0),Vector3(0.82,0.09,0.09),metal)
	_box("StreetlightLamp",pos + Vector3(0.76,3.68,0),Vector3(0.32,0.12,0.24),lamp)
	var light := OmniLight3D.new()
	light.name = "RoadLamp"
	light.position = pos + Vector3(0.75,3.55,0)
	light.omni_range = 5.2
	light.light_color = light_color
	light.light_energy = 0.34
	light.shadow_enabled = false
	root.add_child(light)

func _build_utility_pole(pos: Vector3, material: Material) -> void:
	_box("UtilityPole",pos + Vector3(0,2.3,0),Vector3(0.18,4.60,0.18),material)
	_box("UtilityCrossbar",pos + Vector3(0,4.18,0),Vector3(1.45,0.10,0.10),material)
	_box("UtilityWireA",pos + Vector3(0,4.20,0.34),Vector3(7.2,0.025,0.025),material)
	_box("UtilityWireB",pos + Vector3(0,4.02,-0.34),Vector3(7.2,0.025,0.025),material)

func _build_roadside_building(pos: Vector3, size: Vector3, wall: Material, frame: Material, window_glow: Material, taller: bool) -> void:
	var building := Node3D.new()
	building.name = "RoadsideBuilding"
	building.position = pos
	root.add_child(building)
	_box_local(building,"BuildingBody",Vector3(0,size.y * 0.5,0),size,wall)
	_box_local(building,"BuildingRoof",Vector3(0,size.y + 0.10,0),Vector3(size.x + 0.28,0.20,size.z + 0.28),frame)
	_box_local(building,"BuildingBand",Vector3(0,2.25,-size.z * 0.51),Vector3(size.x * 0.88,0.22,0.08),frame)
	var window_count: int = 4 if taller else 3
	for i in range(window_count):
		var wx: float = -size.x * 0.34 + float(i) * (size.x * 0.68 / maxf(float(window_count - 1),1.0))
		_box_local(building,"LitWindow",Vector3(wx,1.42,-size.z * 0.515),Vector3(0.78,0.72,0.045),window_glow)
		_box_local(building,"WindowTop",Vector3(wx,1.82,-size.z * 0.525),Vector3(0.90,0.08,0.07),frame)
	_box_local(building,"Door",Vector3(size.x * 0.34,0.72,-size.z * 0.52),Vector3(0.72,1.44,0.09),frame)

func _build_tree(pos: Vector3, scale: float) -> void:
	var trunk := _plain(Color(0.16,0.095,0.055),0.92,0.0)
	var leaf_dark := _plain(Color(0.055,0.18,0.075),0.94,0.0)
	var leaf_mid := _plain(Color(0.075,0.25,0.10),0.92,0.0)
	_box("TreeTrunk",pos + Vector3(0,0.95 * scale,0),Vector3(0.32 * scale,1.90 * scale,0.32 * scale),trunk)
	_box("TreeCrownA",pos + Vector3(-0.18 * scale,2.20 * scale,0),Vector3(1.45 * scale,1.20 * scale,1.25 * scale),leaf_dark)
	_box("TreeCrownB",pos + Vector3(0.32 * scale,2.65 * scale,0.12 * scale),Vector3(1.15 * scale,1.10 * scale,1.10 * scale),leaf_mid)
	_box("TreeCrownC",pos + Vector3(-0.28 * scale,2.95 * scale,-0.10 * scale),Vector3(0.95 * scale,0.90 * scale,0.92 * scale),leaf_dark)

func _glass_material(tint: Color, base_alpha: float, fresnel_alpha: float) -> ShaderMaterial:
	var shader := Shader.new()
	# depth_draw_alpha_prepass is the old Godot 3 spelling; Godot 4 WebGL uses depth_prepass_alpha.
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;
uniform vec4 tint_color : source_color = vec4(0.12, 0.19, 0.24, 1.0);
uniform float base_alpha = 0.16;
uniform float fresnel_alpha = 0.34;
void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 5.0);
	ALBEDO = mix(tint_color.rgb, vec3(0.42,0.50,0.56), fresnel * 0.22);
	ROUGHNESS = 0.10 + fresnel * 0.12;
	METALLIC = 0.0;
	SPECULAR = 0.68;
	ALPHA = clamp(base_alpha + fresnel * fresnel_alpha, 0.0, 0.72);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint_color",tint)
	material.set_shader_parameter("base_alpha",base_alpha)
	material.set_shader_parameter("fresnel_alpha",fresnel_alpha)
	return material

func _native_material(tile: int, tint: Color, normal_strength: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	if atlas_base:
		material.albedo_texture = atlas_base
	if atlas_normal:
		material.normal_enabled = true
		material.normal_texture = atlas_normal
		material.normal_scale = normal_strength
	if atlas_rough:
		material.roughness = 1.0
		material.roughness_texture = atlas_rough
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	if atlas_metal:
		material.metallic = 1.0
		material.metallic_texture = atlas_metal
		material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.uv1_scale = Vector3(1.0 / TILE_COUNT,1.0,1.0)
	material.uv1_offset = Vector3(float(tile) / TILE_COUNT,0.0,0.0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material

func _plain(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.24
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

func _find_first(node: Node, target: String) -> Node:
	if String(node.name) == target:
		return node
	for child in node.get_children():
		var found: Node = _find_first(child,target)
		if found:
			return found
	return null
