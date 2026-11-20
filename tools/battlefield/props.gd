extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
## Reusable prop scenes: stone lantern, blossom tree, bamboo grove, lotus, gate.

const BLOSSOM_LOD_ERROR := 0.045

static func build(ctx: AuthoringContext) -> void:
	var lantern := Node3D.new()
	lantern.name = "StoneLantern"
	ctx.box(lantern, "Foot", Vector3(0,.12,0), Vector3(.9,.24,.9), "StoneDark")
	ctx.box(lantern, "Plinth", Vector3(0,.29,0), Vector3(.72,.12,.72), "StoneLight")
	ctx.cylinder(lantern, "Column", Vector3(0,.8,0), .26,.20,1.0,"Stone",6)
	ctx.box(lantern, "LightShelf", Vector3(0,1.34,0), Vector3(.85,.18,.85), "StoneLight")
	ctx.box(lantern, "LuminousPaper", Vector3(0,1.72,0), Vector3(.48,.62,.48), "Amber")
	for x in [-1,1]:
		for z in [-1,1]:
			ctx.box(lantern, "Corner_%d_%d" % [x,z], Vector3(x*.31,1.73,z*.31), Vector3(.075,.76,.075), "Wood")
	for side in [-1,1]:
		for j in range(3):
			ctx.box(lantern,"WindowLattice%d_%d"%[side,j],Vector3((j-1)*.15,1.72,side*.255),Vector3(.025,.6,.025),"Wood")
		ctx.box(lantern,"WindowCrossbar%d"%side,Vector3(0,1.67,side*.27),Vector3(.54,.035,.025),"Wood")
		for j in range(3):
			ctx.box(lantern,"CarvedFoot%d_%d"%[side,j],Vector3((j-1)*.19,.3,side*.365),Vector3(.11,.045,.018),"StoneDark")
	ctx.box(lantern, "Lintel", Vector3(0,2.08,0), Vector3(.72,.12,.72), "Wood")
	ctx.roof(lantern, "PagodaCap", Vector3(0,2.1,0), .62, .37)
	var light := OmniLight3D.new()
	light.name = "WarmLanternLight"
	light.position.y = 1.8
	light.light_color = Color("ffb963")
	light.light_energy = 1.1
	light.omni_range = 4.3
	lantern.add_child(light)
	ctx.prop_scenes["lantern"] = ctx.save_scene(lantern,"res://scenes/props/stone_lantern.tscn")

	var tree := Node3D.new()
	tree.name = "BlossomTree"
	ctx.rod(tree,"AncientTrunk",Vector3.ZERO,Vector3(.18,2.3,0),.34,"Wood",.22)
	ctx.rod(tree,"LeaningTrunk",Vector3(.18,2.3,0),Vector3(-.45,3.7,.1),.22,"Wood",.09)
	var crown_near := SurfaceTool.new()
	var crown_far := SurfaceTool.new()
	crown_near.begin(Mesh.PRIMITIVE_TRIANGLES)
	crown_far.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ends := [Vector3(-1.8,3.6,.1),Vector3(1.6,3.4,.1),Vector3(.4,4.35,-.5),Vector3(-.2,3.5,1.3),Vector3(.6,3.6,-1.2)]
	for i in range(ends.size()):
		ctx.rod(tree,"Bough%d" % i,Vector3(.1,2.0+i*.17,0),ends[i],.17,"Wood",.045)
		for j in range(6):
			var p: Vector3 = ends[i] + Vector3(ctx.rng.randf_range(-.65,.65),ctx.rng.randf_range(-.2,.4),ctx.rng.randf_range(-.5,.5))
			ctx.rod(tree,"FlowerTwig%d_%d" % [i,j],ends[i],p+Vector3(0,.15,0),.034,"Wood",.009)
			flower_cluster(ctx,crown_near,crown_far,p,(i+j)%3)
	for i in range(5):
		var a := i*TAU/5
		ctx.rod(tree,"Root%d" % i,Vector3(0,.15,0),Vector3(cos(a)*.8,0,sin(a)*.8),.12,"Wood",.04)
	finish_blossom_crown(tree, crown_near, crown_far)
	ctx.prop_scenes["tree"] = ctx.save_scene(tree,"res://scenes/props/blossom_tree.tscn")

	var bamboo := Node3D.new()
	bamboo.name = "BambooGrove"
	for i in range(6):
		var p := Vector3(ctx.rng.randf_range(-.7,.7),0,ctx.rng.randf_range(-.6,.6))
		var h := ctx.rng.randf_range(2.7,4.7)
		var tip := p + Vector3(ctx.rng.randf_range(-.45,.45),h,ctx.rng.randf_range(-.4,.4))
		ctx.rod(bamboo,"Culm%d" % i,p,tip,.065,"Bamboo",.035)
		for j in range(1,7):
			var mid := p.lerp(tip,j/7.0)
			ctx.cylinder(bamboo,"Joint%d_%d" % [i,j],mid,.078,.078,.045,"MossLight")
			if j > 2:
				var direction := Vector3(1 if (i+j)%2==0 else -1,.25,.2)
				ctx.rod(bamboo,"Twig%d_%d" % [i,j],mid,mid+direction*.7,.023,"Bamboo",.008)
				for k in range(5):
					var base := mid + direction * (.15+k*.12)
					var tip_leaf := base + Vector3(direction.x*.42,-.12,(k-2)*.21)
					var side := Vector3(.025,.045,.07)
					var leaf := ctx.surface(bamboo,"Leaf%d_%d_%d" % [i,j,k],[base,base.lerp(tip_leaf,.5)+side,tip_leaf,base,tip_leaf,base.lerp(tip_leaf,.5)-side],"LeafLight" if k%2 else "Leaf")
					leaf.material_override = ctx.two_sided(leaf.material_override)
	ctx.prop_scenes["bamboo"] = ctx.save_scene(bamboo,"res://scenes/props/bamboo_grove.tscn")

	var lotus := Node3D.new()
	lotus.name = "Lotus"
	ctx.cylinder(lotus,"LilyPad",Vector3(0,.01,0),.35,.35,.025,"Leaf",10)
	for i in range(8):
		var a := i*TAU/8
		var petal := ctx.rock(lotus,"Petal%d"%i,Vector3(cos(a)*.15,.13,sin(a)*.15),Vector3(.10,.17,.22),"BlossomLight" if i%2 else "Blossom")
		petal.rotation = Vector3(cos(a)*.6,a,sin(a)*.6)
	ctx.cylinder(lotus,"GoldenHeart",Vector3(0,.16,0),.085,.045,.13,"Amber")
	ctx.prop_scenes["lotus"] = ctx.save_scene(lotus,"res://scenes/props/lotus.tscn")

	var gate := Node3D.new()
	gate.name = "SpiritGate"
	for i in range(5):
		ctx.box(gate,"ApproachStep%d"%i,Vector3(0,.12+i*.16,1.45-i*.42),Vector3(5.2-i*.15,.24+i*.32,.5),"Stone" if i%2 else "StoneLight")
	ctx.box(gate,"SanctuaryPlatform",Vector3(0,.48,-.72),Vector3(6.4,.96,2.5),"StoneDark")
	ctx.box(gate,"PlatformCornice",Vector3(0,1.0,-.72),Vector3(6.55,.18,2.6),"Stone")
	for side in [-1,1]:
		var x: float = side * 2.28
		ctx.box(gate,"PillarFoot%d"%side,Vector3(x,1.25,-.35),Vector3(.96,.4,.95),"StoneLight")
		ctx.box(gate,"JadePillar%d"%side,Vector3(x,2.85,-.35),Vector3(.55,3.0,.58),"Jade")
		for y in [1.55,3.7,4.15]:
			ctx.box(gate,"Collar%d_%s"%[side,y],Vector3(x,y,-.35),Vector3(.7,.13,.72),"Gold")
		ctx.box(gate,"Inset%d"%side,Vector3(x,2.85,-.046),Vector3(.21,1.7,.025),"StoneDark")
		for j in range(4):
			var gem := ctx.box(gate,"Glyph%d_%d"%[side,j],Vector3(x,2.25+j*.38,-.025),Vector3(.11,.11,.035),"SpiritDim")
			gem.rotation.z = PI/4
		ctx.rod(gate,"BannerArm%d"%side,Vector3(x,4.1,-.3),Vector3(x+side*.8,4.1,-.3),.05,"Gold")
		ctx.box(gate,"SilkBanner%d"%side,Vector3(x+side*.6,3.42,-.3),Vector3(.4,1.25,.035),"Cloth")
		ctx.box(gate,"BannerStripe%d"%side,Vector3(x+side*.6,3.42,-.27),Vector3(.025,1.12,.015),"Gold")
		var gem := ctx.box(gate,"BannerEmblem%d"%side,Vector3(x+side*.6,3.5,-.265),Vector3(.18,.18,.025),"Gold")
		gem.rotation.z = PI/4
	ctx.box(gate,"TimberLintel",Vector3(0,4.35,-.35),Vector3(5.55,.32,.65),"Wood")
	ctx.box(gate,"GoldLintel",Vector3(0,4.49,-.35),Vector3(5.8,.09,.77),"Gold")
	var r := ctx.roof(gate,"GreatSweptRoof",Vector3(0,4.55,-.35),3.0,.9)
	r.scale.z = .4
	var r2 := ctx.roof(gate,"CrownRoof",Vector3(0,5.35,-.35),1.65,.65)
	r2.scale.z = .46
	ctx.circle(gate,"CarvedHalo",Vector3(0,2.66,-.55),1.42,"StoneLight",.14,true,24)
	ctx.circle(gate,"InnerHalo",Vector3(0,2.66,-.38),1.29,"SpiritDim",.025,true)
	for i in range(8):
		var a := i*TAU/8
		var gem := ctx.box(gate,"HaloSeal%d"%i,Vector3(cos(a)*1.43,2.66+sin(a)*1.43,-.38),Vector3(.16,.24,.12),"Gold")
		gem.rotation.z = a-PI/2
	var spirit: Array = []
	for i in range(49):
		var t := i/48.0
		spirit.append(Vector3(sin(t*TAU*1.45)*(.47-.25*t),1.42+t*2.65,-.18))
	ctx.line(gate,"AscendingSpirit",spirit,.04,"Spirit")
	for i in range(12):
		ctx.rock(gate,"FloatingMote%d"%i,Vector3(ctx.rng.randf_range(-1.05,1.05),ctx.rng.randf_range(1.4,4),ctx.rng.randf_range(-.1,.3)),Vector3.ONE*.035,"Spirit")
	var glow := OmniLight3D.new()
	glow.name = "PortalGlow"
	glow.position = Vector3(0,2.5,.3)
	glow.light_color = Color("59e9e5")
	glow.light_energy = 3.0
	glow.omni_range = 5.5
	gate.add_child(glow)
	ctx.prop_scenes["gate"] = ctx.save_scene(gate,"res://scenes/props/spirit_gate.tscn")

