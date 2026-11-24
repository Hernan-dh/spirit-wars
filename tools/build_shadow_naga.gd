extends "res://tools/unit_visual_builder.gd"
## Deterministic, editable native mesh authoring for the Shadow Naga.
## godot --headless --path . --script tools/build_shadow_naga.gd
const StaticGeometry = preload("res://tools/static_geometry.gd")

var scale_deep: StandardMaterial3D
var scale_mid: StandardMaterial3D
var scale_light: StandardMaterial3D
var scale_hi: StandardMaterial3D
var belly: StandardMaterial3D
var belly_shade: StandardMaterial3D
var gold: StandardMaterial3D
var gold_light: StandardMaterial3D
var mane: StandardMaterial3D
var mane_light: StandardMaterial3D
var fin_mat: StandardMaterial3D
var fin_hi: StandardMaterial3D
var eye: StandardMaterial3D
var pupil: StandardMaterial3D
var mouth: StandardMaterial3D
var tongue: StandardMaterial3D
var bloom_pink: StandardMaterial3D
var bloom_light: StandardMaterial3D
var bloom_deep: StandardMaterial3D
var stamen: StandardMaterial3D
var stone: StandardMaterial3D
var stone_light: StandardMaterial3D
var moss: StandardMaterial3D
var smoke: StandardMaterial3D
var smoke_deep: StandardMaterial3D
var glow: StandardMaterial3D
var _ribbon_materials: Dictionary = {}

func cull_disabled(source: StandardMaterial3D) -> StandardMaterial3D:
	var result := source.duplicate() as StandardMaterial3D
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result

func smoke_material(color: String, alpha: float, emission: float) -> StandardMaterial3D:
	var result := material(color, emission)
	result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	result.albedo_color.a = alpha
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	result.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return result

func oval(parent: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 18
	sphere.rings = 9
	var n := mesh(parent, label, sphere, mat)
	n.position = pos
	n.scale = size
	return n

func torus(parent: Node3D, label: String, pos: Vector3, radius: float, thickness: float, mat: Material) -> MeshInstance3D:
	var mesh_resource := TorusMesh.new()
	mesh_resource.inner_radius = radius - thickness * .5
	mesh_resource.outer_radius = radius + thickness * .5
	mesh_resource.rings = 32
	mesh_resource.ring_segments = 6
	var n := mesh(parent, label, mesh_resource, mat)
	n.position = pos
	return n

func lathe(parent: Node3D, label: String, profile: Array[Vector2], mat: Material, segments := 28) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for i in segments:
			var a := TAU * i / segments
			var b := TAU * (i + 1) / segments
			var p := profile[row]
			var q := profile[row + 1]
			var points := [Vector3(p.x * cos(a), p.y, p.x * sin(a)), Vector3(q.x * cos(a), q.y, q.x * sin(a)), Vector3(q.x * cos(b), q.y, q.x * sin(b)), Vector3(p.x * cos(b), p.y, p.x * sin(b))]
			for index in [0, 2, 1, 0, 3, 2]:
				st.add_vertex(points[index])
	st.generate_normals()
	return mesh(parent, label, st.commit(), mat)

func smooth_path(points: Array[Vector3], steps := 4) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for i in range(points.size() - 1):
		for j in steps:
			result.append(points[i].cubic_interpolate(points[i + 1], points[maxi(0, i - 1)], points[mini(points.size() - 1, i + 2)], float(j) / steps))
	result.append(points[-1])
	return result

func sweep(parent: Node3D, label: String, path: Array[Vector3], widths: Array[float], depths: Array[float], mat: Material, sides := 8) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in path.size():
		var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := Vector3.RIGHT.slide(tangent).normalized()
		if side.length_squared() < .01:
			side = Vector3.UP.slide(tangent).normalized()
		var up := tangent.cross(side).normalized()
		var ring := PackedVector3Array()
		for j in sides:
			var angle := TAU * j / sides
			ring.append(path[i] + side * cos(angle) * widths[i] + up * sin(angle) * depths[i])
		rings.append(ring)
	for i in range(path.size() - 1):
		for j in sides:
			var k := (j + 1) % sides
			for corner in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, k), Vector2i(i, j), Vector2i(i + 1, k), Vector2i(i, k)]:
				st.add_vertex(rings[corner.x][corner.y])
	for end in [0, path.size() - 1]:
		for j in sides:
			st.add_vertex(path[end])
			st.add_vertex(rings[end][j] if end == 0 else rings[end][(j + 1) % sides])
			st.add_vertex(rings[end][(j + 1) % sides] if end == 0 else rings[end][j])
	st.generate_normals()
	return mesh(parent, label, st.commit(), mat)

