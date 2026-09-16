extends Node

const TEX_SIZE: int = 96
var root: Node3D
var map_cache: Dictionary = {}

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	root = get_parent() as Node3D
	if root == null:
		return
	_apply_fabric_materials()
	_tune_glass_and_lighting()
	_add_manufactured_detail()

func _apply_fabric_materials() -> void:
	var brushed := _fabric_material("brushed-steel", 5.0, Color(0.72,0.76,0.79))
	var painted := _fabric_material("painted-steel", 4.5, Color(0.52,0.72,0.72))
	var oak := _fabric_material("oak", 3.2, Color(0.74,0.66,0.56))
	var granite := _fabric_material("granite", 3.8, Color(0.45,0.52,0.57))
	var concrete := _fabric_material("concrete", 3.5, Color(0.72,0.72,0.69))
	var asphalt := _fabric_material("asphalt", 6.0, Color(0.70,0.73,0.76))
	var plastic := _fabric_material("hard-plastic", 4.0, Color(0.58,0.72,0.76))
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	for mesh in meshes:
		var n: String = String(mesh.name)
		match n:
			"P4Tile": mesh.material_override = granite
			"WallLeftVisual", "WallRightVisual", "WallBackVisual", "P4WallPanel": mesh.material_override = concrete
			"ShelfBoard", "CounterBase", "CrateBody", "CrateTop", "StandBase", "P4WallInset": mesh.material_override = oak
			"Back", "LeftPost", "RightPost", "Register", "KickRail", "ColdShelf", "P4CeilingRail", "P4Canopy", "P4CanopyPost": mesh.material_override = brushed
			"FridgeBody", "FrontLeftLowVisual", "FrontRightLowVisual", "P4LeftLowerWall", "P4RightLowerWall", "P4Pump2": mesh.material_override = painted
			"PumpBody", "PumpInset", "P4Pump2Face", "FeatureStand": mesh.material_override = plastic
			"Street": mesh.material_override = asphalt
			"CounterTop": mesh.material_override = granite

func _tune_glass_and_lighting() -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.47,0.72,0.82,0.17)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.08
	glass.metallic = 0.08
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	for mesh in meshes:
		var n: String = String(mesh.name)
		if n == "GlassL" or n == "GlassR" or n == "DoorGlass" or n == "Glass":
			mesh.material_override = glass
	var sun := root.get_node_or_null("ExteriorSoftLight") as DirectionalLight3D
	if sun:
		sun.light_energy = 0.58
		sun.light_color = Color(0.77,0.86,0.98)
	var probe := ReflectionProbe.new()
	probe.name = "P5InteriorReflection"
	probe.position = Vector3(0,1.45,-0.2)
	probe.size = Vector3(9.8,2.8,11.2)
	probe.intensity = 0.72
	probe.box_projection = true
	probe.interior = true
	root.add_child(probe)
	_add_spot(Vector3(-2.6,2.72,-0.8), Vector3(-65,0,0), Color(1.0,0.73,0.43), 2.6, 48.0)
	_add_spot(Vector3(2.9,2.70,1.9), Vector3(-68,0,0), Color(1.0,0.80,0.58), 2.2, 45.0)

func _add_spot(pos: Vector3, rot: Vector3, color: Color, energy: float, angle: float) -> void:
	var light := SpotLight3D.new()
	light.position = pos
	light.rotation_degrees = rot
	light.light_color = color
	light.light_energy = energy
	light.spot_range = 5.5
	light.spot_angle = angle
	light.shadow_enabled = true
	root.add_child(light)

