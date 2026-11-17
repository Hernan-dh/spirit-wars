extends SceneTree
## Rebuild the authored courtyard: godot --headless --path . --script tools/build_battlefield.gd
## Generated scenes contain ordinary, individually editable Godot nodes.

const ISLAND_RIM := [Vector2(-8.8,-6.6),Vector2(-6.8,-9.2),Vector2(5.4,-9.7),Vector2(8.9,-6.8),Vector2(9.4,3.7),Vector2(7.1,7.8),Vector2(3.6,8.4),Vector2(-6.2,7.9),Vector2(-9.3,4.5)]
const LANDSCAPE_SCALE := 2.0
const GRID_SIZE := 14
const HEX_RADIUS := 0.94
const GRID_CENTER_Z := 1.4

var rng := RandomNumberGenerator.new()
var palette: Dictionary = {}
var prop_scenes: Dictionary = {}

func _initialize() -> void:
	rng.seed = 72819
	make_materials()
	make_props()
	build_battlefield()
	quit()

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

func make_materials() -> void:
	material("Stone", "657d88")
	material("StoneLight", "91a0a4")
	material("StoneDark", "334956")
	material("Foundation", "233846")
	material("Earth", "4b6056")
	material("Moss", "506a48")
	material("Cliff", "3e5262")
	material("CliffLight", "647782")
	material("Grass", "718a53")
	material("Sand", "7c8c86")
	material("Foam", "a8e4e1", 0.35)
	material("FallingWater", "62b6c6", 0.4, 0.25)
	material("MossLight", "8aab75")
	material("Jade", "30736c")
	material("Leaf", "3f7967")
	material("LeafLight", "73a378")
	material("Bamboo", "4a8172")
	material("Wood", "452f40")
	material("WoodLight", "86585a")
	material("Roof", "254e60", 0.0, 0.22)
	material("Gold", "cca76c", 0.0, 0.5)
	material("Seam", "9ba795")
	material("Meadow", "566b52")
	material("MeadowLight", "63765b")
	material("MossPaving", "657b6c")
	material("TrailEarth", "727666")
	material("BankPaving", "617c81")
	material("Cloth", "ab5265")
	material("Blossom", "d887b9")
	material("BlossomLight", "f4bbd7")
	material("BlossomDark", "ac609d")
	material("Water", "286975", 0.12, 0.5).roughness = 0.2
	material("Ripple", "70c9c7", 0.5)
	material("Spirit", "6ef5ed", 2.0)
	material("SpiritDim", "338d96", 0.8)
	material("Amber", "ff9f42", 0.8)
	for i in range(6):
		var m := material("Paving%d" % i, "71858f")
		m.albedo_color = Color("71858f").darkened(i * 0.032)

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
	var g := SphereMesh.new()
	g.radius = 1.0
	g.height = 2.0
	g.radial_segments = 7
	g.rings = 3
	var n := mesh(parent, title, g, mat, pos)
	n.scale = size
	n.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.15, 0.15))
	return n

func rod(parent: Node, title: String, a: Vector3, b: Vector3, radius: float, mat: String, top := -1.0) -> MeshInstance3D:
	var n := cylinder(parent, title, (a + b) * 0.5, radius, radius if top < 0 else top, a.distance_to(b), mat, 6)
	var direction := (b - a).normalized()
	n.quaternion = Quaternion(Vector3.UP, direction)
	return n

func line(parent: Node, title: String, points: Array, radius: float, mat: String) -> Node3D:
	var n := node(parent, title)
	for i in range(points.size() - 1):
		rod(n, "Segment%02d" % i, points[i], points[i + 1], radius, mat)
	return n

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
	for i in range(8):
		rod(n, "GildedEave%d" % i, rings[0][i], rings[0][(i+1)%8], 0.025, "Gold")
		line(n, "RoofRib%d" % i, [rings[0][i], rings[1][i], rings[2][i]], 0.018, "Jade")
	cylinder(n, "Finial", Vector3(0,height + 0.12,0), .12, .0, .35, "Gold")
	return n

func own_recursive(n: Node, root: Node) -> void:
	for child in n.get_children():
		if child.owner == null:
			child.owner = root
		own_recursive(child, root)

func save_scene(root: Node, path: String) -> PackedScene:
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
	return n

