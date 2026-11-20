extends RefCounted

const MESH_DIR := "res://scenes/generated/meshes"
const MATERIAL_DIR := "res://materials/generated"

static var _resource_paths: Dictionary = {}
static var _used_paths: Dictionary = {}

static func reset() -> void:
	_resource_paths.clear()
	_used_paths.clear()

static func externalize(root: Node, scene_path: String) -> void:
	_ensure_dir(MESH_DIR)
	_ensure_dir(MATERIAL_DIR)
	var scene_base := scene_path.get_file().get_basename().to_snake_case()
	_visit(root, root, scene_base)

static func _ensure_dir(path: String) -> void:
	var error := DirAccess.make_dir_recursive_absolute(path)
	assert(error == OK or error == ERR_ALREADY_EXISTS, "Could not create " + path)

static func _visit(node: Node, root: Node, scene_base: String) -> void:
	if node != root and not node.scene_file_path.is_empty():
		return
	var node_path := _node_path(node, root)
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		_externalize_material(instance.material_override, scene_base + "_" + node_path + "_material")
		_externalize_material(instance.material_overlay, scene_base + "_" + node_path + "_overlay")
		_externalize_mesh(instance.mesh, scene_base + "_" + node_path)
	elif node is MultiMeshInstance3D:
		var batch := node as MultiMeshInstance3D
		_externalize_material(batch.material_override, scene_base + "_" + node_path + "_material")
		_externalize_material(batch.material_overlay, scene_base + "_" + node_path + "_overlay")
		if batch.multimesh != null:
			_externalize_mesh(batch.multimesh.mesh, scene_base + "_" + node_path)
	for child in node.get_children():
		_visit(child, root, scene_base)

static func _node_path(node: Node, root: Node) -> String:
	if node == root:
		return "root"
	var parts: Array[String] = []
	var current := node
	while current != null and current != root:
		parts.push_front(current.name)
		current = current.get_parent()
	return "/".join(parts).to_snake_case()

static func _externalize_mesh(mesh: Mesh, fallback_name: String) -> void:
	if mesh == null:
		return
	if _resource_paths.has(mesh):
		mesh.resource_path = _resource_paths[mesh]
		return
	if not mesh.resource_path.is_empty():
		_resource_paths[mesh] = mesh.resource_path
		_used_paths[mesh.resource_path] = mesh
		return
	var base := _resource_base("", fallback_name)
	var path := _unique_path(MESH_DIR, base, ".res", mesh)
	mesh.resource_path = path
	var error := ResourceSaver.save(mesh, path, ResourceSaver.FLAG_CHANGE_PATH)
	assert(error == OK, "Could not save mesh " + path)
	_resource_paths[mesh] = path
	_used_paths[path] = mesh

static func _externalize_material(material: Material, fallback_name: String) -> void:
	if material == null:
		return
	if _resource_paths.has(material):
		material.resource_path = _resource_paths[material]
		return
	if not material.resource_path.is_empty():
		_resource_paths[material] = material.resource_path
		_used_paths[material.resource_path] = material
		return
	var base := _resource_base(material.resource_name, fallback_name)
	var path := _unique_path(MATERIAL_DIR, base, ".tres", material)
	material.resource_path = path
	var error := ResourceSaver.save(material, path, ResourceSaver.FLAG_CHANGE_PATH)
	assert(error == OK, "Could not save material " + path)
	_resource_paths[material] = path
	_used_paths[path] = material

static func _resource_base(resource_name: String, fallback_name: String) -> String:
	var base := resource_name.to_snake_case() if not resource_name.is_empty() else fallback_name.to_snake_case()
	base = base.validate_filename()
	if base.is_empty():
		base = "resource"
	return base

static func _unique_path(directory: String, base: String, extension: String, resource: Resource) -> String:
	var candidate := directory.path_join(base + extension)
	var suffix := 2
	while _used_paths.has(candidate) and _used_paths[candidate] != resource:
		candidate = directory.path_join("%s_%d%s" % [base, suffix, extension])
		suffix += 1
	return candidate