func _add_manufactured_detail() -> void:
	var brushed := _fabric_material("brushed-steel", 7.0, Color(0.80,0.83,0.85))
	var painted := _fabric_material("painted-steel", 5.0, Color(0.44,0.62,0.62))
	var oak := _fabric_material("oak", 4.0, Color(0.74,0.62,0.50))
	var shelves: Array[Node] = []
	_collect_named(root, "RetailShelf", shelves)
	for shelf_node in shelves:
		var shelf := shelf_node as Node3D
		_cylinder_local(shelf,"P5ShelfRailL",Vector3(-0.67,0.98,-0.26),0.026,1.72,brushed,16)
		_cylinder_local(shelf,"P5ShelfRailR",Vector3(0.67,0.98,-0.26),0.026,1.72,brushed,16)
		for y in [0.23,0.61,0.99,1.37,1.75]:
			_box_local(shelf,"P5PriceStrip",Vector3(0,y,-0.315),Vector3(1.22,0.032,0.024),painted)
	var counter := _find_first(root,"CheckoutCounter") as Node3D
	if counter:
		_box_local(counter,"P5CounterWoodInset",Vector3(0,0.52,-0.493),Vector3(1.25,0.42,0.022),oak)
		_cylinder_local(counter,"P5CounterRail",Vector3(0,0.19,-0.525),0.026,1.55,brushed,18,Vector3(0,0,90))
	var concrete := _fabric_material("concrete",3.5,Color(0.74,0.74,0.70))
	_box_world("P5PumpIsland",Vector3(2.25,0.09,7.75),Vector3(4.2,0.18,1.16),concrete)
	_box_world("P5CanopyFascia",Vector3(2.25,2.92,6.56),Vector3(4.45,0.25,0.11),painted)
	_label_world("FUEL  •  MARKET",Vector3(2.25,2.93,6.48),Vector3(0,180,0),28,Color(1.0,0.78,0.48))

func _fabric_material(id: String, uv_scale: float, tint: Color) -> StandardMaterial3D:
	var maps: Dictionary = _fabric_maps(id)
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = maps["base"] as Texture2D
	material.roughness = 1.0
	material.roughness_texture = maps["rough"] as Texture2D
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.metallic = 1.0
	material.metallic_texture = maps["metal"] as Texture2D
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = true
	material.normal_texture = maps["normal"] as Texture2D
	material.normal_scale = 0.86
	material.ao_enabled = true
	material.ao_texture = maps["ao"] as Texture2D
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.ao_light_affect = 0.72
	material.uv1_scale = Vector3(uv_scale,uv_scale,uv_scale)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material

func _fabric_maps(id: String) -> Dictionary:
	if map_cache.has(id):
		var cached: Dictionary = map_cache[id]
		return cached
	var d: Dictionary = _descriptor(id)
	var base_image := Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGBA8)
	var normal_image := Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGBA8)
	var rough_image := Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGBA8)
	var metal_image := Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGBA8)
	var ao_image := Image.create(TEX_SIZE,TEX_SIZE,false,Image.FORMAT_RGBA8)
	for y in range(TEX_SIZE):
		for x in range(TEX_SIZE):
			var u: float = (float(x) + 0.5) / float(TEX_SIZE)
			var v: float = (float(y) + 0.5) / float(TEX_SIZE)
			var sample: Dictionary = _family_sample(d,u,v)
			var bc: Color = sample["base"]
			base_image.set_pixel(x,y,bc)
			var rough: float = float(sample["rough"])
			var metal: float = float(sample["metal"])
			var ao: float = float(sample["ao"])
			rough_image.set_pixel(x,y,Color(rough,rough,rough,1.0))
			metal_image.set_pixel(x,y,Color(metal,metal,metal,1.0))
			ao_image.set_pixel(x,y,Color(ao,ao,ao,1.0))
			var nn: Color = _normal_sample(d,u,v,1.0 / float(TEX_SIZE))
			normal_image.set_pixel(x,y,nn)
	base_image.generate_mipmaps()
	normal_image.generate_mipmaps()
	rough_image.generate_mipmaps()
	metal_image.generate_mipmaps()
	ao_image.generate_mipmaps()
	var maps: Dictionary = {
		"base": ImageTexture.create_from_image(base_image),
		"normal": ImageTexture.create_from_image(normal_image),
		"rough": ImageTexture.create_from_image(rough_image),
		"metal": ImageTexture.create_from_image(metal_image),
		"ao": ImageTexture.create_from_image(ao_image)
	}
	map_cache[id] = maps
	return maps

