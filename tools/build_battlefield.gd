extends SceneTree
## Rebuild the authored courtyard: godot --headless --path . --script tools/build_battlefield.gd
## Generated scenes contain ordinary, individually editable Godot nodes.

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
	material("Earth", "344e50")
	material("Moss", "537568")
	material("MossLight", "8aab75")
	material("Jade", "30736c")
	material("Leaf", "3f7967")
	material("LeafLight", "73a378")
	material("Bamboo", "4a8172")
	material("Wood", "452f40")
	material("WoodLight", "86585a")
	material("Roof", "254e60", 0.0, 0.22)
	material("Gold", "cca76c", 0.0, 0.5)
	material("Seam", "a6a081", 0.1)
	material("Cloth", "ab5265")
	material("Blossom", "d887b9")
	material("BlossomLight", "f4bbd7")
	material("BlossomDark", "ac609d")
	material("Water", "286975", 0.12, 0.5).roughness = 0.2
	material("Ripple", "70c9c7", 0.5)
	material("Spirit", "6ef5ed", 2.0)
	material("SpiritDim", "338d96", 0.8)
	material("Amber", "ffc97b", 3.0)
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
	light.light_energy = 2.0
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

func make_tile(parent: Node, row: int, column: int) -> void:
	const R := 0.94
	var pos := Vector3((column-3)*sqrt(3.0)*R + (row%2)*sqrt(3.0)*R*.5-sqrt(3.0)*R*.25,0,(row-3)*1.5*R)
	var tile := node(parent,"Hex_%d_%d"%[row+1,column+1],pos)
	tile.set_meta("row",row)
	tile.set_meta("column",column)
	tile.set_meta("axial_q",column - (row - row%2)/2)
	tile.set_meta("axial_r",row)
	var faces: Array = []
	for i in range(6):
		var a := PI/6+i*TAU/6
		var b := PI/6+(i+1)*TAU/6
		var a0 := Vector3(cos(a)*.925,.04,sin(a)*.925)
		var b0 := Vector3(cos(b)*.925,.04,sin(b)*.925)
		var a1 := Vector3(cos(a)*.925,.29,sin(a)*.925)
		var b1 := Vector3(cos(b)*.925,.29,sin(b)*.925)
		tri(faces,a0,a1,b0)
		tri(faces,b0,a1,b1)
	surface(tile,"StoneSlab",faces,"StoneDark")
	var bevel: Array = []
	var outline: Array = []
	for i in range(7):
		var a := PI/6+i*TAU/6
		outline.append(Vector3(cos(a)*.884,.355,sin(a)*.884))
		if i < 6:
			var b := a+TAU/6
			var p := Vector3(cos(a)*.925,.29,sin(a)*.925)
			var q := Vector3(cos(b)*.925,.29,sin(b)*.925)
			var s := Vector3(cos(a)*.89,.35,sin(a)*.89)
			var t := Vector3(cos(b)*.89,.35,sin(b)*.89)
			tri(bevel,p,s,q)
			tri(bevel,q,s,t)
	surface(tile,"WornBevel",bevel,"StoneLight")
	var sacred := (row == 3 and column == 3)
	disk(tile,"WalkingSurface",.89,.35,"Jade" if sacred else "Paving%d"%rng.randi_range(0,5))
	line(tile,"HexBoundary",outline,.009,"Spirit" if sacred else "Seam")
	if sacred:
		circle(tile,"MoonwellSeal",Vector3(0,.37,0),.59,"Spirit",.016)
		circle(tile,"InnerSeal",Vector3(0,.37,0),.43,"Spirit",.009)
		for i in range(6):
			var a := i*TAU/6
			line(tile,"PetalRune%d"%i,[Vector3.ZERO+Vector3(0,.37,0),Vector3(cos(a-.3)*.28,.37,sin(a-.3)*.28),Vector3(cos(a)*.39,.37,sin(a)*.39),Vector3(cos(a+.3)*.28,.37,sin(a+.3)*.28),Vector3(0,.37,0)],.012,"Spirit")
	elif rng.randf() < .55:
		var a := rng.randf()*TAU
		line(tile,"HairlineFracture",[Vector3(cos(a)*.87,.354,sin(a)*.87),Vector3(cos(a)*.56,.354,sin(a)*.56),Vector3(cos(a+.3)*.32,.354,sin(a+.3)*.32)],.009,"StoneDark")
	if (row==0 or row==6 or column==0 or column==6) and rng.randf()<.65:
		var a := rng.randf()*TAU
		rock(tile,"EdgeMoss",Vector3(cos(a)*.74,.355,sin(a)*.74),Vector3(.21,.016,.12),"Moss")
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
	root.set_meta("description","A 7 × 7 moonlit shrine courtyard. All tiles and scenery are editable scene nodes.")
	var board := node(root,"Board_7x7")
	for row in range(7):
		for column in range(7):
			make_tile(board,row,column)
	var land := node(root,"IslandFoundation")
	var rim := [Vector2(-8.8,-6.6),Vector2(-6.8,-9.2),Vector2(5.4,-9.7),Vector2(8.9,-6.8),Vector2(9.4,3.7),Vector2(7.1,7.8),Vector2(3.6,8.4),Vector2(-6.2,7.9),Vector2(-9.3,4.5)]
	var top_faces: Array = []
	var side_faces: Array = []
	var base_faces: Array = []
	for i in range(rim.size()):
		var p: Vector2 = rim[i]
		var q: Vector2 = rim[(i+1)%rim.size()]
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
	box(land,"CourtyardFoundation",Vector3(0,-.02,0),Vector3(11.7,.14,10.5),"StoneDark")
	var water := node(root,"LotusPools")
	for side in [-1,1]:
		var pond := node(water,"WestPool" if side<0 else "EastPool",Vector3(side*7.05,-.02,2.05))
		box(pond,"StillWater",Vector3.ZERO,Vector3(2.65,.055,6.7),"Water")
		for i in range(13):
			var z := -3.4 + i*.55
			rock(pond,"BankStone%d"%i,Vector3(side*1.35,.02,z),Vector3(.36,.22,.36),"StoneDark" if i%3 else "Moss")
		for j in range(5):
			var p := Vector3(rng.randf_range(-.9,.9),.05,rng.randf_range(-2.8,2.8))
			place(pond,"lotus","Lotus%d"%j,p,0,rng.randf_range(.65,1.05))
			circle(pond,"Ripple%d"%j,p-Vector3(0,.02,0),.45+j*.04,"Ripple",.008,false,24)
		for j in range(8):
			cylinder(pond,"FloatingPad%d"%j,Vector3(rng.randf_range(-1.0,1.0),.04,rng.randf_range(-3.0,3.0)),.17,.17,.02,"Leaf",9)
	var sanctuary := node(root,"NorthernSanctuary")
	place(sanctuary,"gate","MoonGate",Vector3(0,0,-7.05))
	for side in [-1,1]:
		place(sanctuary,"lantern","GateLantern%d"%side,Vector3(side*3.8,.0,-6.0),0,1.05)
		place(root,"lantern","CourtyardLantern%d"%side,Vector3(side*5.7,0,5.65),0,.88)
	var garden := node(root,"Gardens")
	place(garden,"tree","AncientCherry",Vector3(-6.7,0,-4.6),-.2,1.1)
	place(garden,"tree","YoungCherry",Vector3(6.65,0,-6.0),.5,.72)
	place(garden,"bamboo","EastBamboo",Vector3(8.1,0,-2.1),.1)
	place(garden,"bamboo","WestBamboo",Vector3(-8.0,0,1.2),1.4,.8)
	place(garden,"bamboo","RearBamboo",Vector3(4.9,0,-8.1),.3,.85)
	for i in range(48):
		var side: int = -1 if i%2 else 1
		var x := side*rng.randf_range(6.0,8.6)
		var z := rng.randf_range(-7.3,6.4)
		if z > -1.5 and z < 5.3:
			x = side*rng.randf_range(8.4,8.8)
		var size := rng.randf_range(.22,.6)
		rock(garden,"WeatheredRock%02d"%i,Vector3(x,size*.15,z),Vector3(size,size*.65,size*.8),"Stone" if i%4 else "Moss")
		if i%2 == 0:
			rock(garden,"MossCap%02d"%i,Vector3(x,size*.65,z),Vector3(size*.7,.07,size*.6),"Moss")
	for i in range(26):
		var x := rng.randf_range(-7.8,7.8)
		var z := rng.randf_range(6.0,7.2) if i%2 else rng.randf_range(-8.8,-6.2)
		if abs(x)<3.4 and z<0:
			continue
		var tuft := node(garden,"Fern%02d"%i,Vector3(x,0,z))
		for j in range(5):
			var a := j*TAU/5
			var tip := Vector3(cos(a)*.36,.25+rng.randf()*.2,sin(a)*.36)
			rod(tuft,"Stem%d"%j,Vector3.ZERO,tip,.028,"MossLight",.002)
	for i in range(25):
		var p := Vector3(rng.randf_range(-7.2,-3.8),.38,rng.randf_range(-4.8,-1.7))
		rock(garden,"FallenPetal%02d"%i,p,Vector3(.055,.012,.036),"BlossomLight")
	var entrance := node(root,"SouthernApproach")
	for i in range(3):
		box(entrance,"EntrySlab%d"%i,Vector3(0,.02,5.65+i*.62),Vector3(2.1,.18,.52),"Stone")
		box(entrance,"EntryInlay%d"%i,Vector3(0,.115,5.65+i*.62),Vector3(.65,.012,.025),"Gold")
	for side in [-1,1]:
		var marker := node(entrance,"BoundaryMarker%d"%side,Vector3(side*2.0,0,6.8))
		box(marker,"Foot",Vector3(0,.1,0),Vector3(.65,.2,.65),"StoneDark")
		box(marker,"CarvedStone",Vector3(0,.46,0),Vector3(.4,.62,.36),"Stone")
		box(marker,"Cap",Vector3(0,.8,0),Vector3(.53,.1,.48),"StoneLight")
		var seal := box(marker,"JadeSeal",Vector3(0,.48,.185),Vector3(.15,.15,.025),"Jade")
		seal.rotation.z = PI/4
	make_bridge(root)
	make_atmosphere(root)
	make_camera(root)
	var skirmish := preload("res://scenes/units/skirmish.tscn").instantiate()
	root.add_child(skirmish)
	var packed := save_scene(root,"res://scenes/battlefields/moonwell_courtyard.tscn")
	print("Saved Moonwell Courtyard: 49 hexes, editable scenery, camera and lighting.")

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
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9ac4dd")
	env.ambient_light_energy = .38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
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
	key.light_energy = 1.1
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 55
	root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "SoftDuskFill"
	fill.rotation_degrees = Vector3(-28,130,0)
	fill.light_color = Color("d5a3c0")
	fill.light_energy = .28
	root.add_child(fill)

func make_camera(root: Node3D) -> void:
	var rig := node(root,"CameraRig")
	rig.set_script(load("res://scripts/battlefield_camera.gd"))
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.5
	camera.far = 150
	camera.current = true
	rig.add_child(camera)
	camera.position = Vector3(15.3,21.0,23.8)
	camera.basis = Basis.looking_at(Vector3(0,.6,-.6)-camera.position)
	var hud := CanvasLayer.new()
	hud.name = "CourtyardLabels"
	hud.set_script(load("res://scripts/courtyard_labels.gd"))
	root.add_child(hud)