static func flower_cluster(ctx: AuthoringContext, near: SurfaceTool, far: SurfaceTool, pos: Vector3, shade: int) -> void:
	# Keep all 64 bloom positions, sizes and colors (and the RNG sequence), but
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
	for i in range(64):
		var a := ctx.rng.randf()*TAU
		var r := sqrt(ctx.rng.randf())
		var p := Vector3(cos(a)*r*.76,ctx.rng.randf_range(-.22,.26),sin(a)*r*.6)
		var size := ctx.rng.randf_range(.12,.24)
		var basis := Basis.from_euler(Vector3(ctx.rng.randf(),a,0))
		var color := Color("f0b7d7").lerp(Color("a65f9e"),ctx.rng.randf()*.55+shade*.09)
		append_bloom(near, octa, octa_faces, basis, size, pos+p, color)
		# Equalize projected coverage so distant flowers do not become sparse.
		append_bloom(far, tetra, tetra_faces, basis, size*1.225, pos+p, color)

static func append_bloom(st: SurfaceTool, vertices: PackedVector3Array, indices: PackedInt32Array,
		basis: Basis, size: float, pos: Vector3, color: Color) -> void:
	for index in indices:
		st.set_color(color)
		st.set_normal(basis*vertices[index])
		st.add_vertex(basis*vertices[index]*size+pos)

static func finish_blossom_crown(tree: Node3D, near: SurfaceTool, far: SurfaceTool) -> void:
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
		{BLOSSOM_LOD_ERROR: far_indices})
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
