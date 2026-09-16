extends Node

func _ready() -> void:
	for _i in range(9):
		await get_tree().process_frame
	var root := get_parent() as Node3D
	if root == null:
		return
	var player := root.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		return
	player.position = Vector3(1.65,0,-4.35)
	player.rotation_degrees = Vector3(0,200,0)
	var camera := player.get_node_or_null("Camera3D") as Camera3D
	if camera:
		camera.fov = 78.0
