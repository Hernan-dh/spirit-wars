extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
const LevelPlan = preload("res://tools/battlefield/level_plan.gd")
## Reusable prop scenes: stone lantern, blossom tree, bamboo grove, lotus, gate.
## All editable dimensions, counts, colors and light values come from the level plan.

static func build(ctx: AuthoringContext) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.prop_templates
	_stone_lantern(ctx, data["stone_lantern"])
	_blossom_tree(ctx, data["blossom_tree"])
	_bamboo(ctx, data["bamboo"])
	_lotus(ctx, data["lotus"])
	_spirit_gate(ctx, data["spirit_gate"])

static func _add_part(ctx: AuthoringContext, parent: Node, spec: Dictionary) -> void:
	var kind := String(spec["kind"])
	if kind == "box":
		ctx.box(parent, String(spec["name"]), spec["position"], spec["size"], String(spec["material"]))
	elif kind == "cylinder":
		ctx.cylinder(parent, String(spec["name"]), spec["position"], float(spec["bottom"]), float(spec["top"]), float(spec["height"]), String(spec["material"]), int(spec["sides"]))

static func _stone_lantern(ctx: AuthoringContext, data: Dictionary) -> void:
	var lantern := Node3D.new()
	lantern.name = "StoneLantern"
	for spec: Dictionary in data["parts"]:
		_add_part(ctx, lantern, spec)
	var corner: Dictionary = data["corner"]
	for x in [-1,1]:
		for z in [-1,1]:
			ctx.box(lantern, "Corner_%d_%d" % [x,z], Vector3(x*float(corner["offset"]),float(corner["y"]),z*float(corner["offset"])), corner["size"], String(corner["material"]))
	var lattice: Dictionary = data["window_lattice"]
	for side in [-1,1]:
		for j in range(int(lattice["count"])):
			ctx.box(lantern,"WindowLattice%d_%d"%[side,j],Vector3((j-int(lattice["center"]))*float(lattice["x_step"]),float(lattice["y"]),side*float(lattice["z"])),lattice["size"],String(lattice["material"]))
		var crossbar: Dictionary = data["window_crossbar"]
		ctx.box(lantern,"WindowCrossbar%d"%side,Vector3(0,float(crossbar["y"]),side*float(crossbar["z"])),crossbar["size"],String(crossbar["material"]))
		var carved: Dictionary = data["carved_foot"]
		for j in range(int(carved["count"])):
			ctx.box(lantern,"CarvedFoot%d_%d"%[side,j],Vector3((j-int(carved["center"]))*float(carved["x_step"]),float(carved["y"]),side*float(carved["z"])),carved["size"],String(carved["material"]))
	var lintel: Dictionary = data["lintel"]
	ctx.box(lantern,"Lintel",lintel["position"],lintel["size"],String(lintel["material"]))
	var roof: Dictionary = data["roof"]
	ctx.roof(lantern, String(roof["name"]), roof["position"], float(roof["radius"]), float(roof["height"]))
	var light_data: Dictionary = data["light"]
	var light := OmniLight3D.new()
	light.name = "WarmLanternLight"
	light.position.y = float(light_data["y"])
	light.light_color = light_data["color"]
	light.light_energy = float(light_data["energy"])
	light.omni_range = float(light_data["range"])
	lantern.add_child(light)
	ctx.prop_scenes["lantern"] = ctx.save_scene(lantern,"res://scenes/props/stone_lantern.tscn")

