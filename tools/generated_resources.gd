extends RefCounted

const MESH_DIR := "res://scenes/generated/meshes"
const MATERIAL_DIR := "res://materials/generated"

static var _resource_paths: Dictionary = {}
static var _used_paths: Dictionary = {}
static var _content_paths: Dictionary = {}

static func reset() -> void:
	_resource_paths.clear()
	_used_paths.clear()
	_content_paths.clear()

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
		instance.material_override = _externalize_material(instance.material_override, scene_base + "_" + node_path + "_material")
		instance.material_overlay = _externalize_material(instance.material_overlay, scene_base + "_" + node_path + "_overlay")
		instance.mesh = _externalize_mesh(instance.mesh, scene_base + "_" + node_path)
	elif node is MultiMeshInstance3D:
		var batch := node as MultiMeshInstance3D
		batch.material_override = _externalize_material(batch.material_override, scene_base + "_" + node_path + "_material")
		batch.material_overlay = _externalize_material(batch.material_overlay, scene_base + "_" + node_path + "_overlay")
		if batch.multimesh != null:
			batch.multimesh.mesh = _externalize_mesh(batch.multimesh.mesh, scene_base + "_" + node_path)
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

static func _externalize_mesh(mesh: Mesh, fallback_name: String) -> Mesh:
	if mesh == null:
		return null
	if _resource_paths.has(mesh):
		return _resource_paths[mesh]
	if not mesh.resource_path.is_empty():
		_resource_paths[mesh] = mesh
		_used_paths[mesh.resource_path] = mesh
		return mesh
	var content_key := "mesh:" + _mesh_signature(mesh)
	if _content_paths.has(content_key):
		var shared: Mesh = _used_paths[_content_paths[content_key]]
		_resource_paths[mesh] = shared
		return shared
	var base := _resource_base("", fallback_name)
	var path := _unique_path(MESH_DIR, base, ".res", mesh)
	mesh.resource_path = path
	var error := ResourceSaver.save(mesh, path, ResourceSaver.FLAG_CHANGE_PATH)
	assert(error == OK, "Could not save mesh " + path)
	_resource_paths[mesh] = mesh
	_used_paths[path] = mesh
	_content_paths[content_key] = path
	return mesh

static func _externalize_material(material: Material, fallback_name: String) -> Material:
	if material == null:
		return null
	if _resource_paths.has(material):
		return _resource_paths[material]
	if not material.resource_path.is_empty():
		_resource_paths[material] = material
		_used_paths[material.resource_path] = material
		return material
	var content_key := "material:" + _material_signature(material)
	if _content_paths.has(content_key):
		var shared: Material = _used_paths[_content_paths[content_key]]
		_resource_paths[material] = shared
		return shared
	var base := _resource_base(material.resource_name, fallback_name)
	var path := _unique_path(MATERIAL_DIR, base, ".tres", material)
	material.resource_path = path
	var error := ResourceSaver.save(material, path, ResourceSaver.FLAG_CHANGE_PATH)
	assert(error == OK, "Could not save material " + path)
	_resource_paths[material] = material
	_used_paths[path] = material
	_content_paths[content_key] = path
	return material

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

static func _mesh_signature(mesh: Mesh) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(mesh.get_class()))
	var surfaces := mesh.get_surface_count()
	ctx.update(var_to_bytes(surfaces))
	for surface in surfaces:
		if mesh is ArrayMesh:
			var array_mesh := mesh as ArrayMesh
			ctx.update(var_to_bytes(array_mesh.surface_get_primitive_type(surface)))
			ctx.update(var_to_bytes(array_mesh.surface_get_name(surface)))
			ctx.update(var_to_bytes(array_mesh.surface_get_blend_shape_arrays(surface)))
		ctx.update(var_to_bytes(mesh.surface_get_arrays(surface)))
		var material := mesh.surface_get_material(surface)
		ctx.update(var_to_bytes(_material_signature(material) if material != null else "none"))
	return ctx.finish().hex_encode()

static func _material_signature(material: Material) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(material.get_class()))
	for property in material.get_property_list():
		if not (property.usage & PROPERTY_USAGE_STORAGE):
			continue
		if property.name in ["resource_path", "resource_name", "resource_scene_unique_id", "script"]:
			continue
		_update_signature_value(ctx, property.name, material.get(property.name))
	return ctx.finish().hex_encode()

static func _update_signature_value(ctx: HashingContext, property_name: String, value: Variant) -> void:
	ctx.update(property_name.to_utf8_buffer())
	if value == null:
		ctx.update(var_to_bytes("null"))
	elif value is Resource:
		var resource := value as Resource
		ctx.update(var_to_bytes(resource.resource_path if not resource.resource_path.is_empty() else resource.get_class()))
	elif value is Object:
		ctx.update(var_to_bytes((value as Object).get_class()))
	else:
		ctx.update(var_to_bytes(value))

static func cleanup_scene(scene_path: String) -> void:
	var scene_base := scene_path.get_file().get_basename().to_snake_case()
	_cleanup_directory(MESH_DIR, scene_base)
	_cleanup_directory(MATERIAL_DIR, scene_base)

static func _cleanup_directory(directory: String, scene_base: String) -> void:
	var stale: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if not dir.current_is_dir():
			var stem := entry.get_basename()
			var path := directory.path_join(entry)
			if (stem == scene_base or stem.begins_with(scene_base + "_")) and not _used_paths.has(path):
				stale.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	for stale_entry in stale:
		var error := dir.remove(stale_entry)
		assert(error == OK, "Could not remove stale generated resource " + directory.path_join(stale_entry))