func make_props() -> void:
	var lantern := Node3D.new()
	lantern.name = "StoneLantern"
	box(lantern, "Foot", Vector3(0,.12,0), Vector3(.9,.24,.9), "StoneDark")
	box(lantern, "Plinth", Vector3(0,.29,0), Vector3(.72,.12,.72), "StoneLight")
	cylinder(lantern, "Column", Vector3(0,.8,0), .26,.20,1.0,"Stone",6)
	box(lantern, "LightShelf", Vector3(0,1.34,0), Vector3(.85,.18,.85), "StoneLight")
	box(lantern, "LuminousPaper", Vector3(0,1.72,0), Vector3(.48,.62,.48), "Amber")
	for x in [-1,1]:
		for z in [-1,1]:
			box(lantern, "Corner_%d_%d" % [x,z], Vector3(x*.31,1.73,z*.31), Vector3(.075,.76,.075), "Wood")
	box(lantern, "Lintel", Vector3(0,2.08,0), Vector3(.72,.12,.72), "Wood")
	roof(lantern, "PagodaCap", Vector3(0,2.1,0), .62, .37)
	var light := OmniLight3D.new()
	light.name = "WarmLanternLight"
	light.position.y = 1.8
	light.light_color = Color("ffb963")
	light.light_energy = 1.1
	light.omni_range = 4.3
	lantern.add_child(light)
	prop_scenes["lantern"] = save_scene(lantern,"res://scenes/props/stone_lantern.tscn")

	var tree := Node3D.new()
	tree.name = "BlossomTree"
	rod(tree,"AncientTrunk",Vector3.ZERO,Vector3(.18,2.3,0),.34,"Wood",.22)
	rod(tree,"LeaningTrunk",Vector3(.18,2.3,0),Vector3(-.45,3.7,.1),.22,"Wood",.09)
	var ends := [Vector3(-1.8,3.6,.1),Vector3(1.6,3.4,.1),Vector3(.4,4.35,-.5),Vector3(-.2,3.5,1.3),Vector3(.6,3.6,-1.2)]
	for i in range(ends.size()):
		rod(tree,"Bough%d" % i,Vector3(.1,2.0+i*.17,0),ends[i],.17,"Wood",.045)
		for j in range(4):
			var p: Vector3 = ends[i] + Vector3(rng.randf_range(-.65,.65),rng.randf_range(-.2,.4),rng.randf_range(-.5,.5))
			rock(tree,"FlowerCrown%d_%d" % [i,j],p,Vector3(.82,.45,.66),["Blossom","BlossomLight","BlossomDark"][(i+j)%3])
	for i in range(5):
		var a := i*TAU/5
		rod(tree,"Root%d" % i,Vector3(0,.15,0),Vector3(cos(a)*.8,0,sin(a)*.8),.12,"Wood",.04)
	prop_scenes["tree"] = save_scene(tree,"res://scenes/props/blossom_tree.tscn")

	var bamboo := Node3D.new()
	bamboo.name = "BambooGrove"
	for i in range(6):
		var p := Vector3(rng.randf_range(-.7,.7),0,rng.randf_range(-.6,.6))
		var h := rng.randf_range(2.7,4.7)
		var tip := p + Vector3(rng.randf_range(-.45,.45),h,rng.randf_range(-.4,.4))
		rod(bamboo,"Culm%d" % i,p,tip,.065,"Bamboo",.035)
		for j in range(1,7):
			var mid := p.lerp(tip,j/7.0)
			cylinder(bamboo,"Joint%d_%d" % [i,j],mid,.078,.078,.045,"MossLight")
			if j > 2:
				var direction := Vector3(1 if (i+j)%2==0 else -1,.25,.2)
				rod(bamboo,"Twig%d_%d" % [i,j],mid,mid+direction*.7,.023,"Bamboo",.008)
				for k in range(3):
					var base := mid + direction * (.2+k*.18)
					var tip_leaf := base + Vector3(direction.x*.5,-.16,(k-1)*.57)
					var side := Vector3(.055,.10,.16)
					var leaf := surface(bamboo,"Leaf%d_%d_%d" % [i,j,k],[base,base.lerp(tip_leaf,.5)+side,tip_leaf,base,tip_leaf,base.lerp(tip_leaf,.5)-side],"LeafLight" if k%2 else "Leaf")
					var m: StandardMaterial3D = leaf.material_override.duplicate()
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
					leaf.material_override = m
	prop_scenes["bamboo"] = save_scene(bamboo,"res://scenes/props/bamboo_grove.tscn")

	var lotus := Node3D.new()
	lotus.name = "Lotus"
	cylinder(lotus,"LilyPad",Vector3(0,.01,0),.35,.35,.025,"Leaf",10)
	for i in range(8):
		var a := i*TAU/8
		var petal := rock(lotus,"Petal%d"%i,Vector3(cos(a)*.15,.13,sin(a)*.15),Vector3(.10,.17,.22),"BlossomLight" if i%2 else "Blossom")
		petal.rotation = Vector3(cos(a)*.6,a,sin(a)*.6)
	cylinder(lotus,"GoldenHeart",Vector3(0,.16,0),.085,.045,.13,"Amber")
	prop_scenes["lotus"] = save_scene(lotus,"res://scenes/props/lotus.tscn")

	var gate := Node3D.new()
	gate.name = "SpiritGate"
	for i in range(5):
		box(gate,"ApproachStep%d"%i,Vector3(0,.12+i*.16,1.45-i*.42),Vector3(5.2-i*.15,.24+i*.32,.5),"Stone" if i%2 else "StoneLight")
	box(gate,"SanctuaryPlatform",Vector3(0,.48,-.72),Vector3(6.4,.96,2.5),"StoneDark")
	box(gate,"PlatformCornice",Vector3(0,1.0,-.72),Vector3(6.55,.18,2.6),"Stone")
	for side in [-1,1]:
		var x: float = side * 2.28
		box(gate,"PillarFoot%d"%side,Vector3(x,1.25,-.35),Vector3(.96,.4,.95),"StoneLight")
		box(gate,"JadePillar%d"%side,Vector3(x,2.85,-.35),Vector3(.55,3.0,.58),"Jade")
		for y in [1.55,3.7,4.15]:
			box(gate,"Collar%d_%s"%[side,y],Vector3(x,y,-.35),Vector3(.7,.13,.72),"Gold")
		box(gate,"Inset%d"%side,Vector3(x,2.85,-.046),Vector3(.21,1.7,.025),"StoneDark")
		for j in range(4):
			var gem := box(gate,"Glyph%d_%d"%[side,j],Vector3(x,2.25+j*.38,-.025),Vector3(.11,.11,.035),"SpiritDim")
			gem.rotation.z = PI/4
		rod(gate,"BannerArm%d"%side,Vector3(x,4.1,-.3),Vector3(x+side*.8,4.1,-.3),.05,"Gold")
		box(gate,"SilkBanner%d"%side,Vector3(x+side*.6,3.42,-.3),Vector3(.4,1.25,.035),"Cloth")
		box(gate,"BannerStripe%d"%side,Vector3(x+side*.6,3.42,-.27),Vector3(.025,1.12,.015),"Gold")
		var gem := box(gate,"BannerEmblem%d"%side,Vector3(x+side*.6,3.5,-.265),Vector3(.18,.18,.025),"Gold")
		gem.rotation.z = PI/4
	box(gate,"TimberLintel",Vector3(0,4.35,-.35),Vector3(5.55,.32,.65),"Wood")
	box(gate,"GoldLintel",Vector3(0,4.49,-.35),Vector3(5.8,.09,.77),"Gold")
	var r := roof(gate,"GreatSweptRoof",Vector3(0,4.55,-.35),3.0,.9)
	r.scale.z = .4
	var r2 := roof(gate,"CrownRoof",Vector3(0,5.35,-.35),1.65,.65)
	r2.scale.z = .46
	circle(gate,"CarvedHalo",Vector3(0,2.66,-.55),1.42,"StoneLight",.14,true,24)
	circle(gate,"InnerHalo",Vector3(0,2.66,-.38),1.29,"SpiritDim",.025,true)
	for i in range(8):
		var a := i*TAU/8
		var gem := box(gate,"HaloSeal%d"%i,Vector3(cos(a)*1.43,2.66+sin(a)*1.43,-.38),Vector3(.16,.24,.12),"Gold")
		gem.rotation.z = a-PI/2
	var spirit: Array = []
	for i in range(49):
		var t := i/48.0
		spirit.append(Vector3(sin(t*TAU*1.45)*(.47-.25*t),1.42+t*2.65,-.18))
	line(gate,"AscendingSpirit",spirit,.04,"Spirit")
	for i in range(12):
		rock(gate,"FloatingMote%d"%i,Vector3(rng.randf_range(-1.05,1.05),rng.randf_range(1.4,4),rng.randf_range(-.1,.3)),Vector3.ONE*.035,"Spirit")
	var glow := OmniLight3D.new()
	glow.name = "PortalGlow"
	glow.position = Vector3(0,2.5,.3)
	glow.light_color = Color("59e9e5")
	glow.light_energy = 3.0
	glow.omni_range = 5.5
	gate.add_child(glow)
	prop_scenes["gate"] = save_scene(gate,"res://scenes/props/spirit_gate.tscn")

