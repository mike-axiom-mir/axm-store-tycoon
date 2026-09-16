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
var prompt_panel: PanelContainer
var prompt_text: Label

func _ready() -> void:
	for _i in range(13):
		await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_load_atlas()
	_find_prompt_panel(root)
	_polish_static_hud(root)
	_upgrade_checkout()
	_upgrade_shelves()
	_add_ceiling_utilities()
	_add_entrance_retail_clutter()
	_break_up_blank_wall()
	_update_prompt_visibility()

func _process(_delta: float) -> void:
	_update_prompt_visibility()

func _load_atlas() -> void:
	atlas_base = load("res://assets/pass6/material-atlas_basecolor.png") as Texture2D
	atlas_normal = load("res://assets/pass6/material-atlas_normal.png") as Texture2D
	atlas_rough = load("res://assets/pass6/material-atlas_roughness.png") as Texture2D
	atlas_metal = load("res://assets/pass6/material-atlas_metallic.png") as Texture2D

func _find_prompt_panel(node: Node) -> void:
	if node is PanelContainer:
		var panel := node as PanelContainer
		if absf(panel.size.x - 640.0) < 4.0 and absf(panel.size.y - 78.0) < 4.0:
			prompt_panel = panel
			for child in panel.get_children():
				if child is Label:
					prompt_text = child as Label
					break
	for child in node.get_children():
		if prompt_panel == null:
			_find_prompt_panel(child)

func _update_prompt_visibility() -> void:
	if prompt_panel and prompt_text:
		prompt_panel.visible = not prompt_text.text.strip_edges().is_empty()

