extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
## Scene assembly: roots the playable field, island, landscape features,
## atmosphere, camera and starting encounter into the saved battlefield.

const StaticGeometry = preload("res://tools/static_geometry.gd")
const Field = preload("res://tools/battlefield/field.gd")
const Landscape = preload("res://tools/battlefield/landscape.gd")
const LevelPlan = preload("res://tools/battlefield/level_plan.gd")
const HexGrid = preload("res://scripts/hex_grid.gd")
const CameraScript = preload("res://scripts/battlefield_camera.gd")
const LabelsScript = preload("res://scripts/courtyard_labels.gd")
const SkirmishScene = preload("res://scenes/units/skirmish.tscn")

const FIELD_DESCRIPTION := "A %d × %d battlefield embedded in a moonlit sanctuary landscape. All %d hexes and surrounding terrain are editable scene nodes."
const SAVED_MESSAGE := "Saved Moonwell: %d ground-level playable hexes, editable terraces, wetlands and shrines."

static func build(ctx: AuthoringContext) -> void:
	var plan := LevelPlan.load_default()
	var root := Node3D.new()
	root.name = "MoonwellCourtyard"
	var cell_count := HexGrid.cell_count()
	root.set_meta("description", FIELD_DESCRIPTION % [HexGrid.SIZE, HexGrid.SIZE, cell_count])
	var board := ctx.node(root,"BattlefieldGrid")
	board.set_meta("rows",HexGrid.SIZE)
	board.set_meta("columns",HexGrid.SIZE)
	for row in range(HexGrid.SIZE):
		for column in range(HexGrid.SIZE):
			Field.make_tile(ctx,board,row,column)
	var land := ctx.node(root,"IslandFoundation")
	var foundation: Dictionary = plan.foundation
	var shore_height := float(foundation["shore_height"])
	var upper_stratum_y := float(foundation["upper_stratum_y"])
	var bedrock_y := float(foundation["bedrock_y"])
	var upper_stratum_inset := float(foundation["upper_stratum_inset"])
	var bedrock_inset := float(foundation["bedrock_inset"])
	var top_faces: Array = []
	var side_faces: Array = []
	var base_faces: Array = []
	for i in range(plan.island_rim.size()):
		var p: Vector2 = plan.island_rim[i] * plan.landscape_scale
		var q: Vector2 = plan.island_rim[(i+1)%plan.island_rim.size()] * plan.landscape_scale
		var a := Vector3(p.x,shore_height,p.y)
		var b := Vector3(q.x,shore_height,q.y)
		var c := Vector3(p.x*upper_stratum_inset,upper_stratum_y,p.y*upper_stratum_inset)
		var d := Vector3(q.x*upper_stratum_inset,upper_stratum_y,q.y*upper_stratum_inset)
		var e := Vector3(p.x*bedrock_inset,bedrock_y,p.y*bedrock_inset)
		var f := Vector3(q.x*bedrock_inset,bedrock_y,q.y*bedrock_inset)
		ctx.tri(top_faces,Vector3(0,shore_height,0),b,a)
		ctx.tri(side_faces,a,b,c)
		ctx.tri(side_faces,b,d,c)
		ctx.tri(base_faces,c,d,e)
		ctx.tri(base_faces,d,f,e)
	ctx.surface(land,"MossyIslandTop",top_faces,"Terrain")
	ctx.surface(land,"UpperRockStratum",side_faces,"StoneDark")
	ctx.surface(land,"ChiseledBedrock",base_faces,"Foundation")
	var sanctuary_data: Dictionary = plan.sanctuary
	# Ground-level stepping paths and planted margins merge into the playable field.
	var sanctuary := ctx.node(root,"NorthernSanctuary")
	var gate: Dictionary = sanctuary_data["gate"]
	ctx.place(sanctuary,"gate",String(gate["title"]),gate["position"])
	for spec: Dictionary in sanctuary_data["gate_lanterns"]:
		var position: Vector3 = spec["position"]
		ctx.place(sanctuary,"lantern",String(spec["title"]),position,float(spec["yaw"]),float(spec["scale"]))
	for spec: Dictionary in sanctuary_data["gate_cherries"]:
		var position: Vector3 = spec["position"]
		ctx.place(sanctuary,"tree",String(spec["title"]),position,float(spec["yaw"]),float(spec["scale"]))
	var water := ctx.node(root,"LotusPools")
	var pool: Dictionary = sanctuary_data["west_pool"]
	var pond := ctx.node(water,String(pool["name"]),pool["position"])
	ctx.box(pond,"StillWater",Vector3.ZERO,pool["water_size"],"Water")
	for side in [-1,1]:
		for i in range(int(pool["bank_stones"])):
			ctx.rock(pond,"BankStone%d_%d"%[side,i],Vector3(side*float(pool["bank_x"]),float(pool["bank_y"]),float(pool["bank_z_start"])+i*float(pool["bank_z_step"])),pool["bank_size"],"Moss" if i%3 else "StoneDark")
	var lotus_x: Vector2 = pool["lotus_x_range"]
	var lotus_z: Vector2 = pool["lotus_z_range"]
	for i in range(int(pool["lotus_count"])):
		ctx.place(pond,"lotus","Lotus%d"%i,Vector3(ctx.rng.randf_range(lotus_x.x,lotus_x.y),float(pool["lotus_y"]),ctx.rng.randf_range(lotus_z.x,lotus_z.y)),0,float(pool["lotus_scale"]))
	Landscape.make_bridge(ctx,root)
	root.get_node("GardenBridge").position = sanctuary_data["garden_bridge_position"]
	var margins_data: Dictionary = sanctuary_data["margins"]
	var margins := ctx.node(root,"GroundMargins")
	for side in [-1,1]:
		for i in range(int(margins_data["creeping_moss_count"])):
			var z := float(margins_data["creeping_z_start"])+i*float(margins_data["creeping_z_step"])
			var p := Vector3(side*(float(margins_data["creeping_x_base"])+ctx.rng.randf()*float(margins_data["creeping_x_jitter"])),float(margins_data["creeping_y"]),z+ctx.rng.randf_range(-float(margins_data["creeping_z_jitter"]),float(margins_data["creeping_z_jitter"])))
			var moss_x: Vector2 = margins_data["creeping_size_x_range"]
			var moss_z: Vector2 = margins_data["creeping_size_z_range"]
			ctx.rock(margins,"CreepingMoss%d_%d"%[side,i],p,Vector3(ctx.rng.randf_range(moss_x.x,moss_x.y),float(margins_data["creeping_size_y"]),ctx.rng.randf_range(moss_z.x,moss_z.y)),"MossPaving" if i%2 else "Meadow")
	for i in range(int(margins_data["ground_cover_count"])):
		var x := float(margins_data["ground_cover_x_start"])+i*float(margins_data["ground_cover_x_step"])
		for side in [-1,1]:
			var z := float(margins_data["ground_cover_z_back"]) if side < 0 else float(margins_data["ground_cover_z_front"])
			ctx.rock(margins,"GroundCover%d_%d"%[side,i],Vector3(x,float(margins_data["ground_cover_y"]),z),margins_data["ground_cover_size"],"MeadowLight" if i%3 else "MossPaving")
	var path_start: Vector3 = margins_data["west_path_start"]
	var path_step: Vector3 = margins_data["west_path_step"]
	for i in range(int(margins_data["west_path_count"])):
		ctx.box(margins,"WestPath%d"%i,path_start+path_step*i,margins_data["west_path_size"],"MossPaving")
	Landscape.make_expanded_landscape(ctx,root)
	Landscape.make_sanctuary_details(ctx,root)
	StaticGeometry.optimize_details(root)
	make_atmosphere(ctx,root)
	make_camera(ctx,root)
	var skirmish := SkirmishScene.instantiate()
	root.add_child(skirmish)
	ctx.save_scene(root,"res://scenes/battlefields/moonwell_courtyard.tscn")
	print(SAVED_MESSAGE % cell_count)