func grid_position(row: int, column: int) -> Vector3:
	var midpoint := (GRID_SIZE - 1) * .5
	return Vector3((column-midpoint)*sqrt(3.0)*HEX_RADIUS + (row%2)*sqrt(3.0)*HEX_RADIUS*.5-sqrt(3.0)*HEX_RADIUS*.25,-.35,(row-midpoint)*1.5*HEX_RADIUS+GRID_CENTER_Z)

func ground_material(pos: Vector3) -> String:
	# Continuous meadow patches and paths cross cell boundaries, avoiding a checkerboard.
	var pilgrim_path := absf(pos.x - sin(pos.z*.4)*1.6) < 2.0
	var crossing_path := absf(pos.z + .4 - sin(pos.x*.3)*1.2) < 1.45
	if pilgrim_path or crossing_path or Vector2(pos.x,pos.z-1.4).length() < 3.3:
		return "Paving%d"%rng.randi_range(0,5)
	if pos.x > 7.5 + sin(pos.z*.5):
		return "BankPaving"
	var meadow := sin(pos.x*.36) + cos(pos.z*.42) + sin((pos.x+pos.z)*.23)
	if meadow < -.55 or (pos.x < -7.0 and pos.z > 3):
		return "MeadowLight" if meadow < -1.2 else "Meadow"
	if meadow > 1.25:
		return "TrailEarth"
	return "MossPaving"

func make_tile(parent: Node, row: int, column: int) -> void:
	var pos := grid_position(row,column)
	var terrain_mat := ground_material(pos)
	var tile := node(parent,"Hex_%d_%d"%[row+1,column+1],pos)
	tile.set_meta("row",row)
	tile.set_meta("column",column)
	tile.set_meta("axial_q",column - (row - row%2)/2)
	tile.set_meta("axial_r",row)
	tile.set_meta("terrain",terrain_mat)
	tile.set_meta("surface_height",.35)
	var faces: Array = []
	for i in range(6):
		var a := PI/6+i*TAU/6
		var b := PI/6+(i+1)*TAU/6
		var a0 := Vector3(cos(a)*.938,.04,sin(a)*.938)
		var b0 := Vector3(cos(b)*.938,.04,sin(b)*.938)
		var a1 := Vector3(cos(a)*.938,.325,sin(a)*.938)
		var b1 := Vector3(cos(b)*.938,.325,sin(b)*.938)
		tri(faces,a0,a1,b0)
		tri(faces,b0,a1,b1)
	surface(tile,"StoneSlab",faces,"StoneDark")
	var bevel: Array = []
	var outline: Array = []
	for i in range(7):
		var a := PI/6+i*TAU/6
		outline.append(Vector3(cos(a)*.924,.356,sin(a)*.924))
		if i < 6:
			var b := a+TAU/6
			var p := Vector3(cos(a)*.938,.325,sin(a)*.938)
			var q := Vector3(cos(b)*.938,.325,sin(b)*.938)
			var s := Vector3(cos(a)*.928,.35,sin(a)*.928)
			var t := Vector3(cos(b)*.928,.35,sin(b)*.928)
			tri(bevel,p,s,q)
			tri(bevel,q,s,t)
	surface(tile,"GroundTransition",bevel,terrain_mat)
	var sacred := (row == 6 and column == 6)
	disk(tile,"WalkingSurface",.928,.35,"Jade" if sacred else terrain_mat)
	line(tile,"HexBoundary",outline,.008,"Spirit" if sacred else "Seam")
	if sacred:
		circle(tile,"MoonwellSeal",Vector3(0,.37,0),.59,"Spirit",.016)
		circle(tile,"InnerSeal",Vector3(0,.37,0),.43,"Spirit",.009)
		for i in range(6):
			var a := i*TAU/6
			line(tile,"PetalRune%d"%i,[Vector3.ZERO+Vector3(0,.37,0),Vector3(cos(a-.3)*.28,.37,sin(a-.3)*.28),Vector3(cos(a)*.39,.37,sin(a)*.39),Vector3(cos(a+.3)*.28,.37,sin(a+.3)*.28),Vector3(0,.37,0)],.012,"Spirit")
	elif rng.randf() < .55:
		var a := rng.randf()*TAU
		line(tile,"HairlineFracture",[Vector3(cos(a)*.87,.354,sin(a)*.87),Vector3(cos(a)*.56,.354,sin(a)*.56),Vector3(cos(a+.3)*.32,.354,sin(a+.3)*.32)],.009,"StoneDark")
	if terrain_mat in ["Meadow", "MeadowLight", "MossPaving"] and rng.randf()<.65:
		var a := rng.randf()*TAU
		rock(tile,"EdgeMoss",Vector3(cos(a)*.74,.355,sin(a)*.74),Vector3(.24,.012,.17),"Moss")
	var collision := StaticBody3D.new()
	collision.name = "TileBody"
	var shape := CollisionShape3D.new()
	shape.name = "HexCollision"
	var convex := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for y in [.04,.35]:
		for i in range(6):
			var a := PI/6+i*TAU/6
			points.append(Vector3(cos(a)*.92,y,sin(a)*.92))
	convex.points = points
	shape.shape = convex
	collision.add_child(shape)
	tile.add_child(collision)

