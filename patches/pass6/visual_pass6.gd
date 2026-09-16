extends Node

var root: Node3D
var atlas_base: Texture2D
var atlas_normal: Texture2D
var atlas_rough: Texture2D
var atlas_metal: Texture2D

const NATIVE_SHADER := """
shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D base_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D rough_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D metal_tex : filter_linear_mipmap, repeat_disable;
uniform float atlas_slot = 0.0;
uniform float tiles = 1.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform float normal_strength = 0.82;
uniform float roughness_bias = 0.0;
uniform float metallic_scale = 1.0;

void fragment() {
    vec2 local_uv = fract(UV * max(tiles, 1.0));
    local_uv = clamp(local_uv, vec2(0.02), vec2(0.98));
    float third = 1.0 / 3.0;
    vec2 uv = vec2((local_uv.x + atlas_slot) * third, local_uv.y);
    vec4 base = texture(base_tex, uv);
    ALBEDO = base.rgb * tint;
    ROUGHNESS = clamp(texture(rough_tex, uv).r + roughness_bias, 0.02, 1.0);
    METALLIC = clamp(texture(metal_tex, uv).r * metallic_scale, 0.0, 1.0);
    NORMAL_MAP = texture(normal_tex, uv).rgb;
    NORMAL_MAP_DEPTH = normal_strength;
}
"""

func _ready() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    root = get_parent() as Node3D
    if root == null:
        return
    atlas_base = load("res://assets/axm_native_materials/material-atlas_basecolor.png") as Texture2D
    atlas_normal = load("res://assets/axm_native_materials/material-atlas_normal.png") as Texture2D
    atlas_rough = load("res://assets/axm_native_materials/material-atlas_roughness.png") as Texture2D
    atlas_metal = load("res://assets/axm_native_materials/material-atlas_metallic.png") as Texture2D
    if atlas_base == null or atlas_normal == null or atlas_rough == null or atlas_metal == null:
        push_error("Pass 6 native material atlas failed to load")
        return
    _apply_native_sets()
    _add_native_detail_pass()

func _apply_native_sets() -> void:
    var dark_frame := _native_material(0.0, 1.4, Color(0.78,0.84,0.88), 0.92, -0.04, 1.0)
    var aged_ivory := _native_material(1.0, 1.2, Color(1.0,0.96,0.86), 0.72, 0.06, 0.22)
    var pale_ceramic := _native_material(2.0, 1.0, Color(0.96,0.98,1.0), 0.76, 0.03, 0.16)
    var meshes: Array[MeshInstance3D] = []
    _collect_meshes(root, meshes)
    for mesh in meshes:
        var n: String = String(mesh.name)
        match n:
            "P4Canopy", "P4CanopyFascia", "FrontHeaderVisual", "P4Pump2", "FridgeBody", "Back":
                mesh.material_override = dark_frame
            "ShelfBoard", "CounterBase", "StandBase", "P4WallInset", "CrateBody", "CrateTop":
                mesh.material_override = aged_ivory
            "P4Tile", "CounterTop", "P4WallPanel", "WallBackVisual":
                mesh.material_override = pale_ceramic

func _add_native_detail_pass() -> void:
    var dark_frame := _native_material(0.0, 1.0, Color(0.70,0.79,0.84), 0.92, -0.05, 1.0)
    var aged_ivory := _native_material(1.0, 1.0, Color(1.0,0.93,0.78), 0.70, 0.07, 0.18)
    var pale_ceramic := _native_material(2.0, 1.0, Color(0.94,0.98,1.0), 0.72, 0.02, 0.12)

    # Manufacturer-style inserts break the box silhouette without replacing gameplay geometry.
    var shelves: Array[Node] = []
    _collect_named(root, "RetailShelf", shelves)
    for shelf_node in shelves:
        var shelf := shelf_node as Node3D
        _box_local(shelf,"P6ShelfHeader",Vector3(0,1.93,0.115),Vector3(1.34,0.16,0.055),dark_frame)
        _box_local(shelf,"P6ShelfKick",Vector3(0,0.105,0.18),Vector3(1.22,0.14,0.055),dark_frame)
        for y in [0.24,0.62,1.00,1.38,1.76]:
            _box_local(shelf,"P6ShelfFace",Vector3(0,y,-0.322),Vector3(1.17,0.055,0.025),aged_ivory)

    var counter := _find_first(root,"CheckoutCounter") as Node3D
    if counter:
        _box_local(counter,"P6CounterFront",Vector3(0,0.54,-0.505),Vector3(1.45,0.48,0.030),aged_ivory)
        _box_local(counter,"P6CounterPlinth",Vector3(0,0.12,-0.485),Vector3(1.70,0.10,0.045),dark_frame)

    # Storefront material accents are large enough for the native panel maps to read.
    _box_world("P6FrontFascia",Vector3(0,2.77,5.79),Vector3(6.6,0.30,0.055),dark_frame)
    _box_world("P6FrontCeramicBand",Vector3(0,0.74,5.765),Vector3(6.5,0.20,0.045),pale_ceramic)

    # Gas island gets the dark-frame set so the roadside identity reads through the glass.
    _box_world("P6FuelIslandSkin",Vector3(2.25,0.125,7.75),Vector3(4.0,0.10,1.02),pale_ceramic)
    _box_world("P6CanopyUnderside",Vector3(2.25,2.865,7.75),Vector3(4.12,0.055,2.15),aged_ivory)

func _native_material(slot: float, tiles: float, tint: Color, normal_strength: float, roughness_bias: float, metallic_scale: float) -> ShaderMaterial:
    var shader := Shader.new()
    shader.code = NATIVE_SHADER
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("base_tex", atlas_base)
    material.set_shader_parameter("normal_tex", atlas_normal)
    material.set_shader_parameter("rough_tex", atlas_rough)
    material.set_shader_parameter("metal_tex", atlas_metal)
    material.set_shader_parameter("atlas_slot", slot)
    material.set_shader_parameter("tiles", tiles)
    material.set_shader_parameter("tint", Vector3(tint.r,tint.g,tint.b))
    material.set_shader_parameter("normal_strength", normal_strength)
    material.set_shader_parameter("roughness_bias", roughness_bias)
    material.set_shader_parameter("metallic_scale", metallic_scale)
    return material

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