func _polish_static_hud(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if label.text.begins_with("WASD / Left stick"):
			label.modulate = Color(1,1,1,0.28)
			label.add_theme_font_size_override("font_size",12)
	for child in node.get_children():
		_polish_static_hud(child)

func _upgrade_checkout() -> void:
	var counter := _find_first(root,"CheckoutCounter") as Node3D
	if counter == null:
		return
	var dark := _native_material(TILE_DARK_FRAME,Color(0.36,0.40,0.44),0.78)
	var ivory := _native_material(TILE_AGED_IVORY,Color(0.82,0.78,0.68),0.56)
	var ceramic := _native_material(TILE_PALE_CERAMIC,Color(0.88,0.90,0.91),0.48)
	var rubber := _plain(Color(0.020,0.025,0.030),0.96,0.0)
	var orange := _emissive(Color(0.95,0.28,0.075),1.35)
	var cyan := _emissive(Color(0.10,0.68,0.78),1.25)

	# Break the monolithic counter into manufactured subassemblies.
	_box_local(counter,"P10CounterLowerInset",Vector3(0,0.48,-0.472),Vector3(1.52,0.55,0.022),dark)
	_box_local(counter,"P10CounterLeftTrim",Vector3(-0.86,0.50,-0.486),Vector3(0.055,0.72,0.035),ivory)
	_box_local(counter,"P10CounterRightTrim",Vector3(0.86,0.50,-0.486),Vector3(0.055,0.72,0.035),ivory)
	_box_local(counter,"P10CounterToeKick",Vector3(0,0.09,-0.478),Vector3(1.70,0.12,0.045),rubber)
	_box_local(counter,"P10ScannerBed",Vector3(-0.36,1.078,-0.04),Vector3(0.56,0.025,0.46),rubber)
	_box_local(counter,"P10ScannerGlass",Vector3(-0.36,1.096,-0.04),Vector3(0.42,0.018,0.34),cyan)
	_box_local(counter,"P10ReceiptPrinter",Vector3(0.20,1.17,0.24),Vector3(0.36,0.20,0.34),ceramic)
	_box_local(counter,"P10ReceiptSlot",Vector3(0.20,1.275,0.15),Vector3(0.22,0.025,0.055),rubber)
	_box_local(counter,"P10CardStem",Vector3(0.67,1.22,-0.26),Vector3(0.07,0.30,0.07),dark)
	_box_local(counter,"P10CardTerminal",Vector3(0.67,1.41,-0.28),Vector3(0.28,0.32,0.10),dark)
	_box_local(counter,"P10CardScreen",Vector3(0.67,1.43,-0.338),Vector3(0.20,0.18,0.018),cyan)
	_box_local(counter,"P10ImpulseRail",Vector3(-0.70,0.83,-0.53),Vector3(0.42,0.055,0.06),orange)
	for y in [0.36,0.58,0.80]:
		_box_local(counter,"P10ImpulseShelf",Vector3(-0.70,float(y),-0.54),Vector3(0.44,0.035,0.16),dark)
		for x in [-0.12,0.0,0.12]:
			_box_local(counter,"P10ImpulsePack",Vector3(-0.70+float(x),float(y)+0.09,-0.56),Vector3(0.075,0.14,0.06),orange if int((y*100.0)+x*10.0) % 2 == 0 else ivory)

func _upgrade_shelves() -> void:
	var shelves: Array[Node] = []
	_collect_named(root,"RetailShelf",shelves)
	var dark := _native_material(TILE_DARK_FRAME,Color(0.34,0.38,0.42),0.75)
	var ivory := _native_material(TILE_AGED_IVORY,Color(0.86,0.81,0.70),0.54)
	var price := _emissive(Color(0.88,0.36,0.09),0.60)
	for shelf_node in shelves:
		var shelf := shelf_node as Node3D
		for y in [0.24,0.62,1.00,1.38,1.76]:
			_box_local(shelf,"P10ShelfRail",Vector3(0,float(y),-0.315),Vector3(1.22,0.045,0.055),dark)
			for x in [-0.42,0.0,0.42]:
				_box_local(shelf,"P10PriceTag",Vector3(float(x),float(y)+0.002,-0.347),Vector3(0.20,0.025,0.012),price)
		_box_local(shelf,"P10ShelfHeaderInset",Vector3(0,1.93,-0.01),Vector3(0.94,0.10,0.035),ivory)
		_box_local(shelf,"P10ShelfEndcapL",Vector3(-0.70,0.96,-0.02),Vector3(0.04,1.76,0.50),dark)
		_box_local(shelf,"P10ShelfEndcapR",Vector3(0.70,0.96,-0.02),Vector3(0.04,1.76,0.50),dark)

func _add_ceiling_utilities() -> void:
	var dark := _native_material(TILE_DARK_FRAME,Color(0.24,0.28,0.31),0.82)
	var vent := _plain(Color(0.10,0.12,0.13),0.76,0.18)
	var pipe := _plain(Color(0.25,0.27,0.27),0.58,0.42)
	var red := _plain(Color(0.62,0.055,0.035),0.52,0.18)
	# Vent grilles are intentionally broad enough to read from the start camera.
	for pos in [Vector3(-2.65,2.91,-2.65),Vector3(2.45,2.91,-1.30),Vector3(-0.15,2.91,2.25)]:
		_box("P10VentFrame",pos,Vector3(1.10,0.055,0.62),dark)
		for i in range(5):
			_box("P10VentSlat",pos + Vector3(-0.40 + float(i)*0.20,-0.035,0),Vector3(0.045,0.025,0.46),vent)
	_box("P10CeilingConduit",Vector3(4.35,2.87,-0.30),Vector3(0.06,0.06,8.70),pipe)
	for z in [-3.0,0.2,3.1]:
		_box("P10SprinklerStem",Vector3(4.34,2.80,float(z)),Vector3(0.055,0.18,0.055),pipe)
		_box("P10SprinklerHead",Vector3(4.34,2.69,float(z)),Vector3(0.18,0.045,0.18),red)

func _add_entrance_retail_clutter() -> void:
	var dark := _native_material(TILE_DARK_FRAME,Color(0.30,0.34,0.37),0.76)
	var ivory := _native_material(TILE_AGED_IVORY,Color(0.84,0.80,0.71),0.52)
	var red := _plain(Color(0.70,0.055,0.035),0.48,0.12)
	var orange := _emissive(Color(0.92,0.27,0.07),0.85)
	var cyan := _emissive(Color(0.10,0.64,0.76),0.65)
	# Basket stack near entrance.
	for i in range(4):
		var y: float = 0.16 + float(i)*0.10
		_box("P10Basket",Vector3(-0.85,y,4.65),Vector3(0.58,0.08,0.38),red)
		_box("P10BasketHole",Vector3(-0.85,y+0.025,4.65),Vector3(0.42,0.025,0.24),dark)
	_box("P10BasketStand",Vector3(-0.85,0.34,4.65),Vector3(0.68,0.06,0.48),dark)
	# Fire extinguisher + wall bracket near the right front pier.
	_cylinder("P10Extinguisher",Vector3(4.55,0.62,4.95),0.13,0.78,red,18)
	_box("P10ExtinguisherBracket",Vector3(4.55,0.72,5.05),Vector3(0.34,0.08,0.08),dark)
	_box("P10ExtinguisherTag",Vector3(4.55,1.12,5.04),Vector3(0.26,0.16,0.025),orange)
	# Small poster/lightbox breaks the blank front wall without becoming another giant sign.
	_box("P10PosterFrame",Vector3(-3.55,1.82,5.69),Vector3(1.02,1.18,0.08),dark)
	_box("P10PosterFace",Vector3(-3.55,1.82,5.63),Vector3(0.86,1.00,0.025),ivory)
	_box("P10PosterAccent",Vector3(-3.55,2.12,5.60),Vector3(0.64,0.12,0.018),orange)
	_box("P10PosterAccent",Vector3(-3.55,1.76,5.60),Vector3(0.46,0.08,0.018),cyan)

func _break_up_blank_wall() -> void:
	var dark := _native_material(TILE_DARK_FRAME,Color(0.28,0.31,0.33),0.80)
	var ivory := _native_material(TILE_AGED_IVORY,Color(0.78,0.73,0.64),0.58)
	var orange := _plain(Color(0.48,0.11,0.055),0.48,0.10)
	# Interior service rail and three shallow feature panels on the currently dominant wall.
	_box("P10WallRail",Vector3(-5.00,1.08,-1.05),Vector3(0.08,0.08,7.45),dark)
	for z in [-3.25,-1.05,1.15]:
		_box("P10WallFeature",Vector3(-4.96,1.78,float(z)),Vector3(0.06,0.88,1.42),ivory)
		_box("P10WallFeatureInset",Vector3(-4.92,1.78,float(z)),Vector3(0.025,0.62,1.12),orange)

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

func _cylinder(node_name: String, pos: Vector3, radius: float, height: float, material: Material, segments: int) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
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

func _collect_named(node: Node, target: String, out: Array[Node]) -> void:
	if String(node.name) == target:
		out.append(node)
	for child in node.get_children():
		_collect_named(child,target,out)