static func _blossom_tree(ctx: AuthoringContext, data: Dictionary) -> void:
	var tree := Node3D.new()
	tree.name = "BlossomTree"
	var trunk: Dictionary = data["trunk"]
	ctx.rod(tree,"AncientTrunk",trunk["from"],trunk["to"],float(trunk["bottom_radius"]),String(trunk["material"]),float(trunk["top_radius"]))
	var leaning: Dictionary = data["leaning_trunk"]
	ctx.rod(tree,"LeaningTrunk",leaning["from"],leaning["to"],float(leaning["bottom_radius"]),String(leaning["material"]),float(leaning["top_radius"]))
	var crown_near := SurfaceTool.new()
	var crown_far := SurfaceTool.new()
	crown_near.begin(Mesh.PRIMITIVE_TRIANGLES)
	crown_far.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ends: Array = data["bough_ends"]
	var twig_x: Vector2 = data["twig_offset_x"]
	var twig_y: Vector2 = data["twig_offset_y"]
	var twig_z: Vector2 = data["twig_offset_z"]
	for i in range(ends.size()):
		var end: Vector3 = ends[i]
		var start := Vector3(float(data["bough_start_x"]),float(data["bough_start_y"])+i*float(data["bough_start_step"]),0)
		ctx.rod(tree,"Bough%d" % i,start,end,float(data["bough_bottom_radius"]),String(data["bough_material"]),float(data["bough_top_radius"]))
		for j in range(int(data["twig_count"])):
			var p: Vector3 = end + Vector3(ctx.rng.randf_range(twig_x.x,twig_x.y),ctx.rng.randf_range(twig_y.x,twig_y.y),ctx.rng.randf_range(twig_z.x,twig_z.y))
			ctx.rod(tree,"FlowerTwig%d_%d" % [i,j],end,p+Vector3(0,float(data["twig_lift"]),0),float(data["twig_radius"]),String(data["twig_material"]),float(data["twig_top_radius"]))
			flower_cluster(ctx,crown_near,crown_far,p,(i+j)%3,data["crown"])
	var root_start: Vector3 = data["root_start"]
	for i in range(int(data["root_count"])):
		var a := i*TAU/float(data["root_count"])
		ctx.rod(tree,"Root%d" % i,root_start,Vector3(cos(a)*float(data["root_radius"]),0,sin(a)*float(data["root_radius"])),float(data["root_bottom_radius"]),String(data["root_material"]),float(data["root_top_radius"]))
	finish_blossom_crown(tree, crown_near, crown_far, float(data["crown"]["lod_error"]))
	ctx.prop_scenes["tree"] = ctx.save_scene(tree,"res://scenes/props/blossom_tree.tscn")

static func _bamboo(ctx: AuthoringContext, data: Dictionary) -> void:
	var bamboo := Node3D.new()
	bamboo.name = "BambooGrove"
	var px: Vector2 = data["position_x_range"]
	var pz: Vector2 = data["position_z_range"]
	var height: Vector2 = data["height_range"]
	var tip_x: Vector2 = data["tip_x_range"]
	var tip_z: Vector2 = data["tip_z_range"]
	for i in range(int(data["culm_count"])):
		var p := Vector3(ctx.rng.randf_range(px.x,px.y),0,ctx.rng.randf_range(pz.x,pz.y))
		var h := ctx.rng.randf_range(height.x,height.y)
		var tip := p + Vector3(ctx.rng.randf_range(tip_x.x,tip_x.y),h,ctx.rng.randf_range(tip_z.x,tip_z.y))
		ctx.rod(bamboo,"Culm%d" % i,p,tip,float(data["bottom_radius"]),String(data["material"]),float(data["top_radius"]))
		for j in range(int(data["joint_start"]),int(data["joint_end"])+1):
			var mid := p.lerp(tip,j/float(data["joint_divisions"]))
			ctx.cylinder(bamboo,"Joint%d_%d" % [i,j],mid,float(data["joint_radius"]),float(data["joint_radius"]),float(data["joint_height"]),String(data["joint_material"]))
			if j > int(data["twig_from_joint"]):
				var direction := Vector3(1 if (i+j)%2==0 else -1,float(data["twig_y"]),float(data["twig_z"]))
				ctx.rod(bamboo,"Twig%d_%d" % [i,j],mid,mid+direction*float(data["twig_length"]),float(data["twig_radius"]),String(data["material"]),float(data["twig_top_radius"]))
				var leaf_materials: Array = data["leaf_materials"]
				var leaf_side: Vector3 = data["leaf_side"]
				for k in range(int(data["leaf_count"])):
					var base := mid + direction * (float(data["leaf_start"])+k*float(data["leaf_step"]))
					var tip_leaf := base + Vector3(direction.x*float(data["leaf_x_scale"]),float(data["leaf_y"]),(k-2)*float(data["leaf_z_step"]))
					var leaf := ctx.surface(bamboo,"Leaf%d_%d_%d" % [i,j,k],[base,base.lerp(tip_leaf,.5)+leaf_side,tip_leaf,base,tip_leaf,base.lerp(tip_leaf,.5)-leaf_side],String(leaf_materials[k%2]))
					leaf.material_override = ctx.two_sided(leaf.material_override)
	ctx.prop_scenes["bamboo"] = ctx.save_scene(bamboo,"res://scenes/props/bamboo_grove.tscn")

