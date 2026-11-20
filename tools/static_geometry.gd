extends RefCounted
## Authoring-only batching. Saved scenes need no runtime conversion.
## Only generated static geometry is passed here; gameplay nodes are kept separate.

const CHUNK_SIZE := 8.0

static func append_surface(out: SurfaceTool, source: Mesh, surface: int, transform: Transform3D) -> void:
	var arrays := source.surface_get_arrays(surface)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var normal_basis := transform.basis.inverse().transposed()
	# Emit a consistent vertex format even when mixing primitives and authored surfaces.
	# Inverse transpose preserves lighting on scaled rocks and flattened roofs.
	for i in range(indices.size() if not indices.is_empty() else vertices.size()):
		var index := indices[i] if not indices.is_empty() else i
		out.set_normal((normal_basis * normals[index]).normalized())
		out.set_uv(uvs[index] if not uvs.is_empty() else Vector2.ZERO)
		out.set_color(colors[index] if not colors.is_empty() else Color.WHITE)
		out.add_vertex(transform * vertices[index])

static func collect_meshes(parent: Node3D, transform: Transform3D, output: Array) -> void:
	for child in parent.get_children():
		if not child is Node3D or not child.scene_file_path.is_empty() or child.get_script() != null:
			continue
		var local: Transform3D = transform * child.transform
		if child is MeshInstance3D:
			output.append({"node": child, "transform": local})
		else:
			collect_meshes(child, local, output)

static func merge_meshes(parent: Node3D, entries: Array, spatial: bool) -> void:
	var groups := {}
	for entry in entries:
		var source: MeshInstance3D = entry.node
		assert(source.mesh.get_surface_count() == 1)
		var mat := source.get_active_material(0)
		var cell := chunk(entry.transform.origin) if spatial else Vector2i.ZERO
		var key := [mat, source.cast_shadow, source.layers, cell]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(entry)
	for key in groups:
		var parts: Array = groups[key]
		if parts.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in parts:
			append_surface(st, part.node.mesh, 0, part.transform)
		st.index()
		var combined := MeshInstance3D.new()
		var material_name: String = key[0].resource_name if key[0] != null else "Material"
		combined.name = "Combined_%s_%d_%d_%d_%d" % [material_name.validate_node_name(), key[1], key[2], key[3].x, key[3].y]
		combined.mesh = st.commit()
		combined.mesh.resource_name = combined.name
		combined.material_override = key[0]
		combined.cast_shadow = key[1]
		combined.layers = key[2]
		parent.add_child(combined)
		for part in parts:
			part.node.free()

static func merge_prop(root: Node3D) -> void:
	var entries: Array = []
	collect_meshes(root, Transform3D.IDENTITY, entries)
	merge_meshes(root, entries, false)
	prune_empty(root)

static func prune_empty(parent: Node3D) -> void:
	for child in parent.get_children():
		if child.get_class() == "Node3D":
			prune_empty(child)
			if child.get_child_count() == 0:
				child.free()

static func chunk(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / CHUNK_SIZE), floori(position.z / CHUNK_SIZE))

static func batch_scenery(parent: Node3D) -> void:
	var groups := {}
	var sources: Array[Node3D] = []
	for child in parent.get_children():
		if not child.has_meta("batch_scenery"):
			continue
		sources.append(child)
		var entries: Array = []
		if child is MeshInstance3D:
			entries.append({"node": child, "transform": child.transform})
		else:
			collect_meshes(child, child.transform, entries)
		for entry in entries:
			var source: MeshInstance3D = entry.node
			var key := [source.mesh, source.get_active_material(0), source.cast_shadow, source.layers, chunk(child.position)]
			if not groups.has(key):
				groups[key] = []
			entry["source_name"] = child.name
			groups[key].append(entry)
	for key in groups:
		var entries: Array = groups[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = key[0]
		multimesh.instance_count = entries.size()
		var names := PackedStringArray()
		for i in range(entries.size()):
			multimesh.set_instance_transform(i, entries[i].transform)
			names.append(entries[i].source_name)
		var batch := MultiMeshInstance3D.new()
		batch.name = "Scenery_%s_%d" % [entries[0].source_name, parent.get_child_count()]
		batch.multimesh = multimesh
		batch.material_override = key[1]
		batch.cast_shadow = key[2]
		batch.layers = key[3]
		batch.set_meta("instance_names", names)
		parent.add_child(batch)
	for source in sources:
		source.free()

static func optimize_details(parent: Node3D) -> void:
	# Packed props are already merged; batching markers identify decoration only.
	for child in parent.get_children():
		if child is Node3D and not child is GeometryInstance3D and child.scene_file_path.is_empty() and child.get_script() == null and not child.has_meta("batch_scenery"):
			optimize_details(child)
	batch_scenery(parent)
	var entries: Array = []
	for child in parent.get_children():
		if child is MeshInstance3D:
			entries.append({"node": child, "transform": child.transform})
	merge_meshes(parent, entries, true)
