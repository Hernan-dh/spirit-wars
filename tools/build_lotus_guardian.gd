extends "res://tools/unit_visual_builder.gd"
## Deterministic, editable native mesh authoring for the Lotus Guardian.
## godot --headless --path . --script tools/build_lotus_guardian.gd
const StaticGeometry = preload("res://tools/static_geometry.gd")

var skin: StandardMaterial3D
var skin_shade: StandardMaterial3D
var hair: StandardMaterial3D
var hair_light: StandardMaterial3D
var robe_white: StandardMaterial3D
var robe_cyan: StandardMaterial3D
var robe_teal: StandardMaterial3D
var robe_deep: StandardMaterial3D
var gold: StandardMaterial3D
var jade: StandardMaterial3D
var stamen: StandardMaterial3D
var petal_mid: StandardMaterial3D
var petal_light_mat: StandardMaterial3D
var petal_deep_mat: StandardMaterial3D
var pad: StandardMaterial3D
var pad_light: StandardMaterial3D
var water: StandardMaterial3D
var glow: StandardMaterial3D
var ink: StandardMaterial3D
var lip: StandardMaterial3D
var _ribbon_materials: Dictionary = {}

func cull_disabled(source: StandardMaterial3D) -> StandardMaterial3D:
	var result := source.duplicate() as StandardMaterial3D
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
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