static func _lotus(ctx: AuthoringContext, data: Dictionary) -> void:
	var lotus := Node3D.new()
	lotus.name = "Lotus"
	var pad: Dictionary = data["pad"]
	ctx.cylinder(lotus,"LilyPad",pad["position"],float(pad["bottom"]),float(pad["top"]),float(pad["height"]),String(pad["material"]),int(pad["sides"]))
	var materials: Array = data["petal_materials"]
	var petal_size: Vector3 = data["petal_size"]
	for i in range(int(data["petal_count"])):
		var a := i*TAU/float(data["petal_count"])
		var petal := ctx.rock(lotus,"Petal%d"%i,Vector3(cos(a)*float(data["petal_radius"]),float(data["petal_y"]),sin(a)*float(data["petal_radius"])),petal_size,String(materials[i%2]))
		petal.rotation = Vector3(cos(a)*float(data["petal_tilt"]),a,sin(a)*float(data["petal_tilt"]))
	var heart: Dictionary = data["heart"]
	ctx.cylinder(lotus,"GoldenHeart",heart["position"],float(heart["bottom"]),float(heart["top"]),float(heart["height"]),String(heart["material"]))
	ctx.prop_scenes["lotus"] = ctx.save_scene(lotus,"res://scenes/props/lotus.tscn")