func _descriptor(id: String) -> Dictionary:
	match id:
		"brushed-steel": return _desc("brushed",13.0,Color8(85,94,101),Color8(174,182,188),Color8(229,234,237),0.22,0.48,0.94,0.05,0.16,0.45,0.28,1301)
		"painted-steel": return _desc("painted",9.0,Color8(32,55,72),Color8(55,105,130),Color8(143,177,191),0.32,0.62,0.18,0.08,0.28,0.75,0.55,1302)
		"oak": return _desc("wood",8.0,Color8(75,45,23),Color8(151,100,58),Color8(200,156,98),0.42,0.70,0.0,0.05,0.28,0.70,0.55,1303)
		"concrete": return _desc("concrete",8.0,Color8(85,87,82),Color8(133,135,127),Color8(183,184,173),0.66,0.94,0.0,0.05,0.48,1.05,0.82,1304)
		"granite": return _desc("granite",18.0,Color8(37,39,41),Color8(119,114,112),Color8(198,192,187),0.42,0.72,0.02,0.05,0.30,0.85,0.65,1305)
		"asphalt": return _desc("asphalt",28.0,Color8(21,23,25),Color8(48,51,54),Color8(85,89,92),0.72,0.98,0.0,0.05,0.58,1.25,0.90,1306)
		"hard-plastic": return _desc("plastic",8.0,Color8(24,37,51),Color8(49,91,114),Color8(139,176,192),0.26,0.54,0.02,0.03,0.12,0.35,0.25,1307)
		_: return _desc("concrete",8.0,Color8(85,87,82),Color8(133,135,127),Color8(183,184,173),0.60,0.88,0.0,0.05,0.30,0.70,0.60,1999)

func _desc(pattern: String, scale: float, c0: Color, c1: Color, c2: Color, r0: float, r1: float, metallic: float, metallic_spread: float, ao_strength: float, normal_strength: float, height_contrast: float, seed: int) -> Dictionary:
	return {"pattern":pattern,"scale":scale,"c0":c0,"c1":c1,"c2":c2,"r0":r0,"r1":r1,"metallic":metallic,"metallic_spread":metallic_spread,"ao_strength":ao_strength,"normal_strength":normal_strength,"height_contrast":height_contrast,"seed":seed}

func _family_sample(d: Dictionary, u: float, v: float) -> Dictionary:
	var feature: float = _pattern_value(d,u,v)
	var scale: float = float(d["scale"])
	var seed: int = int(d["seed"])
	var detail: float = _fbm(seed + 909,u * scale * 2.4,v * scale * 2.4,3)
	var height: float = clampf(0.5 + (feature - 0.5) * float(d["height_contrast"]),0.0,1.0)
	var blend: float = clampf(feature * 0.62 + detail * 0.38,0.0,1.0)
	var rough: float = clampf(lerpf(float(d["r0"]),float(d["r1"]),blend),0.0,1.0)
	var metal: float = clampf(float(d["metallic"]) + (detail - 0.5) * float(d["metallic_spread"]),0.0,1.0)
	var ao_strength: float = float(d["ao_strength"])
	var ao: float = clampf(1.0 - ao_strength * (1.0 - height) * 0.72 - ao_strength * absf(feature - detail) * 0.28,0.0,1.0)
	var color_mix: float = clampf(feature * 0.72 + detail * 0.28,0.0,1.0)
	var c0: Color = d["c0"]
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var base: Color = c0.lerp(c1,color_mix)
	if detail > 0.82:
		base = base.lerp(c2,_smoothstep(0.82,1.0,detail))
	var grime: float = _smoothstep(0.52,0.84,_fbm(seed + 505,u * scale * 0.75,v * scale * 0.75,4))
	var scratch_wave: float = 0.5 + 0.5 * sin((u * 28.0 * 19.0 + _fbm(seed + 101,u * 28.0,v * 28.0,3) * 5.0) * PI)
	var scratches: float = _smoothstep(0.965,0.998,scratch_wave)
	if String(d["pattern"]) == "brushed" or String(d["pattern"]) == "painted":
		base = base.lerp(Color(0.07,0.075,0.075),grime * 0.10)
		base = base.lerp(Color(0.80,0.84,0.85),scratches * 0.10)
		rough = clampf(rough + grime * 0.08 + scratches * 0.03,0.0,1.0)
	return {"base":base,"height":height,"rough":rough,"metal":metal,"ao":ao}