func build_battlefield() -> void:
	var root := Node3D.new()
	root.name = "MoonwellCourtyard"
	root.set_meta("description","A 14 × 14 battlefield embedded in a moonlit sanctuary landscape. All 196 hexes and surrounding terrain are editable scene nodes.")
	var board := node(root,"BattlefieldGrid")
	board.set_meta("rows",GRID_SIZE)
	board.set_meta("columns",GRID_SIZE)
	for row in range(GRID_SIZE):
		for column in range(GRID_SIZE):
			make_tile(board,row,column)
	var land := node(root,"IslandFoundation")
	var rim := ISLAND_RIM
	var top_faces: Array = []
	var side_faces: Array = []
	var base_faces: Array = []
	for i in range(rim.size()):
		var p: Vector2 = rim[i] * LANDSCAPE_SCALE
		var q: Vector2 = rim[(i+1)%rim.size()] * LANDSCAPE_SCALE
		var a := Vector3(p.x,-.08,p.y)
		var b := Vector3(q.x,-.08,q.y)
		var c := Vector3(p.x*.97,-.65,p.y*.97)
		var d := Vector3(q.x*.97,-.65,q.y*.97)
		var e := Vector3(p.x*.89,-1.7,p.y*.89)
		var f := Vector3(q.x*.89,-1.7,q.y*.89)
		tri(top_faces,Vector3(0,-.08,0),b,a)
		tri(side_faces,a,b,c)
		tri(side_faces,b,d,c)
		tri(base_faces,c,d,e)
		tri(base_faces,d,f,e)
	surface(land,"MossyIslandTop",top_faces,"Earth")
	surface(land,"UpperRockStratum",side_faces,"StoneDark")
	surface(land,"ChiseledBedrock",base_faces,"Foundation")
	# Ground-level stepping paths and planted margins merge into the playable field.
	var sanctuary := node(root,"NorthernSanctuary")
	place(sanctuary,"gate","MoonGate",Vector3(0,0,-10.3))
	for side in [-1,1]:
		place(sanctuary,"lantern","GateLantern%d"%side,Vector3(side*3.8,0,-9.7),0,.85)
		place(sanctuary,"tree","GateCherry%d"%side,Vector3(side*8.2,0,-10.8),side*.4,.65)
	var water := node(root,"LotusPools")
	var pond := node(water,"WestPool",Vector3(-14.5,-.02,4.0))
	box(pond,"StillWater",Vector3.ZERO,Vector3(2.65,.055,6.7),"Water")
	for side in [-1,1]:
		for i in range(13):
			rock(pond,"BankStone%d_%d"%[side,i],Vector3(side*1.35,.02,-3.4+i*.55),Vector3(.26,.13,.3),"Moss" if i%3 else "StoneDark")
	for i in range(7):
		place(pond,"lotus","Lotus%d"%i,Vector3(rng.randf_range(-.9,.9),.05,rng.randf_range(-2.8,2.8)),0,.75)
	make_bridge(root)
	root.get_node("GardenBridge").position = Vector3(-14.3,.08,2.0)
	var margins := node(root,"GroundMargins")
	for side in [-1,1]:
		for i in range(16):
			var z := -8.0+i*1.25
			var p := Vector3(side*(12.05+rng.randf()*.5),-.055,z+rng.randf_range(-.3,.3))
			rock(margins,"CreepingMoss%d_%d"%[side,i],p,Vector3(rng.randf_range(.35,.7),.025,rng.randf_range(.35,.8)),"MossPaving" if i%2 else "Meadow")
	for i in range(16):
		var x := -10.5+i*1.4
		for side in [-1,1]:
			var z := -8.8 if side < 0 else 11.6
			rock(margins,"GroundCover%d_%d"%[side,i],Vector3(x,-.04,z),Vector3(.7,.035,.38),"MeadowLight" if i%3 else "MossPaving")
	for i in range(10):
		var p := Vector3(-12.1-i*.22,-.015,2.0)
		box(margins,"WestPath%d"%i,p,Vector3(.36,.09,.65),"MossPaving")
	make_expanded_landscape(root)
	make_atmosphere(root)
	make_camera(root)
	var skirmish := preload("res://scenes/units/skirmish.tscn").instantiate()
	root.add_child(skirmish)
	var packed := save_scene(root,"res://scenes/battlefields/moonwell_courtyard.tscn")
	print("Saved Moonwell: 196 ground-level playable hexes, editable terraces, wetlands and shrines.")

