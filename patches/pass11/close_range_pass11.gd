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
	for _i in range(15):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_load_atlas()
	_clean_visible_wall_materials(root)
	_rebuild_upgrade_terminal()
	_rebuild_feature_stand()
	_refine_counter_edges()
	_detail_visible_wall()
	_compact_top_hud(root)

func _load_atlas() -> void:
	atlas_base = load("res://assets/pass6/material-atlas_basecolor.png") as Texture2D
	atlas_normal = load("res://assets/pass6/material-atlas_normal.png") as Texture2D
	atlas_rough = load("res://assets/pass6/material-atlas_roughness.png") as Texture2D
	atlas_metal = load("res://assets/pass6/material-atlas_metallic.png") as Texture2D

func _clean_visible_wall_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var n := String(mesh.name)
		if n.begins_with("SideLowerWall") or n.begins_with("SideUpperWall") or n.begins_with("SideRearWall") or n.begins_with("SideFrontPier"):
			mesh.material_override = _paint(Color(0.53,0.50,0.44),0.86)
	for child in node.get_children():
		_clean_visible_wall_materials(child)

func _rebuild_upgrade_terminal() -> void:
	var holder := _find_first(root,"UpgradeTerminal") as Node3D
	if holder == null:
		return
	_hide_mesh_children(holder)
	var dark := _native_material(TILE_DARK_FRAME,Color(0.32,0.36,0.40),0.76)
	var ivory := _native_material(TILE_AGED_IVORY,Color(0.78,0.74,0.65),0.54)
	var rubber := _paint(Color(0.018,0.022,0.026),0.96)
	var cyan := _emissive(Color(0.08,0.64,0.78),1.40)
	var orange := _emissive(Color(0.92,0.24,0.055),1.05)

	_box_local(holder,"P11KioskFoot",Vector3(0,-0.98,0),Vector3(0.54,0.10,0.48),rubber)
	_box_local(holder,"P11KioskPedestal",Vector3(0,-0.56,0),Vector3(0.38,0.78,0.34),dark)
	_box_local(holder,"P11KioskNeck",Vector3(0,-0.08,0),Vector3(0.28,0.22,0.26),ivory)
	_box_local(holder,"P11KioskHead",Vector3(0,0.24,0),Vector3(0.64,0.50,0.30),dark)
	_box_local_rot(holder,"P11ScreenFront",Vector3(0,0.27,-0.168),Vector3(0.46,0.31,0.022),cyan,Vector3(-8,0,0))
	_box_local_rot(holder,"P11ScreenBack",Vector3(0,0.27,0.168),Vector3(0.46,0.31,0.022),cyan,Vector3(-8,180,0))
	_box_local(holder,"P11KioskBadge",Vector3(0,-0.25,-0.19),Vector3(0.22,0.055,0.022),orange)
	_box_local(holder,"P11KioskCable",Vector3(0.19,-0.53,0.16),Vector3(0.035,0.64,0.035),rubber)

func _rebuild_feature_stand() -> void:
	var holder := _find_first(root,"FeatureStand") as Node3D
	if holder == null:
		return
	_hide_mesh_children(holder)
	var dark := _native_material(TILE_DARK_FRAME,Color(0.34,0.38,0.42),0.74)
	var ivory := _native_material(TILE_AGED_IVORY,Color(0.82,0.77,0.67),0.56)
	var orange := _emissive(Color(0.92,0.25,0.055),0.70)
	_box_local(holder,"P11StandPlinth",Vector3(0,0.10,0),Vector3(0.82,0.18,0.82),dark)
	_box_local(holder,"P11StandColumn",Vector3(0,0.42,0),Vector3(0.50,0.54,0.50),ivory)
	_box_local(holder,"P11StandShelfA",Vector3(0,0.72,0),Vector3(0.92,0.075,0.92),dark)
	_box_local(holder,"P11StandColumn2",Vector3(0,0.88,0),Vector3(0.38,0.25,0.38),ivory)
	_box_local(holder,"P11StandShelfB",Vector3(0,1.04,0),Vector3(0.72,0.065,0.72),dark)
	_box_local(holder,"P11StandSignStem",Vector3(0,1.32,0.22),Vector3(0.055,0.50,0.055),dark)
	_box_local(holder,"P11StandSign",Vector3(0,1.54,0.22),Vector3(0.52,0.26,0.055),orange)