static func _spirit_gate(ctx: AuthoringContext, data: Dictionary) -> void:
	var gate := Node3D.new()
	gate.name = "SpiritGate"
	var steps: Dictionary = data["approach_steps"]
	var step_materials: Array = steps["materials"]
	for i in range(int(steps["count"])):
		ctx.box(gate,"ApproachStep%d"%i,Vector3(0,float(steps["y_start"])+i*float(steps["y_step"]),float(steps["z_start"])+i*float(steps["z_step"])),Vector3(float(steps["width_start"])+i*float(steps["width_step"]),float(steps["height_start"])+i*float(steps["height_step"]),float(steps["depth"])),String(step_materials[i%2]))
	var platform: Dictionary = data["platform"]
	ctx.box(gate,"SanctuaryPlatform",platform["position"],platform["size"],String(platform["material"]))
	var cornice: Dictionary = data["cornice"]
	ctx.box(gate,"PlatformCornice",cornice["position"],cornice["size"],String(cornice["material"]))
	for side in [-1,1]:
		var x: float = side * float(data["pillar_x"])
		var foot: Dictionary = data["pillar_foot"]
		ctx.box(gate,"PillarFoot%d"%side,Vector3(x,float(foot["position"].y),float(foot["position"].z)),foot["size"],String(foot["material"]))
		var pillar: Dictionary = data["jade_pillar"]
		ctx.box(gate,"JadePillar%d"%side,Vector3(x,float(pillar["position"].y),float(pillar["position"].z)),pillar["size"],String(pillar["material"]))
		for y in data["collar_heights"]:
			ctx.box(gate,"Collar%d_%s"%[side,y],Vector3(x,float(y),float(pillar["position"].z)),data["collar_size"],String(data["collar_material"]))
		var inset: Dictionary = data["inset"]
		ctx.box(gate,"Inset%d"%side,Vector3(x,float(inset["position"].y),float(inset["position"].z)),inset["size"],String(inset["material"]))
		for j in range(int(data["glyph_count"])):
			var gem := ctx.box(gate,"Glyph%d_%d"%[side,j],Vector3(x,float(data["glyph_y_start"])+j*float(data["glyph_y_step"]),float(data["glyph_z"])),data["glyph_size"],String(data["glyph_material"]))
			gem.rotation.z = PI/4
		var arm: Dictionary = data["banner_arm"]
		var arm_start := Vector3(x,float(arm["from"].y),float(arm["from"].z))
		ctx.rod(gate,"BannerArm%d"%side,arm_start,arm_start+Vector3(side*float(arm["outward"]),0,0),float(arm["radius"]),String(arm["material"]))
		var banner: Dictionary = data["banner"]
		var banner_x: float = x+side*float(banner["outward"])
		ctx.box(gate,"SilkBanner%d"%side,Vector3(banner_x,float(banner["y"]),float(banner["z"])),banner["size"],String(banner["material"]))
		ctx.box(gate,"BannerStripe%d"%side,Vector3(banner_x,float(banner["y"]),float(banner["stripe_z"])),banner["stripe_size"],String(banner["stripe_material"]))
		var emblem := ctx.box(gate,"BannerEmblem%d"%side,Vector3(banner_x,float(banner["emblem_y"]),float(banner["emblem_z"])),banner["emblem_size"],String(banner["emblem_material"]))
		emblem.rotation.z = PI/4
	var timber: Dictionary = data["timber_lintel"]
	ctx.box(gate,"TimberLintel",timber["position"],timber["size"],String(timber["material"]))
	var gold: Dictionary = data["gold_lintel"]
	ctx.box(gate,"GoldLintel",gold["position"],gold["size"],String(gold["material"]))
	var great: Dictionary = data["great_roof"]
	var r := ctx.roof(gate,"GreatSweptRoof",great["position"],float(great["radius"]),float(great["height"]))
	r.scale.z = float(great["scale_z"])
	var crown: Dictionary = data["crown_roof"]
	var r2 := ctx.roof(gate,"CrownRoof",crown["position"],float(crown["radius"]),float(crown["height"]))
	r2.scale.z = float(crown["scale_z"])
	var halo: Dictionary = data["halo"]
	ctx.circle(gate,"CarvedHalo",halo["position"],float(halo["radius"]),String(halo["material"]),float(halo["thickness"]),bool(halo["vertical"]),int(halo["count"]))
	var inner: Dictionary = data["inner_halo"]
	ctx.circle(gate,"InnerHalo",inner["position"],float(inner["radius"]),String(inner["material"]),float(inner["thickness"]),bool(inner["vertical"]))
	var seal: Dictionary = data["halo_seal"]
	for i in range(int(seal["count"])):
		var a := i*TAU/float(seal["count"])
		var gem := ctx.box(gate,"HaloSeal%d"%i,Vector3(cos(a)*float(seal["radius"]),float(seal["y"])+sin(a)*float(seal["radius"]),float(seal["z"])),seal["size"],String(seal["material"]))
		gem.rotation.z = a-PI/2
	var spirit_data: Dictionary = data["spirit"]
	var spirit: Array = []
	for i in range(int(spirit_data["count"])):
		var t := i/float(int(spirit_data["count"])-1)
		spirit.append(Vector3(sin(t*TAU*float(spirit_data["turns"]))*(float(spirit_data["x_radius"])-float(spirit_data["x_taper"])*t),float(spirit_data["y_start"])+t*float(spirit_data["y_step"]),float(spirit_data["z"])))
	ctx.line(gate,"AscendingSpirit",spirit,float(spirit_data["line_radius"]),String(spirit_data["material"]))
	var motes: Dictionary = data["motes"]
	var mx: Vector2 = motes["x_range"]
	var my: Vector2 = motes["y_range"]
	var mz: Vector2 = motes["z_range"]
	for i in range(int(motes["count"])):
		ctx.rock(gate,"FloatingMote%d"%i,Vector3(ctx.rng.randf_range(mx.x,mx.y),ctx.rng.randf_range(my.x,my.y),ctx.rng.randf_range(mz.x,mz.y)),Vector3.ONE*float(motes["size"]),String(motes["material"]))
	var glow_data: Dictionary = data["glow"]
	var glow := OmniLight3D.new()
	glow.name = "PortalGlow"
	glow.position = glow_data["position"]
	glow.light_color = glow_data["color"]
	glow.light_energy = float(glow_data["energy"])
	glow.omni_range = float(glow_data["range"])
	gate.add_child(glow)
	ctx.prop_scenes["gate"] = ctx.save_scene(gate,"res://scenes/props/spirit_gate.tscn")