func make_bridge(root: Node3D) -> void:
	var bridge := node(root,"GardenBridge",Vector3(-7.0,.18,1.0))
	for i in range(11):
		var x := (i-5)*.29
		var y := .28*(1.0-pow(x/1.7,2))
		box(bridge,"DeckPlank%02d"%i,Vector3(x,y,0),Vector3(.27,.12,1.35),"WoodLight")
	for side in [-1,1]:
		var rail: Array = []
		for i in range(5):
			var x := (i-2)*.72
			var y := .28*(1.0-pow(x/1.7,2))
			box(bridge,"Post%d_%d"%[side,i],Vector3(x,y+.38,side*.67),Vector3(.1,.9,.1),"Wood")
			rock(bridge,"Cap%d_%d"%[side,i],Vector3(x,y+.86,side*.67),Vector3(.085,.085,.085),"Gold")
			rail.append(Vector3(x,y+.65,side*.67))
		line(bridge,"ArchedRail%d"%side,rail,.055,"WoodLight")

func make_atmosphere(root: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "MoonlitAtmosphere"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101e30")
	env.background_energy_multiplier = 0.22
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9ac4dd")
	env.ambient_light_energy = .38
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = .7
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.4
	world.environment = env
	root.add_child(world)
	var key := DirectionalLight3D.new()
	key.name = "Moonlight"
	key.rotation_degrees = Vector3(-52,-28,0)
	key.light_color = Color("b8d8f5")
	key.light_energy = .7
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 100
	root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "SoftDuskFill"
	fill.rotation_degrees = Vector3(-28,130,0)
	fill.light_color = Color("d5a3c0")
	fill.light_energy = .18
	root.add_child(fill)

func make_camera(root: Node3D) -> void:
	var rig := node(root,"CameraRig")
	rig.set_script(load("res://scripts/battlefield_camera.gd"))
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 39.0
	camera.far = 150
	camera.current = true
	rig.add_child(camera)
	camera.position = Vector3(24.3,33.0,37.4)
	camera.basis = Basis.looking_at(Vector3(0,1.0,-1.8)-camera.position)
	var hud := CanvasLayer.new()
	hud.name = "CourtyardLabels"
	hud.set_script(load("res://scripts/courtyard_labels.gd"))
	root.add_child(hud)

# The expanded landscape is baked to ordinary scene nodes by this authoring tool.
# Nothing here runs in the game; each named terrace, rock and plant can be edited.
func terrace(parent: Node, title: String, center: Vector3, radius: Vector2, height: float) -> Node3D:
	var n := node(parent, title, center)
	var rings: Array = []
	for layer in range(3):
		var points: Array = []
		for i in range(10):
			var a := TAU * i / 10.0
			var r := 1.0 + sin(i * 13.7) * .10
			var inset: float = [1.1, 1.0, .92][layer]
			points.append(Vector3(cos(a)*radius.x*r*inset, [-.12, height*.78, height][layer], sin(a)*radius.y*r*inset))
		rings.append(points)
	for layer in range(2):
		var faces: Array = []
		for i in range(10):
			var j := (i+1)%10
			tri(faces, rings[layer][i], rings[layer+1][i], rings[layer][j])
			tri(faces, rings[layer][j], rings[layer+1][i], rings[layer+1][j])
		surface(n, "Bedrock" if layer == 0 else "WeatheredRim", faces, "Cliff" if layer == 0 else "CliffLight")
	var top: Array = []
	for i in range(10):
		tri(top, Vector3(0,height,0), rings[2][(i+1)%10], rings[2][i])
	surface(n,"MossyCrown",top,"Moss")
	for i in range(8):
		if i == 2 and title in ["EasternCascadePlateau", "CascadeShelf"]:
			continue # Keep the spring and spillway free of crown boulders.
		var a := TAU*i/8
		var p := Vector3(cos(a)*radius.x*.86, height-.12, sin(a)*radius.y*.86)
		rock(n,"CrownBoulder%02d"%i,p,Vector3(.65,.3,.48),"Moss" if i%3 else "Stone")
	# Offset facets, shelves and vines break up the large, smooth cliff faces.
	for i in range(16):
		var a := TAU*i/16
		var h := height*(.4+.4*(sin(i*2.8)*.5+.5))
		var p := Vector3(cos(a)*radius.x*.94,h*.5,sin(a)*radius.y*.94)
		var buttress := cylinder(n,"ErodedButtress%02d"%i,p,.55,.32,h,"CliffLight" if i%3 else "Cliff",5)
		buttress.rotation.y = a
		rock(n,"MossShelf%02d"%i,p+Vector3(0,h*.5,0),Vector3(.46,.10,.43),"Moss")
		if i%2 == 0:
			var start := Vector3(cos(a)*radius.x*.9,height,sin(a)*radius.y*.9)
			line(n,"CliffVine%02d"%i,[start,start+Vector3(.05,-.45,.12),start+Vector3(.12,-minf(height*.55,1.4),.15)],.035,"Leaf")
	return n

func ring_mesh(parent: Node, title: String, center: Vector3, radius: float, thickness: float, mat: String) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius-thickness
	torus.outer_radius = radius+thickness
	torus.rings = 40
	torus.ring_segments = 6
	return mesh(parent,title,torus,mat,center)

func fern(parent: Node, title: String, pos: Vector3, size := 1.0) -> void:
	var n := node(parent,title,pos)
	n.scale *= size
	for i in range(7):
		var a := i*TAU/7
		var d := Vector3(cos(a),0,sin(a))
		var side := Vector3(-sin(a),0,cos(a))*.12
		var mid := d*.27+Vector3.UP*.48
		var tip := d*.65+Vector3.UP*.28
		surface(n,"Frond%d"%i,[Vector3.ZERO,mid+side,tip,Vector3.ZERO,tip,mid-side],"Grass" if i%2 else "LeafLight")

func banner(parent: Node, title: String, pos: Vector3, yaw := 0.0) -> void:
	var n := node(parent,title,pos)
	n.rotation.y = yaw
	for side in [-1,1]:
		cylinder(n,"StoneFoot%d"%side,Vector3(side*1.55,.18,0),.32,.25,.36,"StoneDark")
		rod(n,"Pole%d"%side,Vector3(side*1.55,.3,0),Vector3(side*1.55,3.5,0),.055,"Wood")
		rock(n,"Finial%d"%side,Vector3(side*1.55,3.6,0),Vector3(.12,.2,.12),"Gold")
	line(n,"Suspension",[Vector3(-1.55,3.45,0),Vector3(0,3.15,0),Vector3(1.55,3.45,0)],.025,"Gold")
	for i in range(3):
		var x := (i-1)*.85
		var y := 3.18+absf(x)*.14
		var cloth := [Vector3(x-.25,y,0),Vector3(x+.25,y,0),Vector3(x+.27,y-1.25,.14),Vector3(x-.25,y,0),Vector3(x+.27,y-1.25,.14),Vector3(x-.18,y-1.45,.10)]
		var flag := surface(n,"HangingSilk%d"%i,cloth,"Cloth")
		var m: StandardMaterial3D = flag.material_override.duplicate()
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		flag.material_override = m
		for j in range(3):
			var seal := box(n,"GoldStitch%d_%d"%[i,j],Vector3(x,y-.35-j*.25,.09),Vector3(.11,.16,.025),"Gold")
			seal.rotation.z = PI/4

func brazier(parent: Node, title: String, pos: Vector3) -> void:
	var n := node(parent,title,pos)
	cylinder(n,"Plinth",Vector3(0,.15,0),.52,.43,.3,"StoneDark")
	cylinder(n,"Stem",Vector3(0,.55,0),.24,.16,.65,"Gold")
	cylinder(n,"BronzeBowl",Vector3(0,.94,0),.23,.52,.35,"Gold")
	cylinder(n,"Coals",Vector3(0,1.11,0),.43,.40,.04,"Amber")
	for i in range(5):
		var a := i*TAU/5
		var flame := rock(n,"SpiritFlame%d"%i,Vector3(cos(a)*.19,1.4,sin(a)*.19),Vector3(.12,.43+i*.04,.13),"Amber")
		flame.rotation.z = sin(a)*.3

func pavilion(parent: Node, title: String, pos: Vector3, size := 1.0) -> void:
	var n := node(parent,title,pos)
	n.scale *= size
	box(n,"Foundation",Vector3(0,.18,0),Vector3(4.5,.36,3.7),"StoneDark")
	box(n,"StoneFloor",Vector3(0,.41,0),Vector3(4.7,.14,3.9),"StoneLight")
	for x in [-1,1]:
		for z in [-1,1]:
			var p := Vector3(x*1.75,1.85,z*1.35)
			cylinder(n,"Pillar%d_%d"%[x,z],p,.13,.11,2.8,"Wood")
			cylinder(n,"GiltFoot%d_%d"%[x,z],Vector3(p.x,.63,p.z),.22,.19,.3,"Gold")
	box(n,"LintelFront",Vector3(0,3.15,1.35),Vector3(3.8,.24,.18),"WoodLight")
	box(n,"LintelRear",Vector3(0,3.15,-1.35),Vector3(3.8,.24,.18),"WoodLight")
	var r := roof(n,"SweptRoof",Vector3(0,3.3,0),2.6,1.05)
	r.scale.z = .8
	roof(n,"UpperRoof",Vector3(0,4.15,0),1.45,.85)
	place(n,"lantern","OfferingLantern",Vector3(0,.48,0),0,.68)
	for side in [-1,1]:
		box(n,"Balustrade%d"%side,Vector3(side*1.8,1,-.2),Vector3(.12,.12,2.7),"WoodLight")
		for j in range(6):
			box(n,"RailSpindle%d_%d"%[side,j],Vector3(side*1.8,.75,-1.25+j*.43),Vector3(.07,.55,.07),"Wood")

func waterfall(parent: Node, title: String, pos: Vector3, height: float, width: float) -> void:
	var n := node(parent,title,pos)
	# Opaque ribbons avoid sorting artifacts in the project's Compatibility renderer.
	for i in range(5):
		var x := (i-2)*width/5
		var z := .07*sin(i*1.8)
		box(n,"FallingRibbon%d"%i,Vector3(x,height*.5,z),Vector3(width/5*.94,height,.045),"FallingWater" if i%2 else "Ripple")
		rod(n,"Whitewater%d"%i,Vector3(x,height,.04+z),Vector3(x+.04,.12,.15+z),.012,"Foam")
	for i in range(3):
		var ripple := ring_mesh(n,"SplashRing%d"%i,Vector3(0,.035+i*.012,.3),width*.45+i*.26,.02,"Foam")
		ripple.scale.z = .42
	for i in range(7):
		rock(n,"Spray%d"%i,Vector3(rng.randf_range(-width*.6,width*.6),rng.randf_range(.05,.42),rng.randf_range(.05,.6)),Vector3(.04,.07,.04),"Foam")

func make_expanded_landscape(root: Node3D) -> void:
	var terrain := node(root,"HighlandTerraces")
	terrace(terrain,"WesternGardenTerrace",Vector3(-15.5,0,-4.5),Vector2(2.4,4.1),1.0)
	terrace(terrain,"WesternUpperTerrace",Vector3(-13.1,0,-12.6),Vector2(3.2,2.8),2.6)
	terrace(terrain,"TemplePlateau",Vector3(-5.8,0,-15.8),Vector2(5.8,3.0),5.0)
	terrace(terrain,"EasternCascadePlateau",Vector3(13.6,0,-13.5),Vector2(3.0,3.9),4.4)
	terrace(terrain,"CascadeShelf",Vector3(14.5,0,-8.0),Vector2(1.7,2.1),1.8)
	# Narrow, irregular columns read as eroded mountain strata, rather than walls.
	for i in range(27):
		var x := -16.0+i*1.22
		var z := -15.8 + sin(i*.8)*.65
		var h := 3.8 + (sin(i*1.9)+1)*2.3
		if x > -10 and x < -.5:
			h = 4.3
		var column := cylinder(terrain,"RidgeColumn%02d"%i,Vector3(x,h*.5-.1,z),.9,.57,h,"Cliff" if i%3 else "CliffLight",5)
		column.rotation.y = i*.7
		rock(terrain,"RidgeMoss%02d"%i,Vector3(x,h-.1,z),Vector3(.62,.13,.66),"Moss")
	# Separated tall peaks give the rear silhouette the concept's vertical rhythm.
	for i in range(6):
		var x := -14+i*5.1
		var h := 7.5+sin(i*2.3)*1.8
		var peak := cylinder(terrain,"DistantSpire%d"%i,Vector3(x,h*.5,-17),1.0,.35,h,"Cliff",5)
		peak.rotation.z = .06*sin(i)
		rock(terrain,"PeakCap%d"%i,Vector3(x,h,-17),Vector3(.45,.12,.46),"Moss")
	var shrines := node(root,"HighlandShrines")
	pavilion(shrines,"HilltopTemple",Vector3(-5.7,5,-15.8),1.22)
	pavilion(shrines,"EastTeaPavilion",Vector3(14,4.4,-13.8),.85)
	place(shrines,"tree","HilltopCherry",Vector3(-12.4,2.6,-13.3),.6,.9)
	place(shrines,"tree","CascadeCherry",Vector3(11.8,4.4,-14.1),1,.8)
	# Broad stone stairs link the main gate to the elevated sanctuary.
	for i in range(19):
		var y := (i+1)*5.0/19
		box(shrines,"PilgrimStair%02d"%i,Vector3(-5.7,y*.5,-9.4-i*.34),Vector3(2.1,y,.4),"Stone" if i%2 else "StoneLight")
		if i%4 == 0:
			for side in [-1,1]:
				box(shrines,"StairPost%d_%d"%[i,side],Vector3(-5.7+side*1.25,y+.35,-9.4-i*.34),Vector3(.24,.7,.24),"StoneDark")
	for side in [-1,1]:
		place(shrines,"lantern","TempleLantern%d"%side,Vector3(-5.7+side*2.0,5,-13.8),0,.8)
	banner(shrines,"TemplePrayerSilks",Vector3(-9,5,-16.1),.2)
	brazier(shrines,"WesternOffering",Vector3(-3.2,0,-9.7))
	brazier(shrines,"EasternOffering",Vector3(3.2,0,-9.7))

	var wetlands := node(root,"EasternWetlands")
	# An irregular shoreline and winding stream replace the tiny rectangular pond edge.
	var shore := [Vector2(12.6,-9.6),Vector2(15.7,-9.6),Vector2(16.4,-5),Vector2(15.8,-1),Vector2(17.1,2),Vector2(16,8),Vector2(13.6,12.2),Vector2(12.4,11.7),Vector2(12.8,8.2),Vector2(12.3,5.1),Vector2(12.6,3),Vector2(12.5,-1.9)]
	var faces: Array = []
	var polygon := PackedVector2Array(shore)
	var indices := Geometry2D.triangulate_polygon(polygon)
	for i in range(0,indices.size(),3):
		var a := polygon[indices[i]]
		var b := polygon[indices[i+1]]
		var c := polygon[indices[i+2]]
		tri(faces,Vector3(a.x,-.015,a.y),Vector3(c.x,-.015,c.y),Vector3(b.x,-.015,b.y))
	surface(wetlands,"LotusLakeAndStream",faces,"Water")
	for i in range(shore.size()):
		var a: Vector2 = shore[i]
		var b: Vector2 = shore[(i+1)%shore.size()]
		for j in range(5):
			var p := a.lerp(b,j/5.0)
			rock(wetlands,"ShoreRock%d_%d"%[i,j],Vector3(p.x,.02,p.y),Vector3(.45,.22,.39),"StoneDark" if j%3 else "Moss")
	for i in range(25):
		var p := Vector3(rng.randf_range(13,15.8),.025,rng.randf_range(1,10))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),polygon):
			continue
		place(wetlands,"lotus","LotusCluster%02d"%i,p,rng.randf()*TAU,rng.randf_range(.7,1.25))
		if i%3 == 0:
			ring_mesh(wetlands,"WaterRipple%02d"%i,p,.65,.008,"Ripple")
		cylinder(wetlands,"LilyPad%02d"%i,p+Vector3(.5,0,.1),.24,.24,.02,"Leaf",10)
	# Water starts in a visible upper basin and falls over two successive cliff ledges.
	box(wetlands,"UpperSpring",Vector3(14.4,4.42,-10.7),Vector3(1.7,.04,3.0),"Water")
	box(wetlands,"MiddleBasin",Vector3(14.4,1.82,-6.9),Vector3(2.1,.04,2.8),"Water")
	for side in [-1,1]:
		for i in range(5):
			rock(wetlands,"SpringBank%d_%d"%[side,i],Vector3(14.4+side*.98,4.4,-11.8+i*.6),Vector3(.22,.18,.38),"Moss" if i%2 else "StoneDark")
		for i in range(4):
			rock(wetlands,"ShelfBank%d_%d"%[side,i],Vector3(14.4+side*1.16,1.8,-7.7+i*.65),Vector3(.22,.16,.36),"StoneDark")
	waterfall(wetlands,"UpperFalls",Vector3(14.4,1.84,-9.2),2.58,1.6)
	waterfall(wetlands,"LowerFalls",Vector3(14.4,.02,-5.5),1.8,1.9)
	# The second bridge crosses the stream between the shore paths.
	var crossing := node(wetlands,"StreamCrossing",Vector3(14.4,.12,-.4))
	make_bridge(crossing)
	var bridge := crossing.get_node("GardenBridge") as Node3D
	bridge.position = Vector3.ZERO
	bridge.scale = Vector3(1.0,1.25,1.2)
	for side in [-1,1]:
		place(wetlands,"lantern","BridgeLantern%d"%side,Vector3(14.4+side*.9,0,-1.5),0,.6)
	for i in range(9):
		var p := Vector3(12.6+i*.1,.04,6+i*.65)
		cylinder(wetlands,"WetlandSteppingStone%d"%i,p,.53,.51,.16,"Stone",6)

	var gardens := node(root,"OuterGardens")
	var trees := [Vector3(-16.0,1,-3),Vector3(-15.8,1,-6.5),Vector3(-14.2,2.6,-12.4),Vector3(17,0,-4),Vector3(-14.4,0,8.4),Vector3(7.2,0,15.3)]
	for i in range(trees.size()):
		place(gardens,"tree","CherryGrove%d"%i,trees[i],i*.7,.42 if i == 5 else .72+(i%3)*.14)
	var bamboo_positions := [Vector3(-17,1,-5),Vector3(-15,1,-7),Vector3(-16.5,0,1),Vector3(-16.5,0,4),Vector3(17.3,0,-2),Vector3(17.4,0,1),Vector3(16.6,0,7),Vector3(3,0,-14)]
	for i in range(bamboo_positions.size()):
		place(gardens,"bamboo","BambooThicket%d"%i,bamboo_positions[i],i*1.3,1.0+(i%3)*.2)
	var planted_boundary := PackedVector2Array()
	for point in ISLAND_RIM:
		planted_boundary.append(point * LANDSCAPE_SCALE * .96)
	for i in range(100):
		var p := Vector3(rng.randf_range(-16,16),0,rng.randf_range(-11,14))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),planted_boundary):
			continue
		# Keep the tactical board, shore water and terraces clear of scattered props.
		if (absf(p.x)<12.7 and p.z>-9.4 and p.z<12.2) or (p.x>12 and p.z<12) or (p.x<-12 and p.z<0) or (absf(p.x)<2 and p.z>5):
			continue
		fern(gardens,"GroundFern%03d"%i,p,rng.randf_range(.65,1.5))
		if i%3 == 0:
			rock(gardens,"MossyOutcrop%03d"%i,p,Vector3(.65,.35,.5),"Moss")
	for i in range(22):
		var p := Vector3(-16.5+rng.randf()*2,1.03,-7+rng.randf()*6)
		fern(gardens,"TerraceFern%02d"%i,p,.8)
		if i%2 == 0:
			rock(gardens,"BlossomCarpet%02d"%i,p,Vector3(.16,.025,.13),"BlossomDark")
	# A worn approach remains low in the foreground, preserving the board silhouette.
	var approach := node(root,"PilgrimApproach")
	for i in range(13):
		var z := 11.9+i*.26
		box(approach,"OldFlagstone%02d"%i,Vector3(sin(i*.35)*.35,.03,z),Vector3(2.25,.10,.24),"Stone" if i%3 else "StoneLight")
		if i in [4,12]:
			for side in [-1,1]:
				place(approach,"lantern","PathLight%d_%d"%[i,side],Vector3(side*1.9,0,z+.6),0,.38)
	banner(approach,"EntryPrayerFlags",Vector3(-3.8,0,15.3),-.2)
	banner(approach,"EasternPrayerFlags",Vector3(4,0,15.3),.3)
	approach.get_node("EntryPrayerFlags").scale = Vector3.ONE*.65
	approach.get_node("EasternPrayerFlags").scale = Vector3.ONE*.65
	make_ruins(root)

