extends Node

const TILE_COUNT: float = 3.0
const TILE_DARK_FRAME: int = 0
const TILE_AGED_IVORY: int = 1
const TILE_PALE_CERAMIC: int = 2

var root: Node3D
var atlas_base: Texture2D
var atlas_normal: Texture2D
var atlas_rough: Texture2D
var atlas_metal: Texture2D

func _ready() -> void:
	# Pass 4 and Pass 5 build first; this layer deliberately overrides only finish materials.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	atlas_base = load("res://assets/pass6/material-atlas_basecolor.png") as Texture2D
	atlas_normal = load("res://assets/pass6/material-atlas_normal.png") as Texture2D
	atlas_rough = load("res://assets/pass6/material-atlas_roughness.png") as Texture2D
	atlas_metal = load("res://assets/pass6/material-atlas_metallic.png") as Texture2D
	if atlas_base == null or atlas_normal == null or atlas_rough == null or atlas_metal == null:
		push_error("Pass 6 native PBR atlas failed to load")
		return
	_apply_native_materials()
	_build_native_wall_skin()
	_add_finish_details()

func _apply_native_materials() -> void:
	var frame := _native_material(TILE_DARK_FRAME, Color(0.88,0.92,0.96), 0.92)
	var ivory := _native_material(TILE_AGED_IVORY, Color(1.0,0.98,0.92), 0.78)
	var ceramic := _native_material(TILE_PALE_CERAMIC, Color(0.93,0.96,1.0), 0.68)
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	for mesh in meshes:
		var n: String = String(mesh.name)
		match n:
			"Back", "LeftPost", "RightPost", "Register", "KickRail", "ColdShelf", "FridgeBody", "P4CeilingRail", "P4Canopy", "P4CanopyPost", "P4Pump2", "P4BackBand":
				mesh.material_override = frame
			"ShelfBoard", "CounterBase", "CrateBody", "CrateTop", "StandBase", "P4WallInset", "P5CounterWoodInset":
				mesh.material_override = ivory
			"CounterTop", "PumpInset", "P4Pump2Face", "FeatureStand", "P4WallPanel":
				mesh.material_override = ceramic

func _build_native_wall_skin() -> void:
	var frame := _native_material(TILE_DARK_FRAME, Color(0.82,0.88,0.94), 0.88)
	var ivory := _native_material(TILE_AGED_IVORY, Color(0.94,0.91,0.84), 0.72)
	var ceramic := _native_material(TILE_PALE_CERAMIC, Color(0.88,0.92,0.96), 0.62)
	for side in [-1, 1]:
		var x: float = float(side) * 5.055
		for i in range(7):
			var z: float = -4.85 + float(i) * 1.55
			var panel_mat: Material = ivory if (i % 3 != 1) else ceramic
			_box("P6SidePanel", Vector3(x,1.36,z), Vector3(0.045,2.12,1.38), panel_mat)
			_box("P6SideFrame", Vector3(x - float(side) * 0.022,1.36,z + 0.72), Vector3(0.065,2.18,0.045), frame)
	for i in range(6):
		var x2: float = -4.0 + float(i) * 1.60
		var back_mat: Material = ivory if i % 2 == 0 else ceramic
		_box("P6BackPanel", Vector3(x2,1.30,-6.055), Vector3(1.42,2.0,0.045), back_mat)
		_box("P6BackFrame", Vector3(x2 + 0.76,1.30,-6.03), Vector3(0.045,2.06,0.07), frame)
	_box("P6FrontKickL", Vector3(-3.18,0.47,5.835), Vector3(3.50,0.78,0.055), frame)
	_box("P6FrontKickR", Vector3(3.18,0.47,5.835), Vector3(3.50,0.78,0.055), frame)

func _add_finish_details() -> void:
	var frame := _native_material(TILE_DARK_FRAME, Color(0.90,0.94,0.98), 0.88)
	var ivory := _native_material(TILE_AGED_IVORY, Color(1.0,0.94,0.82), 0.74)
	_box("P6LeftBaseboard", Vector3(-5.015,0.16,-0.25), Vector3(0.07,0.22,10.8), frame)
	_box("P6RightBaseboard", Vector3(5.015,0.16,-0.25), Vector3(0.07,0.22,10.8), frame)
	var shelves: Array[Node] = []
	_collect_named(root,"RetailShelf",shelves)
	for shelf_node in shelves:
		var shelf := shelf_node as Node3D
		_box_local(shelf,"P6ShelfPlinth",Vector3(0,0.075,0.04),Vector3(1.38,0.10,0.54),frame)
		_box_local(shelf,"P6ShelfHeader",Vector3(0,1.90,0.10),Vector3(1.32,0.11,0.16),ivory)
	var counter := _find_first(root,"CheckoutCounter") as Node3D
	if counter:
		_box_local(counter,"P6CounterBase",Vector3(0,0.10,0),Vector3(1.95,0.13,0.82),frame)
	var rim := OmniLight3D.new()
	rim.name = "P6CoolRim"
	rim.position = Vector3(-3.3,2.35,-1.5)
	rim.omni_range = 5.8
	rim.light_color = Color(0.52,0.74,1.0)
	rim.light_energy = 0.34
	root.add_child(rim)

func _native_material(tile: int, tint: Color, normal_strength: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = atlas_base
	material.normal_enabled = true
	material.normal_texture = atlas_normal
	material.normal_scale = normal_strength
	material.roughness = 1.0
	material.roughness_texture = atlas_rough
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
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

func _collect_named(node: Node, target: String, out: Array[Node]) -> void:
	if String(node.name) == target:
		out.append(node)
	for child in node.get_children():
		_collect_named(child,target,out)

func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child,out)
