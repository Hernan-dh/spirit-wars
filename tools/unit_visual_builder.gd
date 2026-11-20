extends SceneTree
## Shared helpers for authoring native-mesh unit visuals as editable scenes.
## Build scripts create geometry into one visual root, then save it with external
## resources next to the reusable scene.

const GeneratedResources = preload("res://tools/generated_resources.gd")

var visual: Node3D
var material_roughness := 0.5

func begin_visual(title: String) -> void:
	GeneratedResources.reset()
	visual = Node3D.new()
	visual.name = title

func material(color: String, emission := 0.0, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = material_roughness
	m.metallic = metallic
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = emission
	return m

func node(parent: Node, label: String, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = label
	parent.add_child(n)
	n.owner = visual
	n.position = pos
	return n

func mesh(parent: Node3D, label: String, geometry: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = geometry
	n.material_override = mat
	parent.add_child(n)
	n.owner = visual
	n.position = pos
	return n

func save_visual(path: String) -> void:
	GeneratedResources.externalize(visual, path)
	var packed := PackedScene.new()
	var error := packed.pack(visual)
	if error == OK:
		error = ResourceSaver.save(packed, path)
	if error == OK:
		GeneratedResources.cleanup_scene(path)
	visual.free()
	quit(error)