func _refine_counter_edges() -> void:
	var counter := _find_first(root,"CheckoutCounter") as Node3D
	if counter == null:
		return
	var dark := _native_material(TILE_DARK_FRAME,Color(0.36,0.40,0.44),0.76)
	var orange := _emissive(Color(0.92,0.24,0.055),0.60)
	# Thin corner/edge profiles make the block read as assembled cabinetry.
	for x in [-1.07,1.07]:
		_box_local(counter,"P11CounterCorner",Vector3(float(x),0.52,-0.48),Vector3(0.045,0.86,0.045),dark)
	_box_local(counter,"P11CounterTopEdge",Vector3(0,1.075,-0.49),Vector3(2.16,0.045,0.045),dark)
	_box_local(counter,"P11CounterStatus",Vector3(0.75,0.62,-0.515),Vector3(0.34,0.045,0.018),orange)

func _detail_visible_wall() -> void:
	var dark := _native_material(TILE_DARK_FRAME,Color(0.30,0.34,0.37),0.78)
	var ivory := _native_material(TILE_AGED_IVORY,Color(0.82,0.78,0.69),0.55)
	var orange := _paint(Color(0.48,0.10,0.045),0.50)
	# Current camera faces the +X wall; build the detail there, inside the glazing bays.
	_box("P11VisibleWallRail",Vector3(4.90,0.92,0.65),Vector3(0.055,0.085,7.60),dark)
	for z in [-2.55,-0.35,1.85,4.05]:
		_box("P11WallPanel",Vector3(4.91,0.61,float(z)),Vector3(0.045,0.46,1.45),ivory)
		_box("P11WallPanelStripe",Vector3(4.88,0.61,float(z)),Vector3(0.018,0.10,1.10),orange)
	# Narrow upper service track and little junction boxes add real-world construction logic.
	_box("P11UpperTrack",Vector3(4.90,2.55,0.20),Vector3(0.055,0.07,8.25),dark)
	for z in [-2.8,0.0,2.8]:
		_box("P11JunctionBox",Vector3(4.86,2.38,float(z)),Vector3(0.12,0.24,0.30),dark)

func _compact_top_hud(node: Node) -> void:
	if node is PanelContainer:
		var panel := node as PanelContainer
		if absf(panel.size.x - 330.0) < 6.0 and absf(panel.size.y - 116.0) < 6.0:
			var label := _first_label(panel)
			if label:
				label.position = Vector2(12,8)
				label.size = Vector2(276,80)
				label.add_theme_font_size_override("font_size",17)
			panel.size = Vector2(302,100)
		elif absf(panel.size.x - 332.0) < 6.0 and absf(panel.size.y - 150.0) < 6.0:
			var inv := _first_label(panel)
			if inv:
				inv.position = Vector2(10,8)
				inv.size = Vector2(278,102)
				inv.add_theme_font_size_override("font_size",15)
			panel.position = Vector2(-318,18)
			panel.size = Vector2(300,120)
	for child in node.get_children():
		_compact_top_hud(child)

func _first_label(node: Node) -> Label:
	for child in node.get_children():
		if child is Label:
			return child as Label
	return null

func _hide_mesh_children(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
		else:
			_hide_mesh_children(child)

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

func _paint(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.18
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

func _box_local_rot(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material, rot: Vector3) -> MeshInstance3D:
	var instance := _box_local(parent,node_name,pos,size,material)
	instance.rotation_degrees = rot
	return instance

func _find_first(node: Node, target: String) -> Node:
	if String(node.name) == target:
		return node
	for child in node.get_children():
		var found := _find_first(child,target)
		if found:
			return found
	return null