static func flower_cluster(ctx: AuthoringContext, near: SurfaceTool, far: SurfaceTool, pos: Vector3, shade: int, data: Dictionary) -> void:
	# Keep all bloom positions, sizes and colors (and the RNG sequence), but
	# replace the 36-triangle spheres with eight-triangle rounded octahedra.
	var octa := PackedVector3Array([Vector3.UP, Vector3.RIGHT, Vector3.BACK,
		Vector3.LEFT, Vector3.FORWARD, Vector3.DOWN])
	var octa_faces := PackedInt32Array([0,1,2, 0,2,3, 0,3,4, 0,4,1,
		5,2,1, 5,3,2, 5,4,3, 5,1,4])
	# Four-triangle blooms retain the same centers and color variation at distance.
	var tetra := PackedVector3Array([Vector3(1,1,1).normalized(),
		Vector3(1,-1,-1).normalized(), Vector3(-1,1,-1).normalized(),
		Vector3(-1,-1,1).normalized()])
	var tetra_faces := PackedInt32Array([0,2,1, 0,1,3, 0,3,2, 1,2,3])
	var y_range: Vector2 = data["y_range"]
	var size_range: Vector2 = data["size_range"]
	var near_color: Color = data["color_near"]
	var far_color: Color = data["color_far"]
	for i in range(int(data["blooms"])):
		var a := ctx.rng.randf()*TAU
		var r := sqrt(ctx.rng.randf())
		var p := Vector3(cos(a)*r*float(data["radius_x"]),ctx.rng.randf_range(y_range.x,y_range.y),sin(a)*r*float(data["radius_z"]))
		var size := ctx.rng.randf_range(size_range.x,size_range.y)
		var basis := Basis.from_euler(Vector3(ctx.rng.randf(),a,0))
		var color := near_color.lerp(far_color,ctx.rng.randf()*float(data["color_mix"])+shade*float(data["shade_step"]))
		append_bloom(near, octa, octa_faces, basis, size, pos+p, color)
		# Equalize projected coverage so distant flowers do not become sparse.
		append_bloom(far, tetra, tetra_faces, basis, size*float(data["far_scale"]), pos+p, color)

static func append_bloom(st: SurfaceTool, vertices: PackedVector3Array, indices: PackedInt32Array,
		basis: Basis, size: float, pos: Vector3, color: Color) -> void:
	for index in indices:
		st.set_color(color)
		st.set_normal(basis*vertices[index])
		st.add_vertex(basis*vertices[index]*size+pos)

static func finish_blossom_crown(tree: Node3D, near: SurfaceTool, far: SurfaceTool, lod_error: float) -> void:
	near.index()
	far.index()
	var arrays := near.commit_to_arrays()
	var distant := far.commit_to_arrays()
	var offset: int = arrays[Mesh.ARRAY_VERTEX].size()
	var far_indices: PackedInt32Array = distant[Mesh.ARRAY_INDEX]
	for i in range(far_indices.size()):
		far_indices[i] += offset
	for attribute in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR]:
		arrays[attribute].append_array(distant[attribute])
	var crown := ArrayMesh.new()
	crown.resource_name = "BlossomCrownLOD"
	crown.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [],
		{lod_error: far_indices})
	var n := MeshInstance3D.new()
	n.name = "BlossomCrown"
	n.mesh = crown
	var mat := StandardMaterial3D.new()
	mat.resource_name = "BlossomPetals"
	mat.vertex_color_use_as_albedo = true
	mat.roughness = .95
	n.material_override = mat
	# One complete crown surface avoids flattening away its native LOD indices
	# during prop merging. Scenery MultiMeshes reuse this mesh unchanged.
	tree.add_child(n)
