extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
## Scene assembly: roots the playable field, island, landscape features,
## atmosphere, camera and starting encounter into the saved battlefield.

const StaticGeometry = preload("res://tools/static_geometry.gd")
const Field = preload("res://tools/battlefield/field.gd")
const Landscape = preload("res://tools/battlefield/landscape.gd")

static func build(ctx: AuthoringContext) -> void:
	var root := Node3D.new()
	root.name = "MoonwellCourtyard"
	root.set_meta("description","A 14 × 14 battlefield embedded in a moonlit sanctuary landscape. All 196 hexes and surrounding terrain are editable scene nodes.")
	var board := ctx.node(root,"BattlefieldGrid")
	board.set_meta("rows",Field.GRID_SIZE)
	board.set_meta("columns",Field.GRID_SIZE)
	for row in range(Field.GRID_SIZE):
		for column in range(Field.GRID_SIZE):
			Field.make_tile(ctx,board,row,column)
	var land := ctx.node(root,"IslandFoundation")
	var rim := Landscape.ISLAND_RIM
	var top_faces: Array = []
	var side_faces: Array = []
	var base_faces: Array = []
	for i in range(rim.size()):
		var p: Vector2 = rim[i] * Landscape.LANDSCAPE_SCALE
		var q: Vector2 = rim[(i+1)%rim.size()] * Landscape.LANDSCAPE_SCALE
		var a := Vector3(p.x,-.025,p.y)
		var b := Vector3(q.x,-.025,q.y)
		var c := Vector3(p.x*.97,-.65,p.y*.97)
		var d := Vector3(q.x*.97,-.65,q.y*.97)
		var e := Vector3(p.x*.89,-1.7,p.y*.89)
		var f := Vector3(q.x*.89,-1.7,q.y*.89)
		ctx.tri(top_faces,Vector3(0,-.025,0),b,a)
		ctx.tri(side_faces,a,b,c)
		ctx.tri(side_faces,b,d,c)
		ctx.tri(base_faces,c,d,e)
		ctx.tri(base_faces,d,f,e)
	ctx.surface(land,"MossyIslandTop",top_faces,"Terrain")
	ctx.surface(land,"UpperRockStratum",side_faces,"StoneDark")
	ctx.surface(land,"ChiseledBedrock",base_faces,"Foundation")
	# Ground-level stepping paths and planted margins merge into the playable field.
	var sanctuary := ctx.node(root,"NorthernSanctuary")
	ctx.place(sanctuary,"gate","MoonGate",Vector3(0,0,-10.3))
	for side in [-1,1]:
		ctx.place(sanctuary,"lantern","GateLantern%d"%side,Vector3(side*3.8,0,-9.7),0,.85)
		ctx.place(sanctuary,"tree","GateCherry%d"%side,Vector3(side*8.2,0,-10.8),side*.4,.65)
	var water := ctx.node(root,"LotusPools")
	var pond := ctx.node(water,"WestPool",Vector3(-14.5,-.02,4.0))
	ctx.box(pond,"StillWater",Vector3.ZERO,Vector3(2.65,.055,6.7),"Water")
	for side in [-1,1]:
		for i in range(13):
			ctx.rock(pond,"BankStone%d_%d"%[side,i],Vector3(side*1.35,.02,-3.4+i*.55),Vector3(.26,.13,.3),"Moss" if i%3 else "StoneDark")
	for i in range(7):
		ctx.place(pond,"lotus","Lotus%d"%i,Vector3(ctx.rng.randf_range(-.9,.9),.05,ctx.rng.randf_range(-2.8,2.8)),0,.75)
	Landscape.make_bridge(ctx,root)
	root.get_node("GardenBridge").position = Vector3(-14.3,.08,2.0)
	var margins := ctx.node(root,"GroundMargins")
	for side in [-1,1]:
		for i in range(16):
			var z := -8.0+i*1.25
			var p := Vector3(side*(12.05+ctx.rng.randf()*.5),-.055,z+ctx.rng.randf_range(-.3,.3))
			ctx.rock(margins,"CreepingMoss%d_%d"%[side,i],p,Vector3(ctx.rng.randf_range(.35,.7),.025,ctx.rng.randf_range(.35,.8)),"MossPaving" if i%2 else "Meadow")
	for i in range(16):
		var x := -10.5+i*1.4
		for side in [-1,1]:
			var z := -8.8 if side < 0 else 11.6
			ctx.rock(margins,"GroundCover%d_%d"%[side,i],Vector3(x,-.04,z),Vector3(.7,.035,.38),"MeadowLight" if i%3 else "MossPaving")
	for i in range(10):
		var p := Vector3(-12.1-i*.22,-.015,2.0)
		ctx.box(margins,"WestPath%d"%i,p,Vector3(.36,.09,.65),"MossPaving")
	Landscape.make_expanded_landscape(ctx,root)
	Landscape.make_sanctuary_details(ctx,root)
	StaticGeometry.optimize_details(root)
	make_atmosphere(ctx,root)
	make_camera(ctx,root)
	var skirmish := preload("res://scenes/units/skirmish.tscn").instantiate()
	root.add_child(skirmish)
	var packed := ctx.save_scene(root,"res://scenes/battlefields/moonwell_courtyard.tscn")
	print("Saved Moonwell: 196 ground-level playable hexes, editable terraces, wetlands and shrines.")

static func make_atmosphere(ctx: AuthoringContext, root: Node3D) -> void:
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

static func make_camera(ctx: AuthoringContext, root: Node3D) -> void:
	var rig := ctx.node(root,"CameraRig")
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
