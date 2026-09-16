extends Node3D

var game: Node = null
var shelf_id := -1
var target := Vector3.ZERO
var state := "idle"
var wait_time := 0.0
var speed := 1.75
var pending_purchase: Dictionary = {}
var clothing_color := Color(0.2, 0.5, 0.75)
var accent_color := Color(0.8, 0.7, 0.4)
var phase := 0.0
var visual_root: Node3D

func _ready() -> void:
	_build_visual()

func begin(game_ref: Node, chosen_shelf: int, spawn_position: Vector3, entrance_position: Vector3) -> void:
	game = game_ref
	shelf_id = chosen_shelf
	global_position = spawn_position
	phase = randf() * TAU
	state = "enter"
	target = entrance_position

func _process(delta: float) -> void:
	if game == null:
		return
	if visual_root:
		visual_root.position.y = sin(Time.get_ticks_msec() * 0.007 + phase) * 0.018
	if wait_time > 0.0:
		wait_time -= delta
		if wait_time <= 0.0:
			_finish_wait()
		return
	var delta_pos := target - global_position
	delta_pos.y = 0.0
	var distance := delta_pos.length()
	if distance <= 0.08:
		_arrived()
		return
	var direction: Vector3 = delta_pos / maxf(distance, 0.001)
	global_position += direction * min(speed * delta, distance)
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _arrived() -> void:
	match state:
		"enter":
			state = "browse"
			target = game.get_shelf_browse_position(shelf_id)
		"browse":
			state = "browse_wait"
			wait_time = 0.75 + randf() * 1.15
		"counter":
			state = "counter_wait"
			wait_time = 0.55 + randf() * 0.65
		"exit":
			game.customer_finished(self)

func _finish_wait() -> void:
	match state:
		"browse_wait":
			pending_purchase = game.customer_attempt_purchase(self, shelf_id)
			if pending_purchase.is_empty():
				state = "exit"
				target = game.get_exit_position()
			else:
				_show_bag(pending_purchase.get("color", Color.WHITE))
				state = "counter"
				target = game.get_counter_customer_position()
		"counter_wait":
			game.customer_checkout(self, pending_purchase)
			state = "exit"
			target = game.get_exit_position()

func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	var skin := _mat(Color(0.78 + randf() * 0.14, 0.58 + randf() * 0.20, 0.46 + randf() * 0.18), 0.8)
	var shirt := _mat(clothing_color, 0.72)
	var pants := _mat(accent_color.darkened(0.45), 0.78)
	var shoes := _mat(Color(0.06, 0.07, 0.075), 0.62)
	_add_capsule(visual_root, "Torso", Vector3(0, 1.12, 0), 0.29, 0.76, shirt)
	_add_sphere(visual_root, "Head", Vector3(0, 1.78, 0), 0.24, skin)
	_add_capsule(visual_root, "LegL", Vector3(-0.14, 0.47, 0), 0.075, 0.73, pants)
	_add_capsule(visual_root, "LegR", Vector3(0.14, 0.47, 0), 0.075, 0.73, pants)
	_add_capsule(visual_root, "ArmL", Vector3(-0.36, 1.12, 0), 0.06, 0.58, shirt)
	_add_capsule(visual_root, "ArmR", Vector3(0.36, 1.12, 0), 0.06, 0.58, shirt)
	_add_box(visual_root, "ShoeL", Vector3(-0.14, 0.08, -0.04), Vector3(0.18, 0.12, 0.34), shoes)
	_add_box(visual_root, "ShoeR", Vector3(0.14, 0.08, -0.04), Vector3(0.18, 0.12, 0.34), shoes)

func _show_bag(color: Color) -> void:
	if visual_root == null:
		return
	var bag_mat := _mat(color.lightened(0.25), 0.78)
	_add_box(visual_root, "ShoppingBag", Vector3(0.36, 0.78, -0.16), Vector3(0.25, 0.34, 0.18), bag_mat)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _add_sphere(parent: Node3D, node_name: String, pos: Vector3, radius: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)

func _add_capsule(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)

func _add_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	parent.add_child(instance)