func ribbon(parent: Node3D, label: String, points: Array[Vector3], width: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var w := Vector3(width * 0.5, 0, 0)
		for p in [points[i] - w, points[i + 1] - w, points[i + 1] + w, points[i] - w, points[i + 1] + w, points[i] + w]:
			st.add_vertex(p)
	st.generate_normals()
	if not _ribbon_materials.has(mat):
		_ribbon_materials[mat] = cull_disabled(mat)
	return mesh(parent, label, st.commit(), _ribbon_materials[mat])

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

func lily_pad(parent: Node3D, label: String, radius: float, mat: Material) -> MeshInstance3D:
	const SEGMENTS := 30
	const NOTCH := .34
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center_top := Vector3(0, 0, 0)
	var center_bottom := Vector3(0, -.012, 0)
	for i in SEGMENTS:
		var a := NOTCH + (TAU - NOTCH) * i / SEGMENTS
		var b := NOTCH + (TAU - NOTCH) * (i + 1) / SEGMENTS
		var pa := Vector3(cos(a) * radius, 0, sin(a) * radius)
		var pb := Vector3(cos(b) * radius, 0, sin(b) * radius)
		var qa := pa + Vector3(0, -.012, 0)
		var qb := pb + Vector3(0, -.012, 0)
		for point in [center_top, pa, pb, center_bottom, qb, qa]:
			st.add_vertex(point)
	st.generate_normals()
	return mesh(parent, label, st.commit(), cull_disabled(mat))

func small_lotus(parent: Node3D, label: String, flower_scale: float) -> Node3D:
	var flower := node(parent, label)
	oval(flower, "Heart", Vector3(0, .02, 0), Vector3(.045, .030, .045), stamen)
	var rings := [
		{"count": 6, "length": .21, "width": .070, "rise": .075, "offset": 0.0, "mat": petal_mid},
		{"count": 5, "length": .16, "width": .058, "rise": .105, "offset": PI / 5.0, "mat": petal_light_mat},
	]
	for ring in rings:
		for i in int(ring["count"]):
			var p := petal(flower, "Petal%d" % i, float(ring["length"]), float(ring["width"]), float(ring["rise"]), ring["mat"])
			p.position = Vector3(0, .01, 0)
			p.rotation.y = TAU * i / float(ring["count"]) + float(ring["offset"])
	flower.scale = Vector3.ONE * flower_scale
	return flower

func merge_children(parent: Node3D) -> void:
	var entries: Array = []
	StaticGeometry.collect_meshes(parent, Transform3D.IDENTITY, entries)
	StaticGeometry.merge_meshes(parent, entries, false)
	StaticGeometry.prune_empty(parent)

func own_tree(parent: Node) -> void:
	for child in parent.get_children():
		child.owner = visual
		own_tree(child)

func _initialize() -> void:
	material_roughness = .52
	begin_visual("LotusGuardianVisual")
	skin = material("f3d8c6", .015)
	skin_shade = material("dcb5a6", .01)
	hair = material("1b2340", .02, .12)
	hair_light = material("35446e", .05, .16)
	robe_white = material("e8f7f3", .035)
	robe_cyan = material("8edde0", .07)
	robe_teal = material("3d93ad", .055)
	robe_deep = material("1f5d7c", .04)
	gold = material("ebc15d", .14, .68)
	jade = material("64cbb1", .12, .18)
	stamen = material("ffd66f", .38)
	petal_mid = cull_disabled(material("f291bb", .12))
	petal_light_mat = cull_disabled(material("ffd4e4", .16))
	petal_deep_mat = cull_disabled(material("d95594", .08))
	pad = cull_disabled(material("3f8f5e", .02))
	pad_light = material("7bc788", .05)
	water = material("54b8c7", .22, .05)
	glow = material("d9fff7", .9)
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink = material("161a2c", .01)
	lip = material("c45d78", .04)

	# --- Sacred lotus base: stone rim, water, lily pad and bloom -----------
	var base := node(visual, "LotusBase")
	lathe(base, "StonePlinth", [Vector2(.49, .00), Vector2(.53, .045), Vector2(.51, .082), Vector2(.43, .096)], cull_disabled(material("4b5c5d", .01)), 30)
	for i in 12:
		var angle := TAU * i / 12.0 + .15
		var stone := oval(base, "RimStone%d" % i, Vector3(cos(angle) * .475, .075, sin(angle) * .475), Vector3(.085, .045, .065), material("5a6a67") if i % 2 == 0 else material("6f7f63", .02))
		stone.rotation.y = -angle
	lathe(base, "StillWater", [Vector2(.02, .088), Vector2(.44, .088), Vector2(.45, .103)], water, 36)
	torus(base, "WaterRipple0", Vector3(0, .105, 0), .36, .010, glow)
	torus(base, "WaterRipple1", Vector3(0, .105, 0), .23, .008, robe_cyan)
	lily_pad(base, "LilyPad", .405, pad)
	for i in 9:
		var angle := .78 + (TAU - .78) * i / 9.0
		strand(base, "PadVein%d" % i, [Vector3(cos(angle) * .045, .118, sin(angle) * .045), Vector3(cos(angle) * .36, .118, sin(angle) * .36)], .006, pad_light)

	var lotus := node(base, "SacredLotus", Vector3(0, .105, 0))
	oval(lotus, "GoldenHeart", Vector3(0, .09, 0), Vector3(.10, .055, .10), stamen)
	for i in 10:
		var angle := TAU * i / 10.0
		strand(lotus, "Stamen%d" % i, [Vector3(cos(angle) * .035, .10, sin(angle) * .035), Vector3(cos(angle) * .13, .20, sin(angle) * .13)], .006, stamen)
	var petal_rings := [
		{"count": 10, "length": .60, "width": .175, "rise": .155, "offset": 0.0, "y": .01, "mat": petal_deep_mat},
		{"count": 9, "length": .53, "width": .160, "rise": .255, "offset": PI / 9.0, "y": .025, "mat": petal_mid},
		{"count": 7, "length": .41, "width": .130, "rise": .305, "offset": PI / 7.0, "y": .065, "mat": petal_light_mat},
		{"count": 5, "length": .30, "width": .105, "rise": .255, "offset": PI / 5.0, "y": .095, "mat": petal_deep_mat},
	]
	for ring in petal_rings:
		for i in int(ring["count"]):
			var p := petal(lotus, "Petal%d" % i, float(ring["length"]), float(ring["width"]), float(ring["rise"]), ring["mat"])
			p.position = Vector3(0, float(ring["y"]), 0)
			p.rotation.y = TAU * i / float(ring["count"]) + float(ring["offset"])
	for i in 5:
		var angle := .35 + TAU * i / 5.0
		var fallen := petal(base, "FallenPetal%d" % i, .16, .05, .008, petal_light_mat)
		fallen.position = Vector3(cos(angle) * .34, .118, sin(angle) * .34)
		fallen.rotation.y = -angle
		fallen.rotation.x = -.35
	merge_children(base)

	# --- Layered robes, sleeves, hands and ornamental sash ----------------
	var body := node(visual, "GuardianBody")
	lathe(body, "InnerRobe", [Vector2(.02, 1.37), Vector2(.16, 1.37), Vector2(.155, 1.28), Vector2(.18, 1.15), Vector2(.26, .98), Vector2(.35, .80), Vector2(.44, .61), Vector2(.46, .50), Vector2(.30, .45), Vector2(.02, .44)], robe_white, 30)
	for i in 8:
		var angle := TAU * i / 8.0 + PI / 8.0
		var panel := node(body, "RobePanel%d" % i)
		panel.rotation.y = angle
		ribbon(panel, "Cloth", [Vector3(0, 1.32, .15), Vector3(0, 1.15, .27), Vector3(0, .95, .36), Vector3(0, .72, .43), Vector3(0, .50, .47)], .145, robe_cyan if i % 2 == 0 else robe_teal)
		ribbon(panel, "InnerFold", [Vector3(0, 1.25, .17), Vector3(0, 1.04, .30), Vector3(0, .82, .38), Vector3(0, .62, .44)], .070, robe_deep if i % 3 == 0 else robe_white)
		for side in [-1.0, 1.0]:
			ribbon(panel, "GoldTrim%s" % side, [Vector3(side * .068, 1.30, .155), Vector3(side * .070, 1.12, .275), Vector3(side * .073, .93, .360), Vector3(side * .074, .70, .433), Vector3(side * .074, .51, .468)], .011, gold)
	torus(body, "HemBand", Vector3(0, .515, 0), .445, .013, gold)
	oval(body, "Bodice", Vector3(0, 1.46, 0), Vector3(.155, .205, .115), robe_white)
	oval(body, "WaistWrap", Vector3(0, 1.35, 0), Vector3(.172, .085, .125), robe_cyan)
	torus(body, "GoldSash", Vector3(0, 1.345, 0), .175, .030, gold)
	ribbon(body, "CollarLeft", [Vector3(-.135, 1.60, -.075), Vector3(-.060, 1.51, -.120), Vector3(-.008, 1.405, -.130)], .030, robe_teal)
	ribbon(body, "CollarRight", [Vector3(.135, 1.60, -.075), Vector3(.060, 1.51, -.120), Vector3(.008, 1.405, -.130)], .030, robe_teal)
	strand(body, "GoldNecklace", [Vector3(-.085, 1.565, -.070), Vector3(0, 1.505, -.118), Vector3(.085, 1.565, -.070)], .010, gold)
	oval(body, "SashKnot", Vector3(0, 1.33, -.165), Vector3(.045, .040, .022), gold)
	small_lotus(body, "SashLotus", .42).position = Vector3(0, 1.275, -.180)

	for side in [-1.0, 1.0]:
		var sleeve_path: Array[Vector3] = [Vector3(side * .145, 1.605, -.005), Vector3(side * .265, 1.485, .005), Vector3(side * .345, 1.285, .035), Vector3(side * .375, 1.075, .010), Vector3(side * .320, .955, -.030)]
		var path := smooth_path(sleeve_path, 5)
		var widths: Array[float] = []
		var depths: Array[float] = []
		for i in path.size():
			var t := float(i) / (path.size() - 1)
			widths.append(lerpf(.075, .155, sin(t * PI * .85)))
			depths.append(lerpf(.090, .175, sin(t * PI * .85)))
		sweep(body, "Sleeve%s" % side, path, widths, depths, robe_cyan if side < 0 else robe_teal, 10)
		oval(body, "Shoulder%s" % side, Vector3(side * .150, 1.585, -.005), Vector3(.085, .105, .090), robe_white)
		strand(body, "CuffBand%s" % side, [Vector3(side * .300, .990, -.020), Vector3(side * .335, .985, .000), Vector3(side * .350, .955, .015), Vector3(side * .320, .935, -.025)], .012, gold)
		var hand := oval(body, "Hand%s" % side, Vector3(side * .270, .925, -.095), Vector3(.038, .062, .032), skin)
		hand.rotation.z = side * .24
		for finger in 3:
			strand(body, "Finger%s%d" % [side, finger], [Vector3(side * (.255 + finger * .014), .905, -.105), Vector3(side * (.245 + finger * .016), .860, -.115), Vector3(side * (.245 + finger * .018), .835, -.120)], .006, skin)
		strand(body, "WristBead%s" % side, [Vector3(side * .245, .945, -.070), Vector3(side * .285, .950, -.055), Vector3(side * .310, .940, -.070)], .008, jade)
	small_lotus(body, "HandLotus", .48).position = Vector3(-.295, .965, -.140)

	# --- Head, long hair, painted features and lotus headdress ------------
	oval(body, "Neck", Vector3(0, 1.675, -.015), Vector3(.052, .075, .050), skin)
	oval(body, "Head", Vector3(0, 1.845, -.020), Vector3(.102, .122, .096), skin)
	oval(body, "Chin", Vector3(0, 1.775, -.045), Vector3(.072, .070, .070), skin)
	for side in [-1.0, 1.0]:
		oval(body, "Ear%s" % side, Vector3(side * .098, 1.845, -.020), Vector3(.020, .040, .022), skin)
		var eye := oval(body, "Eye%s" % side, Vector3(side * .042, 1.858, -.099), Vector3(.024, .014, .011), ink)
		eye.rotation.z = side * .12
		oval(body, "Iris%s" % side, Vector3(side * .044, 1.857, -.107), Vector3(.010, .011, .005), robe_teal)
		oval(body, "Glint%s" % side, Vector3(side * .047, 1.862, -.112), Vector3(.004, .004, .003), glow)
		strand(body, "Brow%s" % side, [Vector3(side * .018, 1.884, -.101), Vector3(side * .045, 1.890, -.099), Vector3(side * .066, 1.882, -.092)], .006, hair)
		oval(body, "Blush%s" % side, Vector3(side * .061, 1.806, -.096), Vector3(.021, .009, .006), lip)
		strand(body, "Earring%s" % side, [Vector3(side * .105, 1.820, -.012), Vector3(side * .112, 1.785, -.010), Vector3(side * .108, 1.765, -.010)], .008, gold)
		oval(body, "EarringBead%s" % side, Vector3(side * .108, 1.755, -.010), Vector3(.012, .012, .010), jade)
	oval(body, "Nose", Vector3(0, 1.818, -.104), Vector3(.011, .018, .012), skin_shade)
	oval(body, "Lips", Vector3(0, 1.785, -.106), Vector3(.024, .008, .008), lip)
	strand(body, "CrownBand", [Vector3(-.105, 1.915, -.015), Vector3(-.070, 1.935, -.070), Vector3(0, 1.945, -.092), Vector3(.070, 1.935, -.070), Vector3(.105, 1.915, -.015)], .009, gold)
	small_lotus(body, "BrowLotus", .30).position = Vector3(0, 1.928, -.086)
	for side in [-1.0, 1.0]:
		var pin := node(body, "HairPin%s" % side)
		strand(pin, "GoldPin", [Vector3(side * .085, 1.910, .010), Vector3(side * .175, 1.965, .020), Vector3(side * .255, 1.940, .030)], .010, gold)
		oval(pin, "PinJade", Vector3(side * .198, 1.975, .022), Vector3(.018, .028, .010), jade)
		small_lotus(pin, "PinLotus", .26).position = Vector3(side * .245, 1.945, .032)
		strand(pin, "CharmSilk", [Vector3(side * .250, 1.930, .030), Vector3(side * .270, 1.850, .035), Vector3(side * .265, 1.770, .040)], .006, robe_cyan)
		for bead in 3:
			oval(pin, "CharmBead%s%d" % [side, bead], Vector3(side * (.266 + bead * .002), 1.835 - bead * .030, .038), Vector3(.011, .013, .011), gold)

	merge_children(body)

	# Hair cap and long strands stay in their own node so they can sway.
	var hair_node := node(visual, "Hair")
	oval(hair_node, "HairCap", Vector3(0, 1.885, .022), Vector3(.112, .132, .106), hair)
	oval(hair_node, "HairBack", Vector3(0, 1.800, .065), Vector3(.098, .180, .075), hair)
	for side in [-1.0, 1.0]:
		strand(hair_node, "SideLock%s" % side, [Vector3(side * .092, 1.900, .020), Vector3(side * .128, 1.735, .035), Vector3(side * .142, 1.545, .060), Vector3(side * .126, 1.390, .080)], .043, hair)
		strand(hair_node, "LongLock%s" % side, [Vector3(side * .070, 1.920, .070), Vector3(side * .105, 1.690, .105), Vector3(side * .138, 1.390, .140), Vector3(side * .150, 1.090, .165), Vector3(side * .125, .820, .190)], .052, hair)
		strand(hair_node, "OuterLock%s" % side, [Vector3(side * .045, 1.900, .085), Vector3(side * .075, 1.640, .135), Vector3(side * .095, 1.320, .180), Vector3(side * .105, 1.010, .215), Vector3(side * .085, .760, .235)], .036, hair)
		for i in 3:
			var start := Vector3(side * (0.055 + i * .018), 1.955 - i * .012, .055 - i * .020)
			var tip := Vector3(side * (0.035 + i * .035), 1.895 - i * .015, -.090 + i * .018)
			tuft(hair_node, "Bang%s%d" % [side, i], [start, start.lerp(tip, .55) + Vector3(side * .012, .006, 0), tip], .030, hair)
		strand(hair_node, "HairShine%s" % side, [Vector3(side * .076, 1.905, .075), Vector3(side * .108, 1.660, .120), Vector3(side * .122, 1.420, .155), Vector3(side * .124, 1.180, .178)], .008, hair_light)
	strand(hair_node, "PartLine", [Vector3(0, 2.005, .015), Vector3(0, 1.930, -.040), Vector3(0, 1.900, -.080)], .006, hair_light)
	merge_children(hair_node)

	# --- Trailing silk sashes live in an animated group -------------------
	var ribbons := node(visual, "Ribbons")
	for side in [-1.0, 1.0]:
		var sash := node(ribbons, "Sash%s" % side)
		ribbon(sash, "OuterSilk", [Vector3(side * .145, 1.335, .105), Vector3(side * .315, 1.245, .170), Vector3(side * .485, 1.035, .215), Vector3(side * .585, .800, .245), Vector3(side * .610, .625, .255)], .090, robe_cyan if side < 0 else robe_teal)
		ribbon(sash, "InnerSilk", [Vector3(side * .120, 1.300, .120), Vector3(side * .260, 1.165, .190), Vector3(side * .390, .930, .230), Vector3(side * .455, .720, .255)], .050, robe_white)
		ribbon(sash, "GoldEdge", [Vector3(side * .190, 1.315, .110), Vector3(side * .350, 1.205, .175), Vector3(side * .510, .985, .220), Vector3(side * .605, .760, .250)], .012, gold)
		merge_children(sash)
	ribbon(ribbons, "BackVeil", [Vector3(-.130, 1.555, .095), Vector3(-.160, 1.300, .150), Vector3(-.175, 1.000, .180), Vector3(-.165, .720, .195)], .115, robe_white)
	ribbon(ribbons, "BackVeilTrim", [Vector3(-.130, 1.545, .098), Vector3(-.160, 1.290, .153), Vector3(-.175, .990, .183), Vector3(-.165, .715, .198)], .014, gold)

	# --- Small lotus blossoms drift around the guardian -------------------
	var floating := node(visual, "FloatingLotus")
	var positions := [Vector3(-.61, .58, .14), Vector3(.57, .72, .24), Vector3(.22, 1.02, .56), Vector3(-.30, .92, -.52)]
	for i in positions.size():
		var blossom := node(floating, "Blossom%d" % i, positions[i])
		small_lotus(blossom, "Flower", 1.0)
		oval(blossom, "Mote", Vector3(0, .185, 0), Vector3(.020, .020, .020), glow)
		merge_children(blossom)

	var light := OmniLight3D.new()
	light.name = "LotusLight"
	visual.add_child(light)
	light.owner = visual
	light.position = Vector3(0, 1.35, .10)
	light.light_color = Color("8fe8e4")
	light.light_energy = .42
	light.omni_range = 2.6
	light.shadow_enabled = false

	own_tree(visual)
	save_visual("res://scenes/units/lotus_guardian_visual.tscn")