func _normal_sample(d: Dictionary, u: float, v: float, step: float) -> Color:
	var left: float = _height(d,u-step,v)
	var right: float = _height(d,u+step,v)
	var down: float = _height(d,u,v-step)
	var up: float = _height(d,u,v+step)
	var strength: float = float(d["normal_strength"]) * 4.0
	var normal := Vector3(-(right-left)*strength,-(up-down)*strength,1.0).normalized()
	return Color(normal.x * 0.5 + 0.5,normal.y * 0.5 + 0.5,normal.z * 0.5 + 0.5,1.0)

func _height(d: Dictionary, u: float, v: float) -> float:
	var feature: float = _pattern_value(d,_fract(u + 1000.0),_fract(v + 1000.0))
	return clampf(0.5 + (feature - 0.5) * float(d["height_contrast"]),0.0,1.0)

func _pattern_value(d: Dictionary, u: float, v: float) -> float:
	var scale: float = float(d["scale"])
	var seed: int = int(d["seed"])
	var x: float = u * scale
	var y: float = v * scale
	var n: float = _fbm(seed,x,y,4)
	var n2: float = _fbm(seed + 771,x * 1.9,y * 1.9,3)
	match String(d["pattern"]):
		"brushed": return clampf(0.45*n + 0.55*(0.5+0.5*sin((u*scale*30.0+n2*2.0)*PI)),0.0,1.0)
		"painted":
			var speck: float = 0.18 if _hash2(seed+5,int(floor(x*5.0)),int(floor(y*5.0))) > 0.93 else 0.0
			return clampf(n*0.78+speck,0.0,1.0)
		"wood":
			var warp: float = _fbm(seed+44,x*0.45,y*0.45,3)
			return clampf(0.5+0.42*sin((u*scale*2.2+warp*3.8)*PI),0.0,1.0)
		"concrete": return clampf(0.23+n*0.55+_smoothstep(0.78,0.96,n2)*0.28,0.0,1.0)
		"asphalt": return clampf(0.18+n*0.50+_hash2(seed+17,int(floor(x*3.0)),int(floor(y*3.0)))*0.32,0.0,1.0)
		"granite": return clampf(0.20+0.42*n+0.24*_smoothstep(0.72,0.90,n2)+0.18*_smoothstep(0.92,0.985,_hash2(seed+33,int(floor(x*6.0)),int(floor(y*6.0)))),0.0,1.0)
		"plastic": return clampf(0.42+(n-0.5)*0.32+(n2-0.5)*0.12,0.0,1.0)
		_: return n

func _fbm(seed: int, x: float, y: float, octaves: int) -> float:
	var value: float = 0.0
	var amplitude: float = 0.5
	var frequency: float = 1.0
	var weight: float = 0.0
	for i in range(octaves):
		value += _noise2(seed + i * 1013,x * frequency,y * frequency) * amplitude
		weight += amplitude
		amplitude *= 0.5
		frequency *= 2.03
	return value / maxf(weight,0.0001)

func _noise2(seed: int, x: float, y: float) -> float:
	var x0: int = int(floor(x))
	var y0: int = int(floor(y))
	var tx: float = x - float(x0)
	var ty: float = y - float(y0)
	var sx: float = tx*tx*(3.0-2.0*tx)
	var sy: float = ty*ty*(3.0-2.0*ty)
	var a: float = _hash2(seed,x0,y0)
	var b: float = _hash2(seed,x0+1,y0)
	var c: float = _hash2(seed,x0,y0+1)
	var d: float = _hash2(seed,x0+1,y0+1)
	return lerpf(lerpf(a,b,sx),lerpf(c,d,sx),sy)

func _hash2(seed: int, x: int, y: int) -> float:
	var raw: float = sin(float(seed) * 37.719 + float(x) * 12.9898 + float(y) * 78.233) * 43758.5453
	return absf(raw - floor(raw))

func _smoothstep(a: float, b: float, value: float) -> float:
	var t: float = clampf((value-a)/maxf(b-a,0.000001),0.0,1.0)
	return t*t*(3.0-2.0*t)

func _fract(v: float) -> float:
	return v - floor(v)

func _box_world(node_name: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
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

func _cylinder_local(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, material: Material, segments: int, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
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
	instance.rotation_degrees = rot
	parent.add_child(instance)
	return instance

func _label_world(text: String, pos: Vector3, rot: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.modulate = color
	label.outline_size = 5
	label.position = pos
	label.rotation_degrees = rot
	root.add_child(label)

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
