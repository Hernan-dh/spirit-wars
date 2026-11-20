extends RefCounted
## Shared state and primitive geometry for the courtyard authoring tool.
## Every module builds into one context, so authored placements keep one RNG
## sequence and reuse the same palette and packed prop scenes.

const StaticGeometry = preload("res://tools/static_geometry.gd")
const GeneratedResources = preload("res://tools/generated_resources.gd")

var rng := RandomNumberGenerator.new()
var palette: Dictionary = {}
var prop_scenes: Dictionary = {}
var rock_geometry: SphereMesh
var fern_geometry: Mesh
var two_sided_materials: Dictionary = {}

func material(key: String, color: String, emission := 0.0, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = key
	m.albedo_color = Color(color)
	m.roughness = 0.84
	m.metallic = metallic
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = emission
	palette[key] = m
	return m

func node(parent: Node, title: String, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = title
	n.position = pos
	parent.add_child(n)
	return n

func mesh(parent: Node, title: String, geometry: Mesh, mat: String, pos := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	n.mesh = geometry
	n.material_override = palette[mat]
	n.position = pos
	parent.add_child(n)
	return n

func box(parent: Node, title: String, pos: Vector3, size: Vector3, mat: String) -> MeshInstance3D:
	var g := BoxMesh.new()
	g.size = size
	return mesh(parent, title, g, mat, pos)

func cylinder(parent: Node, title: String, pos: Vector3, bottom: float, top: float, height: float, mat: String, sides := 8) -> MeshInstance3D:
	var g := CylinderMesh.new()
	g.bottom_radius = bottom
	g.top_radius = top
	g.height = height
	g.radial_segments = sides
	g.rings = 1
	return mesh(parent, title, g, mat, pos)

func rock(parent: Node, title: String, pos: Vector3, size: Vector3, mat: String) -> MeshInstance3D:
	if rock_geometry == null:
		rock_geometry = SphereMesh.new()
		rock_geometry.radius = 1.0
		rock_geometry.height = 2.0
		rock_geometry.radial_segments = 7
		rock_geometry.rings = 3
	var n := mesh(parent, title, rock_geometry, mat, pos)
	# Bake these nonuniform scales into merged surfaces for correct Compatibility normals.
	n.scale = size
	n.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.15, 0.15))
	return n

func rod(parent: Node, title: String, a: Vector3, b: Vector3, radius: float, mat: String, top := -1.0) -> MeshInstance3D:
	var n := cylinder(parent, title, (a + b) * 0.5, radius, radius if top < 0 else top, a.distance_to(b), mat, 6)
	var direction := (b - a).normalized()
	n.quaternion = Quaternion(Vector3.UP, direction)
	return n

func line(parent: Node, title: String, points: Array, radius: float, mat: String) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		if a.is_equal_approx(b):
			continue
		var segment := CylinderMesh.new()
		segment.bottom_radius = radius
		segment.top_radius = radius
		segment.height = a.distance_to(b)
		segment.radial_segments = 6
		segment.rings = 1
		var transform := Transform3D(Basis(Quaternion(Vector3.UP, (b - a).normalized())), (a + b) * 0.5)
		StaticGeometry.append_surface(st, segment, 0, transform)
	st.index()
	return mesh(parent, title, st.commit(), mat)

func circle(parent: Node, title: String, center: Vector3, radius: float, mat: String, thickness := 0.018, vertical := false, count := 48) -> void:
	var points: Array = []
	for i in range(count + 1):
		var a := float(i) / count * TAU
		points.append(center + (Vector3(cos(a), sin(a), 0) if vertical else Vector3(cos(a), 0, sin(a))) * radius)
	line(parent, title, points, thickness, mat)

func surface(parent: Node, title: String, triangles: Array, mat: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, triangles.size(), 3):
		# Godot uses clockwise front faces. Input triangles use outward cross products.
		st.add_vertex(triangles[i])
		st.add_vertex(triangles[i + 2])
		st.add_vertex(triangles[i + 1])
	st.generate_normals()
	return mesh(parent, title, st.commit(), mat)

func tri(out: Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	out.append_array([a, b, c])

func disk(parent: Node, title: String, radius: float, height: float, mat: String, count := 6) -> void:
	var faces: Array = []
	for i in range(count):
		var a := TAU * i / count + PI / 6.0
		var b := TAU * (i + 1) / count + PI / 6.0
		tri(faces, Vector3(0, height, 0), Vector3(cos(b)*radius, height, sin(b)*radius), Vector3(cos(a)*radius, height, sin(a)*radius))
	surface(parent, title, faces, mat)

func roof(parent: Node, title: String, pos: Vector3, radius: float, height: float) -> Node3D:
	var n := node(parent, title, pos)
	var rings: Array = []
	for level in range(3):
		var pts: Array = []
		var scale_factor: float = [1.0, 0.62, 0.12][level]
		for i in range(8):
			var a := PI/4 + i * TAU/8
			var r := radius * scale_factor * (1.4142 if i % 2 == 0 else 1.0)
			var y: float = [0.18 if i % 2 == 0 else 0.0, height * 0.38, height][level]
			pts.append(Vector3(cos(a)*r, y, sin(a)*r))
		rings.append(pts)
	var faces: Array = []
	for k in range(2):
		for i in range(8):
			var j := (i + 1) % 8
			tri(faces, rings[k][i], rings[k + 1][i], rings[k][j])
			tri(faces, rings[k][j], rings[k + 1][i], rings[k + 1][j])
	surface(n, "SweptTileRoof", faces, "Roof")
	var tile_faces: Array = []
	for side in range(8):
		var next := (side+1)%8
		var count := maxi(3,int(radius*7))
		for course in range(6):
			var t0 := course/6.0
			var t1 := (course+1)/6.0-.025
			for column in range(count):
				var u0 := column/float(count)
				var u1 := (column+1)/float(count)-.018
				var a := roof_point(rings,side,next,u0,t0)
				var b := roof_point(rings,side,next,u1,t0)
				var c := roof_point(rings,side,next,u0,t1)
				var d := roof_point(rings,side,next,u1,t1)
				var ridge0 := (a+b)*.5+Vector3.UP*.035
				var ridge1 := (c+d)*.5+Vector3.UP*.035
				tri(tile_faces,a,c,ridge0)
				tri(tile_faces,c,ridge1,ridge0)
				tri(tile_faces,ridge0,ridge1,b)
				tri(tile_faces,ridge1,d,b)
	var tiles := surface(n,"OverlappingCeramicTiles",tile_faces,"Roof")
	# Roof faces include both windings at swept corners.
	tiles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED

	for i in range(8):
		rod(n, "GildedEave%d" % i, rings[0][i], rings[0][(i+1)%8], 0.025, "Gold")
		line(n, "RoofRib%d" % i, [rings[0][i], rings[1][i], rings[2][i]], 0.018, "Jade")
	cylinder(n, "Finial", Vector3(0,height + 0.12,0), .12, .0, .35, "Gold")
	return n

func roof_point(rings: Array, side: int, next: int, u: float, t: float) -> Vector3:
	var eave: Vector3 = rings[0][side].lerp(rings[0][next],u)
	var middle: Vector3 = rings[1][side].lerp(rings[1][next],u)
	var peak: Vector3 = rings[2][side].lerp(rings[2][next],u)
	return (eave.lerp(middle,t/.62) if t<.62 else middle.lerp(peak,(t-.62)/.38)) + Vector3.UP*.012

func own_recursive(n: Node, root: Node) -> void:
	for child in n.get_children():
		if child.owner == null:
			child.owner = root
		own_recursive(child, root)

func save_scene(root: Node, path: String) -> PackedScene:
	if path.begins_with("res://scenes/props/"):
		StaticGeometry.merge_prop(root)
	GeneratedResources.externalize(root, path)
	own_recursive(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	var result := ResourceSaver.save(packed, path, ResourceSaver.FLAG_CHANGE_PATH)
	assert(result == OK, "Could not save " + path)
	root.free()
	return load(path) as PackedScene

func place(parent: Node, key: String, title: String, pos: Vector3, yaw := 0.0, size := 1.0) -> Node3D:
	var n: Node3D = prop_scenes[key].instantiate()
	n.name = title
	n.position = pos
	n.rotation.y = yaw
	n.scale *= size
	parent.add_child(n)
	# Light-bearing lanterns and the gate remain individually editable scene instances.
	if key in ["tree", "bamboo", "lotus"]:
		n.set_meta("batch_scenery", true)
	return n

func two_sided(source: StandardMaterial3D) -> StandardMaterial3D:
	if not two_sided_materials.has(source):
		var result := source.duplicate() as StandardMaterial3D
		result.resource_name = source.resource_name + " double sided"
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
		two_sided_materials[source] = result
	return two_sided_materials[source]
