extends SceneTree
## Builds the small saved silhouette used by Mirage Rush.
## godot --headless --path . --script tools/build_kitsune_echo.gd

const OUTPUT := "res://generated/meshes/kitsune_mirage_echo.res"

func _initialize() -> void:
	var mesh := _build_mesh()
	mesh.resource_name = "kitsune_mirage_echo"
	var error := ResourceSaver.save(mesh, OUTPUT, ResourceSaver.FLAG_CHANGE_PATH)
	print("Saved kitsune echo mesh: %d" % error)
	quit(0 if error == OK else 1)

func _build_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := SphereMesh.new()
	body.radius = .26
	body.height = .62
	body.radial_segments = 8
	body.rings = 5
	surface.append_from(body, 0, _part_transform(Vector3(0,.35,.04), Vector3(1,1,.8)))
	var head := SphereMesh.new()
	head.radius = .19
	head.height = .40
	head.radial_segments = 8
	head.rings = 4
	surface.append_from(head, 0, _part_transform(Vector3(0,.65,-.22)))
	var snout := SphereMesh.new()
	snout.radius = .10
	snout.height = .22
	snout.radial_segments = 6
	snout.rings = 3
	surface.append_from(snout, 0, _part_transform(Vector3(0,.61,-.41), Vector3(1.2,.8,1.5)))
	for side in [-1, 1]:
		surface.append_from(_cone(.075, .24), 0, _part_transform(Vector3(side*.12,.84,-.18), Vector3.ONE, Vector3(0,0,side*.12)))
		for z in [-.18, .18]:
			surface.append_from(_tube(.04, .28), 0, _part_transform(Vector3(side*.12,.14,z)))
	for tail_index in 3:
		surface.append_from(
			_cone(.065, .62),
			0,
			_part_transform(Vector3((tail_index - 1) * .17,.36,.42), Vector3.ONE, Vector3(1.15,0,0))
		)
	surface.generate_normals()
	return surface.commit()

func _cone(bottom_radius: float, height: float) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.bottom_radius = bottom_radius
	cone.top_radius = 0.0
	cone.height = height
	cone.radial_segments = 6
	cone.rings = 1
	return cone

func _tube(radius: float, height: float) -> CylinderMesh:
	var tube := CylinderMesh.new()
	tube.bottom_radius = radius
	tube.top_radius = radius
	tube.height = height
	tube.radial_segments = 5
	tube.rings = 1
	return tube

func _part_transform(origin: Vector3, scale := Vector3.ONE, rotation := Vector3.ZERO) -> Transform3D:
	var basis := Basis.from_scale(scale)
	basis = basis.rotated(Vector3.RIGHT, rotation.x).rotated(Vector3.UP, rotation.y).rotated(Vector3.FORWARD, rotation.z)
	return Transform3D(basis, origin)