func strand(parent: Node3D, label: String, points: Array[Vector3], radius: float, mat: Material) -> MeshInstance3D:
	var path := smooth_path(points, 3)
	var widths: Array[float] = []
	for i in path.size():
		widths.append(maxf(.002, radius * (1.0 - .55 * float(i) / (path.size() - 1))))
	return sweep(parent, label, path, widths, widths, mat)

func tuft(parent: Node3D, label: String, points: Array[Vector3], width: float, mat: Material) -> void:
	var path := smooth_path(points, 4)
	var widths: Array[float] = []
	var depths: Array[float] = []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		widths.append(maxf(.002, width * (1.0 - t) * (.55 + sin(t * PI))))
		depths.append(widths[-1] * .48)
	sweep(parent, label, path, widths, depths, mat, 7)

func fin(parent: Node3D, label: String, a: Vector3, b: Vector3, tip: Vector3, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [a, b, tip]:
		st.add_vertex(point)
	st.generate_normals()
	mesh(parent, label, st.commit(), cull_disabled(mat))

func blade(parent: Node3D, label: String, base: Vector3, outward: Vector3, tip: Vector3, width: float, mat: Material) -> void:
	var side := outward.cross(tip - base).normalized() * width * .5
	fin(parent, label, base - side, base + side, tip, mat)

func petal(parent: Node3D, label: String, length: float, width: float, rise: float, mat: Material) -> MeshInstance3D:
	const ROWS := 8
	const COLS := 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for row in ROWS:
		var t := float(row) / (ROWS - 1)
		var half := width * pow(sin(t * PI), .58) * (1.0 - .18 * t) + .002
		var y := rise * (t * .72 + sin(t * PI) * .10)
		var z := length * t
		var ring := PackedVector3Array()
		for column in COLS:
			var u := float(column) / (COLS - 1) * 2.0 - 1.0
			var cup := (1.0 - absf(u)) * sin(t * PI) * .024
			ring.append(Vector3(u * half, y + cup, z))
		rings.append(ring)
	for row in range(ROWS - 1):
		for column in range(COLS - 1):
			var a := rings[row][column]
			var b := rings[row][column + 1]
			var c := rings[row + 1][column]
			var d := rings[row + 1][column + 1]
			for point in [a, c, b, b, c, d]:
				st.add_vertex(point)
	st.generate_normals()
	return mesh(parent, label, st.commit(), mat)

func small_lotus(parent: Node3D, label: String, flower_scale: float) -> Node3D:
	var flower := node(parent, label)
	oval(flower, "Heart", Vector3(0, .02, 0), Vector3(.045, .030, .045), stamen)
	var rings := [
		{"count": 6, "length": .21, "width": .070, "rise": .075, "offset": 0.0, "mat": bloom_pink},
		{"count": 5, "length": .16, "width": .058, "rise": .105, "offset": PI / 5.0, "mat": bloom_light},
	]
	for ring in rings:
		for i in int(ring["count"]):
			var p := petal(flower, "Petal%d" % i, float(ring["length"]), float(ring["width"]), float(ring["rise"]), ring["mat"])
			p.position = Vector3(0, .01, 0)
			p.rotation.y = TAU * i / float(ring["count"]) + float(ring["offset"])
	flower.scale = Vector3.ONE * flower_scale
	return flower

func plume(parent: Node3D, label: String, points: Array[Vector3], mat: Material) -> void:
	var path := smooth_path(points, 5)
	var widths: Array[float] = []
	var depths: Array[float] = []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		var width := .010 + .074 * sin(t * PI) * (1.0 - .28 * t)
		widths.append(width)
		depths.append(width * .82)
	sweep(parent, label, path, widths, depths, mat, 8)

func merge_children(parent: Node3D) -> void:
	var entries: Array = []
	StaticGeometry.collect_meshes(parent, Transform3D.IDENTITY, entries)
	StaticGeometry.merge_meshes(parent, entries, false)
	StaticGeometry.prune_empty(parent)

func own_tree(parent: Node) -> void:
	for child in parent.get_children():
		child.owner = visual
		own_tree(child)

func body_radius(t: float) -> float:
	var radius := lerpf(.028, .148, smoothstep(0.0, .20, t))
	radius *= 1.0 - .42 * smoothstep(.72, 1.0, t)
	return radius

func _initialize() -> void:
	material_roughness = .54
	begin_visual("ShadowNagaVisual")
	scale_deep = material("21143f", .02, .10)
	scale_mid = material("4c2679", .03, .12)
	scale_light = material("7a3fb2", .05, .08)
	scale_hi = material("b56df0", .16, .04)
	belly = material("efd8d0", .02)
	belly_shade = material("cfaba9", .01)
	gold = material("e9a83e", .12, .62)
	gold_light = material("ffd887", .28, .35)
	mane = material("2a1847", .03)
	mane_light = cull_disabled(material("8438c6", .22))
	fin_mat = cull_disabled(material("5b2b93", .10))
	fin_hi = cull_disabled(material("c070ff", .30))
	eye = material("ffd34d", .85)
	eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pupil = material("1a0b22", .02)
	mouth = material("3a0d1d", .01)
	tongue = material("d24a5e", .04)
	bloom_pink = cull_disabled(material("f069b6", .12))
	bloom_light = cull_disabled(material("ffc0e0", .16))
	bloom_deep = cull_disabled(material("c23d8b", .08))
	stamen = material("ffd66f", .38)
	stone = material("586765", .01)
	stone_light = material("6f7f6a", .02)
	moss = material("4f7a4a", .02)
	smoke = smoke_material("c58cff", .18, .55)
	smoke_deep = smoke_material("8f4fd6", .13, .30)
	glow = material("e6c6ff", .9)
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# --- Jungle-stone base with paving, moss, petals and a lotus ----------
	var base := node(visual, "StoneBase")
	lathe(base, "StonePlinth", [Vector2(.50, .00), Vector2(.545, .042), Vector2(.515, .088), Vector2(.40, .098)], cull_disabled(stone), 30)
	for i in 10:
		var angle := TAU * i / 10.0 + .12
		var tile := oval(base, "PavingStone%d" % i, Vector3(cos(angle) * .405, .083, sin(angle) * .405), Vector3(.125, .038, .085), stone_light if i % 2 == 0 else stone)
		tile.rotation.y = -angle
	for i in 7:
		var angle := .6 + TAU * i / 7.0
		var patch := oval(base, "Moss%d" % i, Vector3(cos(angle) * .455, .105, sin(angle) * .455), Vector3(.075, .018, .052), moss)
		patch.rotation.y = -angle
	for i in 9:
		var angle := .25 + TAU * i / 9.0
		var fallen := petal(base, "FallenPetal%d" % i, .13, .045, .006, bloom_light if i % 2 == 0 else bloom_pink)
		fallen.position = Vector3(cos(angle) * .31, .115, sin(angle) * .31)
		fallen.rotation.y = -angle + .4
		fallen.rotation.x = -.36
	var base_lotus := small_lotus(base, "BaseLotus", .95)
	base_lotus.position = Vector3(.285, .11, -.275)
	base_lotus.rotation.y = -.4
	merge_children(base)

	# --- Coiled serpent body, belly plates and dorsal ridge --------------
	var body := node(visual, "NagaBody")
	var body_points: Array[Vector3] = [
		Vector3(.36, .18, .40),
		Vector3(.54, .21, .12),
		Vector3(.46, .24, -.24),
		Vector3(.16, .27, -.44),
		Vector3(-.22, .30, -.40),
		Vector3(-.46, .34, -.12),
		Vector3(-.44, .39, .24),
		Vector3(-.18, .45, .42),
		Vector3(.18, .52, .38),
		Vector3(.36, .60, .12),
		Vector3(.30, .70, -.16),
		Vector3(.14, .82, -.24),
		Vector3(.04, .96, -.18),
		Vector3(.00, 1.10, -.08),
		Vector3(-.02, 1.24, -.02),
		Vector3(.00, 1.38, -.04),
	]
	var body_path := smooth_path(body_points, 5)
	var body_widths: Array[float] = []
	var body_depths: Array[float] = []
	for i in body_path.size():
		var t := float(i) / (body_path.size() - 1)
		var radius := body_radius(t)
		body_widths.append(radius)
		body_depths.append(radius * 1.03)
	sweep(body, "SerpentCoil", body_path, body_widths, body_depths, scale_mid, 12)
	# Overlapping violet scale plates gloss the upper coil.
	for i in range(5, body_path.size() - 34, 5):
		var t := float(i) / (body_path.size() - 1)
		var point := body_path[i]
		var tangent := (body_path[mini(i + 1, body_path.size() - 1)] - body_path[maxi(i - 1, 0)]).normalized()
		var radius := body_radius(t)
		var plate := oval(body, "CoilScale%d" % i, point + Vector3(0, radius * .64, 0), Vector3(radius * .78, radius * .20, radius * .56), scale_light if i % 10 == 0 else scale_deep)
		plate.rotation.y = atan2(tangent.x, tangent.z)
		plate.rotation.x = tangent.z * .35
	# Ivory segmented belly runs up the throat.
	for i in range(body_path.size()):
		var t := float(i) / (body_path.size() - 1)
		var point := body_path[i]
		var neck := point.y > .62
		if (neck and i % 3 == 0) or (not neck and point.z < -.16 and i % 4 == 0):
			var radius := body_radius(t)
			var tangent := (body_path[mini(i + 1, body_path.size() - 1)] - body_path[maxi(i - 1, 0)]).normalized()
			var length := radius * (2.0 if neck else 1.15)
			var plate := oval(body, "BellyPlate%d" % i, point + Vector3(0, radius * .04, -radius * .78), Vector3(radius * .68, radius * .14, length), belly if i % 2 == 0 else belly_shade)
			plate.rotation.y = atan2(tangent.x, tangent.z)
			plate.rotation.x = -.16
	# Gold scale hooks accent the outer coil.
	for i in range(14, body_path.size() - 50, 16):
		var point := body_path[i]
		var tangent := (body_path[mini(i + 1, body_path.size() - 1)] - body_path[maxi(i - 1, 0)]).normalized()
		var radius := body_radius(float(i) / (body_path.size() - 1))
		var hook := strand(body, "ScaleHook%d" % i, [point + Vector3(0, radius * .5, 0), point + Vector3(radius * .52, radius * .7, radius * .2), point + Vector3(radius * .82, radius * .55, radius * .5)], .007, gold)
		hook.rotation.y = atan2(tangent.x, tangent.z)
	# Dorsal ridge fins follow the upright neck.
	var ridge := [
		[Vector3(.20, .60, .18), Vector3(.25, .71, .33)],
		[Vector3(.27, .70, .02), Vector3(.34, .82, .17)],
		[Vector3(.22, .82, -.08), Vector3(.29, .94, .07)],
		[Vector3(.11, .93, -.12), Vector3(.17, 1.07, .03)],
		[Vector3(.04, 1.04, -.06), Vector3(.09, 1.18, .10)],
		[Vector3(.00, 1.16, .00), Vector3(.04, 1.30, .16)],
		[Vector3(-.01, 1.27, .02), Vector3(.02, 1.40, .17)],
	]
	for i in ridge.size():
		var pair: Array = ridge[i]
		blade(body, "DorsalFin%d" % i, pair[0] + Vector3(-.055, 0, 0), Vector3(1, 0, 0), pair[1], .085, fin_hi if i % 3 == 0 else fin_mat)
	merge_children(body)

	# --- Dragon head with horns, whiskers and glowing eyes ----------------
	var head := node(visual, "NagaHead", Vector3(0, 1.36, -.02))
	oval(head, "Skull", Vector3(0, .26, -.08), Vector3(.155, .135, .185), scale_mid)
	oval(head, "BrowCrown", Vector3(0, .335, -.02), Vector3(.118, .070, .125), scale_light)
	oval(head, "Snout", Vector3(0, .215, -.28), Vector3(.115, .075, .160), scale_deep)
	oval(head, "SnoutBridge", Vector3(0, .278, -.245), Vector3(.085, .042, .120), scale_light)
	oval(head, "NoseTip", Vector3(0, .205, -.395), Vector3(.074, .048, .070), scale_mid)
	oval(head, "LowerJaw", Vector3(0, .172, -.265), Vector3(.100, .054, .150), belly)
	oval(head, "Chin", Vector3(0, .146, -.300), Vector3(.070, .036, .092), belly_shade)
	oval(head, "MouthGap", Vector3(0, .196, -.348), Vector3(.083, .014, .112), mouth)
	strand(head, "Tongue", [Vector3(0, .196, -.365), Vector3(.020, .176, -.420), Vector3(-.010, .150, -.398)], .012, tongue)
	for side in [-1.0, 1.0]:
		oval(head, "Nostril%s" % side, Vector3(side * .035, .230, -.425), Vector3(.013, .010, .010), pupil)
		var eye_ball := oval(head, "Eye%s" % side, Vector3(side * .103, .297, -.188), Vector3(.038, .030, .030), eye)
		eye_ball.rotation.z = side * .18
		oval(head, "Pupil%s" % side, Vector3(side * .110, .297, -.212), Vector3(.013, .021, .012), pupil)
		oval(head, "EyeGlint%s" % side, Vector3(side * .113, .306, -.220), Vector3(.005, .006, .004), glow)
		oval(head, "BrowRidge%s" % side, Vector3(side * .108, .340, -.176), Vector3(.062, .016, .032), scale_hi)
		strand(head, "Whisker%s" % side, [Vector3(side * .105, .206, -.365), Vector3(side * .190, .180, -.250), Vector3(side * .245, .130, -.090), Vector3(side * .255, .060, .070)], .007, gold_light)
		strand(head, "JawFrill%s" % side, [Vector3(side * .120, .170, -.130), Vector3(side * .188, .120, -.030), Vector3(side * .210, .050, .090)], .016, fin_mat)
		# Antler-like horns rise from the crown and fork back.
		strand(head, "Horn%s" % side, [Vector3(side * .055, .350, .020), Vector3(side * .090, .455, .060), Vector3(side * .125, .548, .120), Vector3(side * .150, .625, .205)], .020, gold)
		strand(head, "HornFork%s" % side, [Vector3(side * .090, .455, .060), Vector3(side * .160, .505, .030), Vector3(side * .198, .548, .072)], .011, gold_light)
		strand(head, "HornSpur%s" % side, [Vector3(side * .125, .548, .120), Vector3(side * .192, .588, .155), Vector3(side * .221, .625, .205)], .009, gold)
		oval(head, "HornJewel%s" % side, Vector3(side * .093, .468, .070), Vector3(.019, .015, .017), glow)
		blade(head, "CheekFin%s" % side, Vector3(side * .135, .250, -.055), Vector3(0, .4, .2), Vector3(side * .215, .335, .075), .055, fin_hi)
	# Central gold crest.
	blade(head, "CrestSpike", Vector3(0, .360, -.030), Vector3(0, 0, 1), Vector3(0, .455, .120), .060, gold)
	blade(head, "CrestFin", Vector3(0, .335, .045), Vector3(0, 0, 1), Vector3(0, .410, .225), .080, fin_hi)
	torus(head, "Collar", Vector3(0, .015, -.020), .103, .026, gold)
	torus(head, "CollarLow", Vector3(0, -.060, -.010), .115, .020, gold_light)
	strand(head, "PendantChain", [Vector3(0, .000, -.108), Vector3(0, -.070, -.135), Vector3(0, -.135, -.126)], .012, gold)
	oval(head, "Pendant", Vector3(0, -.160, -.128), Vector3(.030, .040, .018), gold_light)
	strand(head, "TasselCenter", [Vector3(0, -.190, -.128), Vector3(.006, -.280, -.132), Vector3(.000, -.365, -.140)], .010, tongue)
	strand(head, "TasselLeft", [Vector3(-.012, -.190, -.126), Vector3(-.030, -.270, -.120), Vector3(-.036, -.345, -.118)], .008, tongue)
	strand(head, "TasselRight", [Vector3(.012, -.190, -.126), Vector3(.030, -.270, -.120), Vector3(.036, -.345, -.118)], .008, tongue)
	strand(head, "TasselKnot", [Vector3(-.022, -.365, -.124), Vector3(0, -.405, -.130), Vector3(.022, -.365, -.124)], .007, gold)
	merge_children(head)

	# --- Flow of purple mane behind the head ------------------------------
	var mane_node := node(visual, "Mane", Vector3(0, 1.52, .04))
	var mane_strands := [
		[Vector3(0, .15, .05), Vector3(0, .06, .26), Vector3(0, -.09, .42), Vector3(0, -.28, .50)],
		[Vector3(-.045, .145, .04), Vector3(-.085, .045, .25), Vector3(-.130, -.105, .40), Vector3(-.170, -.280, .45)],
		[Vector3(.045, .145, .04), Vector3(.085, .045, .25), Vector3(.130, -.105, .40), Vector3(.170, -.280, .45)],
		[Vector3(-.085, .100, .02), Vector3(-.155, -.010, .19), Vector3(-.225, -.150, .28), Vector3(-.280, -.300, .31)],
		[Vector3(.085, .100, .02), Vector3(.155, -.010, .19), Vector3(.225, -.150, .28), Vector3(.280, -.300, .31)],
		[Vector3(-.030, .195, .06), Vector3(-.065, .100, .30), Vector3(-.100, -.030, .47), Vector3(-.135, -.190, .55)],
		[Vector3(.030, .195, .06), Vector3(.065, .100, .30), Vector3(.100, -.030, .47), Vector3(.135, -.190, .55)],
	]
	for i in mane_strands.size():
		var mane_points: Array[Vector3] = []
		for point: Vector3 in mane_strands[i]:
			mane_points.append(point)
		tuft(mane_node, "ManeStrand%d" % i, mane_points, .072, mane_light if i % 3 == 0 else mane)
	for side in [-1.0, 1.0]:
		strand(mane_node, "ManeVein%s" % side, [Vector3(side * .045, .140, .05), Vector3(side * .090, .035, .26), Vector3(side * .135, -.110, .41)], .008, scale_hi)
	merge_children(mane_node)

	# --- Drifting blossoms around the neck and coil -----------------------
	var blossoms := node(visual, "Blossoms")
	var blossom_specs := [
		[Vector3(.150, 1.305, -.105), .58, .5],
		[Vector3(-.155, 1.255, -.055), .52, -.9],
		[Vector3(.315, .500, .060), .46, .2],
		[Vector3(-.390, .455, .180), .44, 1.3],
	]
	for i in blossom_specs.size():
		var spec: Array = blossom_specs[i]
		var blossom := small_lotus(blossoms, "Blossom%d" % i, float(spec[1]))
		blossom.position = spec[0]
		blossom.rotation.y = float(spec[2])
		merge_children(blossom)

	# --- Purple miasma wisps curl around the spirit -----------------------
	var miasma := node(visual, "Miasma")
	var plumes := [
		[Vector3(-.30, .30, .30), Vector3(-.48, .62, .34), Vector3(-.60, .98, .26), Vector3(-.54, 1.35, .16), Vector3(-.64, 1.70, .06), Vector3(-.56, 1.96, -.02)],
		[Vector3(.34, .28, .32), Vector3(.50, .60, .36), Vector3(.58, .95, .28), Vector3(.50, 1.28, .18), Vector3(.58, 1.58, .08), Vector3(.50, 1.80, .00)],
		[Vector3(-.05, .34, .46), Vector3(.05, .64, .56), Vector3(.02, 1.00, .52), Vector3(-.06, 1.34, .42), Vector3(.00, 1.62, .32), Vector3(-.04, 1.84, .24)],
		[Vector3(.22, .26, -.30), Vector3(.34, .52, -.40), Vector3(.30, .84, -.40), Vector3(.22, 1.12, -.32), Vector3(.28, 1.36, -.24)],
		[Vector3(-.28, .24, -.26), Vector3(-.40, .48, -.36), Vector3(-.38, .78, -.36), Vector3(-.30, 1.04, -.28)],
	]
	for i in plumes.size():
		var plume_points: Array[Vector3] = []
		for point: Vector3 in plumes[i]:
			plume_points.append(point)
		plume(miasma, "MiasmaPlume%d" % i, plume_points, smoke if i % 2 == 0 else smoke_deep)
	var mote_positions := [Vector3(-.52, .70, .20), Vector3(.48, .94, .22), Vector3(.10, 1.28, .46), Vector3(-.30, 1.52, .18), Vector3(.34, 1.72, .12), Vector3(-.14, 1.90, .22)]
	for i in mote_positions.size():
		oval(miasma, "Mote%d" % i, mote_positions[i], Vector3(.014, .014, .014), glow)
	merge_children(miasma)

	var light := OmniLight3D.new()
	light.name = "MiasmaLight"
	visual.add_child(light)
	light.owner = visual
	light.position = Vector3(0, 1.45, .08)
	light.light_color = Color("b06bff")
	light.light_energy = .46
	light.omni_range = 2.8
	light.shadow_enabled = false

	own_tree(visual)
	save_visual("res://scenes/units/shadow_naga_visual.tscn")
