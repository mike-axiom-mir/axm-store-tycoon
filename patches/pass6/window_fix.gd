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
	# Run after the other visual passes and rebuild the openings last.
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
		# Continuous solid base and head give the glass believable wall depth.
		_box("SideLowerWall",Vector3(x_wall,0.52,-0.18),Vector3(0.14,1.04,10.70),wall)
		_box("SideUpperWall",Vector3(x_wall,2.60,-0.18),Vector3(0.14,0.64,10.70),wall)
		# Rear half stays solid for stock/service space.
		_box("SideRearWall",Vector3(x_wall,1.64,-3.25),Vector3(0.14,1.58,4.35),wall)
		# Front corner/pier keeps the facade structurally believable.
		_box("SideFrontPier",Vector3(x_wall,1.64,5.22),Vector3(0.14,1.58,0.92),wall)

		for z in bay_centers:
			_box("SideGlassBay",Vector3(x_glass,1.65,z),Vector3(0.028,1.25,1.52),glass)
			# Deep sill and head cap catch light like an actual storefront extrusion.
			_box("SideWindowSill",Vector3(x_wall - sidef * 0.035,1.015,z),Vector3(0.18,0.085,1.68),frame)
			_box("SideWindowHead",Vector3(x_wall - sidef * 0.035,2.285,z),Vector3(0.18,0.085,1.68),frame)
			_box("SideWindowJambA",Vector3(x_wall - sidef * 0.035,1.65,z - 0.80),Vector3(0.18,1.34,0.085),frame)
			_box("SideWindowJambB",Vector3(x_wall - sidef * 0.035,1.65,z + 0.80),Vector3(0.18,1.34,0.085),frame)

		# One restrained retail color band ties the side bays back to the storefront.
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
		env.background_color = Color(0.105,0.22,0.38)
		env.ambient_light_color = Color(0.50,0.59,0.69)
		env.ambient_light_energy = 0.45
		env.adjustment_enabled = true
		env.adjustment_brightness = 0.84
		env.adjustment_contrast = 1.10
		env.adjustment_saturation = 0.96
	var sun := root.get_node_or_null("ExteriorSoftLight") as DirectionalLight3D
	if sun:
		sun.light_energy = 0.36
		sun.light_color = Color(0.72,0.81,0.94)

func _add_outside_depth() -> void:
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.055,0.12,0.06)
	grass.roughness = 0.98
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.22,0.24,0.26)
	concrete.roughness = 0.92
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.035,0.045,0.055)
	asphalt.roughness = 0.96
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.035,0.045,0.055)
	dark.roughness = 0.78
	# Give every window something with depth and scale to look at.
	_box("OutsideGroundL",Vector3(-7.3,-0.13,-0.5),Vector3(4.2,0.18,13.0),grass)
	_box("OutsideGroundR",Vector3(7.3,-0.13,-0.5),Vector3(4.2,0.18,13.0),grass)
	_box("SideAccessL",Vector3(-6.0,-0.02,2.1),Vector3(1.2,0.10,7.4),concrete)
	_box("SideAccessR",Vector3(6.0,-0.02,2.1),Vector3(1.2,0.10,7.4),concrete)
	_box("FarRoad",Vector3(0,-0.08,12.2),Vector3(18.0,0.14,3.4),asphalt)
	for x in [-6.2,-2.8,5.9]:
		_box("RoadsideSilhouette",Vector3(float(x),0.85,15.5),Vector3(1.6,1.7,0.7),dark)

func _glass_material(tint: Color, base_alpha: float, fresnel_alpha: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_disabled;
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