func make_ruins(root: Node3D) -> void:
	var ruins := node(root,"WesternRuins",Vector3(-14,0,10.4))
	ruins.scale = Vector3.ONE*.6
	for i in range(9):
		var slab := box(ruins,"BrokenPaving%d"%i,Vector3((i%3-1)*1.1,.04,(i/3-1)*1.05),Vector3(1,.17,.94),"StoneDark" if i%2 else "Stone")
		slab.rotation.y = rng.randf_range(-.14,.14)
	for side in [-1,1]:
		var pillar := node(ruins,"CarvedPillar%d"%side,Vector3(side*2.1,0,-.4))
		box(pillar,"Foot",Vector3(0,.2,0),Vector3(1.2,.4,1.2),"StoneDark")
		box(pillar,"Shaft",Vector3(0,1.6,0),Vector3(.7,2.7,.8),"Stone")
		for y in [.5,2.3,2.9]:
			box(pillar,"Collar%s"%y,Vector3(0,y,0),Vector3(.9,.15,1),"StoneLight")
		for j in range(3):
			var glyph := box(pillar,"InsetRune%d"%j,Vector3(0,1+j*.46,.411),Vector3(.18,.24,.02),"SpiritDim")
			glyph.rotation.z = PI/4
		rock(pillar,"Overgrowth",Vector3(.1,3.04,0),Vector3(.55,.12,.54),"Moss")
		for j in range(4):
			line(pillar,"HangingVine%d"%j,[Vector3((j-1.5)*.17,3,.48),Vector3((j-1.5)*.17+.05,2.7,.49),Vector3((j-1.5)*.17,2.15-j*.15,.47)],.026,"Leaf")
	var fallen := box(ruins,"FallenLintel",Vector3(.4,.36,-1.7),Vector3(3.6,.65,.9),"Stone")
	fallen.rotation = Vector3(.1,.22,-.12)
	var monolith := rock(ruins,"SpiritMonolith",Vector3(0,1.25,-.5),Vector3(.72,1.35,.48),"StoneDark")
	monolith.rotation = Vector3.ZERO
	var spiral: Array = []
	for i in range(25):
		var t := i/24.0
		spiral.append(Vector3(sin(t*TAU*1.5)*.22,.55+t*1.45,.005))
	line(ruins,"MonolithInscription",spiral,.023,"Spirit")
	ring_mesh(ruins,"OfferingCircle",Vector3(0,.15,1),.9,.018,"SpiritDim")
	place(ruins,"lantern","RuinLantern",Vector3(-2.7,0,1.4),0,.7)
	for i in range(12):
		var a := i*TAU/12
		fern(ruins,"ReclaimedFern%d"%i,Vector3(cos(a)*2.9,0,sin(a)*2.5),.8)