static func make_atmosphere(ctx: AuthoringContext, root: Node3D) -> void:
	var plan := LevelPlan.load_default()
	var lighting: Dictionary = plan.lighting
	var world := WorldEnvironment.new()
	world.name = "MoonlitAtmosphere"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = lighting["background_color"]
	env.background_energy_multiplier = float(lighting["background_energy"])
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = lighting["ambient_color"]
	env.ambient_light_energy = float(lighting["ambient_energy"])
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = bool(lighting["glow_enabled"])
	env.glow_intensity = float(lighting["glow_intensity"])
	env.ssao_enabled = bool(lighting["ssao_enabled"])
	env.ssao_radius = float(lighting["ssao_radius"])
	env.ssao_intensity = float(lighting["ssao_intensity"])
	world.environment = env
	root.add_child(world)
	var key := DirectionalLight3D.new()
	key.name = "Moonlight"
	key.rotation_degrees = lighting["moon_rotation"]
	key.light_color = lighting["moon_color"]
	key.light_energy = float(lighting["moon_energy"])
	key.shadow_enabled = true
	key.directional_shadow_max_distance = float(lighting["moon_shadow_distance"])
	root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "SoftDuskFill"
	fill.rotation_degrees = lighting["fill_rotation"]
	fill.light_color = lighting["fill_color"]
	fill.light_energy = float(lighting["fill_energy"])
	root.add_child(fill)

static func make_camera(ctx: AuthoringContext, root: Node3D) -> void:
	var rig := ctx.node(root,"CameraRig")
	rig.set_script(CameraScript)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CameraScript.DEFAULT_ZOOM
	camera.far = CameraScript.DEFAULT_FAR
	camera.current = true
	rig.add_child(camera)
	camera.position = CameraScript.default_camera_position()
	camera.basis = Basis.looking_at(CameraScript.DEFAULT_FOCUS - camera.position)
	var hud := CanvasLayer.new()
	hud.name = "CourtyardLabels"
	hud.set_script(LabelsScript)
	root.add_child(hud)
