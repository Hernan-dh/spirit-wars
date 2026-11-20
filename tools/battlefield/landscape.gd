extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
const GroundZones = preload("res://tools/battlefield/ground_zones.gd")
## Surrounding landscape features: island rim, terraces, wetlands, gardens,
## ruins and sanctuary details. Everything is baked into ordinary scene nodes.

const ISLAND_RIM := [Vector2(-8.8,-6.6),Vector2(-6.8,-9.2),Vector2(5.4,-9.7),Vector2(8.9,-6.8),Vector2(9.4,3.7),Vector2(7.1,7.8),Vector2(3.6,8.4),Vector2(-6.2,7.9),Vector2(-9.3,4.5)]
const LANDSCAPE_SCALE := 2.0

static func make_bridge(ctx: AuthoringContext, root: Node3D) -> void:
	var bridge := ctx.node(root,"GardenBridge",Vector3(-7.0,.18,1.0))
	for i in range(11):
		var x := (i-5)*.29
		var y := .28*(1.0-pow(x/1.7,2))
		ctx.box(bridge,"DeckPlank%02d"%i,Vector3(x,y,0),Vector3(.27,.12,1.35),"WoodLight")
	for side in [-1,1]:
		var rail: Array = []
		for i in range(5):
			var x := (i-2)*.72
			var y := .28*(1.0-pow(x/1.7,2))
			ctx.box(bridge,"Post%d_%d"%[side,i],Vector3(x,y+.38,side*.67),Vector3(.1,.9,.1),"Wood")
			ctx.rock(bridge,"Cap%d_%d"%[side,i],Vector3(x,y+.86,side*.67),Vector3(.085,.085,.085),"Gold")
			rail.append(Vector3(x,y+.65,side*.67))
		ctx.line(bridge,"ArchedRail%d"%side,rail,.055,"WoodLight")

# The expanded landscape is baked to ordinary scene nodes by this authoring tool.
# Nothing here runs in the game; each named terrace, rock and plant can be edited.
static func terrace(ctx: AuthoringContext, parent: Node, title: String, center: Vector3, radius: Vector2, height: float) -> Node3D:
	var n := ctx.node(parent, title, center)
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
			ctx.tri(faces, rings[layer][i], rings[layer+1][i], rings[layer][j])
			ctx.tri(faces, rings[layer][j], rings[layer+1][i], rings[layer+1][j])
		ctx.surface(n, "Bedrock" if layer == 0 else "WeatheredRim", faces, "Cliff" if layer == 0 else "CliffLight")
	var top: Array = []
	for i in range(10):
		ctx.tri(top, Vector3(0,height,0), rings[2][(i+1)%10], rings[2][i])
	ctx.surface(n,"MossyCrown",top,"Moss")
	for i in range(8):
		if i == 2 and title in ["EasternCascadePlateau", "CascadeShelf"]:
			continue # Keep the spring and spillway free of crown boulders.
		var a := TAU*i/8
		var p := Vector3(cos(a)*radius.x*.86, height-.12, sin(a)*radius.y*.86)
		ctx.rock(n,"CrownBoulder%02d"%i,p,Vector3(.65,.3,.48),"Moss" if i%3 else "Stone")
	# Offset facets, shelves and vines break up the large, smooth cliff faces.
	for i in range(16):
		var a := TAU*i/16
		var h := height*(.4+.4*(sin(i*2.8)*.5+.5))
		var p := Vector3(cos(a)*radius.x*.94,h*.5,sin(a)*radius.y*.94)
		var buttress := ctx.cylinder(n,"ErodedButtress%02d"%i,p,.55,.32,h,"CliffLight" if i%3 else "Cliff",5)
		buttress.rotation.y = a
		ctx.rock(n,"MossShelf%02d"%i,p+Vector3(0,h*.5,0),Vector3(.46,.10,.43),"Moss")
		if i%2 == 0:
			var start := Vector3(cos(a)*radius.x*.9,height,sin(a)*radius.y*.9)
			ctx.line(n,"CliffVine%02d"%i,[start,start+Vector3(.05,-.45,.12),start+Vector3(.12,-minf(height*.55,1.4),.15)],.035,"Leaf")
	return n

static func ring_mesh(ctx: AuthoringContext, parent: Node, title: String, center: Vector3, radius: float, thickness: float, mat: String) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius-thickness
	torus.outer_radius = radius+thickness
	torus.rings = 40
	torus.ring_segments = 6
	return ctx.mesh(parent,title,torus,mat,center)

static func fern(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, size := 1.0) -> void:
	var n := ctx.node(parent,title,pos)
	n.scale *= size
	n.set_meta("batch_scenery", true)
	if ctx.fern_geometry != null:
		ctx.mesh(n, "FeatheredFronds", ctx.fern_geometry, "LeafLight")
		return
	var fronds: Array = []
	for i in range(9):
		var a := i*TAU/9
		var d := Vector3(cos(a),0,sin(a))
		var side := Vector3(-sin(a),0,cos(a))
		for j in range(7):
			var t := j/7.0
			var mid := d*t*.72+Vector3.UP*(sin(t*PI*.85)*.48+.03)
			var next := d*(t+.14)*.72+Vector3.UP*(sin((t+.14)*PI*.85)*.48+.03)
			ctx.tri(fronds,mid-side*.012,mid+side*.012,next)
			ctx.tri(fronds,mid+side*.012,mid-side*.012,next)
			for direction in [-1,1]:
				var tip: Vector3 = mid+side*direction*(.17*(1.0-t)+.025)+d*.10
				var middle := mid.lerp(tip,.5)+Vector3.UP*.035
				ctx.tri(fronds,mid,middle-d*.04,tip)
				ctx.tri(fronds,mid,tip,middle+d*.04)
				ctx.tri(fronds,mid,tip,middle-d*.04)
				ctx.tri(fronds,mid,middle+d*.04,tip)
	ctx.fern_geometry = ctx.surface(n,"FeatheredFronds",fronds,"LeafLight").mesh

static func banner(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, yaw := 0.0) -> void:
	var n := ctx.node(parent,title,pos)
	n.rotation.y = yaw
	for side in [-1,1]:
		ctx.cylinder(n,"StoneFoot%d"%side,Vector3(side*1.55,.18,0),.32,.25,.36,"StoneDark")
		ctx.rod(n,"Pole%d"%side,Vector3(side*1.55,.3,0),Vector3(side*1.55,3.5,0),.055,"Wood")
		ctx.rock(n,"Finial%d"%side,Vector3(side*1.55,3.6,0),Vector3(.12,.2,.12),"Gold")
	ctx.line(n,"Suspension",[Vector3(-1.55,3.45,0),Vector3(0,3.15,0),Vector3(1.55,3.45,0)],.025,"Gold")
	for i in range(3):
		var x := (i-1)*.85
		var y := 3.18+absf(x)*.14
		var cloth := [Vector3(x-.25,y,0),Vector3(x+.25,y,0),Vector3(x+.27,y-1.25,.14),Vector3(x-.25,y,0),Vector3(x+.27,y-1.25,.14),Vector3(x-.18,y-1.45,.10)]
		var flag := ctx.surface(n,"HangingSilk%d"%i,cloth,"Cloth")
		flag.material_override = ctx.two_sided(flag.material_override)
		for j in range(3):
			var seal := ctx.box(n,"GoldStitch%d_%d"%[i,j],Vector3(x,y-.35-j*.25,.09),Vector3(.11,.16,.025),"Gold")
			seal.rotation.z = PI/4

static func brazier(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3) -> void:
	var n := ctx.node(parent,title,pos)
	ctx.cylinder(n,"Plinth",Vector3(0,.15,0),.52,.43,.3,"StoneDark")
	ctx.cylinder(n,"Stem",Vector3(0,.55,0),.24,.16,.65,"Gold")
	ctx.cylinder(n,"BronzeBowl",Vector3(0,.94,0),.23,.52,.35,"Gold")
	ctx.cylinder(n,"Coals",Vector3(0,1.11,0),.43,.40,.04,"Amber")
	for i in range(5):
		var a := i*TAU/5
		var flame := ctx.rock(n,"SpiritFlame%d"%i,Vector3(cos(a)*.19,1.4,sin(a)*.19),Vector3(.12,.43+i*.04,.13),"Amber")
		flame.rotation.z = sin(a)*.3

static func pavilion(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, size := 1.0) -> void:
	var n := ctx.node(parent,title,pos)
	n.scale *= size
	ctx.box(n,"Foundation",Vector3(0,.18,0),Vector3(4.5,.36,3.7),"StoneDark")
	ctx.box(n,"StoneFloor",Vector3(0,.41,0),Vector3(4.7,.14,3.9),"StoneLight")
	for x in [-1,1]:
		for z in [-1,1]:
			var p := Vector3(x*1.75,1.85,z*1.35)
			ctx.cylinder(n,"Pillar%d_%d"%[x,z],p,.13,.11,2.8,"Wood")
			ctx.cylinder(n,"GiltFoot%d_%d"%[x,z],Vector3(p.x,.63,p.z),.22,.19,.3,"Gold")
	for side in [-1,1]:
		for j in range(9):
			var x := (j-4)*.43
			ctx.box(n,"EaveBracket%d_%d"%[side,j],Vector3(x,3.02,side*1.43),Vector3(.12,.34,.36),"Wood")
			ctx.box(n,"BracketScroll%d_%d"%[side,j],Vector3(x,2.94,side*1.53),Vector3(.24,.08,.22),"Gold")
		for j in range(5):
			ctx.box(n,"RearScreen%d_%d"%[side,j],Vector3(side*(.6+j*.21),1.9,-1.35),Vector3(.04,2.2,.06),"WoodLight")
	ctx.box(n,"LintelFront",Vector3(0,3.15,1.35),Vector3(3.8,.24,.18),"WoodLight")
	ctx.box(n,"LintelRear",Vector3(0,3.15,-1.35),Vector3(3.8,.24,.18),"WoodLight")
	var r := ctx.roof(n,"SweptRoof",Vector3(0,3.3,0),2.6,1.05)
	r.scale.z = .8
	ctx.roof(n,"UpperRoof",Vector3(0,4.15,0),1.45,.85)
	ctx.place(n,"lantern","OfferingLantern",Vector3(0,.48,0),0,.68)
	for side in [-1,1]:
		ctx.box(n,"Balustrade%d"%side,Vector3(side*1.8,1,-.2),Vector3(.12,.12,2.7),"WoodLight")
		for j in range(6):
			ctx.box(n,"RailSpindle%d_%d"%[side,j],Vector3(side*1.8,.75,-1.25+j*.43),Vector3(.07,.55,.07),"Wood")

static func waterfall(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, height: float, width: float) -> void:
	var n := ctx.node(parent,title,pos)
	# Opaque ribbons avoid sorting artifacts in the project's Compatibility renderer.
	for i in range(5):
		var x := (i-2)*width/5
		var z := .07*sin(i*1.8)
		ctx.box(n,"FallingRibbon%d"%i,Vector3(x,height*.5,z),Vector3(width/5*.94,height,.045),"FallingWater" if i%2 else "Ripple")
		ctx.rod(n,"Whitewater%d"%i,Vector3(x,height,.04+z),Vector3(x+.04,.12,.15+z),.012,"Foam")
	for i in range(3):
		var ripple := ring_mesh(ctx,n,"SplashRing%d"%i,Vector3(0,.035+i*.012,.3),width*.45+i*.26,.02,"Foam")
		ripple.scale.z = .42
	for i in range(7):
		ctx.rock(n,"Spray%d"%i,Vector3(ctx.rng.randf_range(-width*.6,width*.6),ctx.rng.randf_range(.05,.42),ctx.rng.randf_range(.05,.6)),Vector3(.04,.07,.04),"Foam")

static func make_expanded_landscape(ctx: AuthoringContext, root: Node3D) -> void:
	var terrain := ctx.node(root,"HighlandTerraces")
	terrace(ctx,terrain,"WesternGardenTerrace",Vector3(-15.5,0,-4.5),Vector2(2.4,4.1),1.0)
	terrace(ctx,terrain,"WesternUpperTerrace",Vector3(-13.1,0,-12.6),Vector2(3.2,2.8),2.6)
	terrace(ctx,terrain,"TemplePlateau",Vector3(-5.8,0,-15.8),Vector2(5.8,3.0),5.0)
	terrace(ctx,terrain,"EasternCascadePlateau",Vector3(13.6,0,-13.5),Vector2(3.0,3.9),4.4)
	terrace(ctx,terrain,"CascadeShelf",Vector3(14.5,0,-8.0),Vector2(1.7,2.1),1.8)
	# Narrow, irregular columns read as eroded mountain strata, rather than walls.
	for i in range(27):
		var x := -16.0+i*1.22
		var z := -15.8 + sin(i*.8)*.65
		var h := 3.8 + (sin(i*1.9)+1)*2.3
		if x > -10 and x < -.5:
			h = 4.3
		var column := ctx.cylinder(terrain,"RidgeColumn%02d"%i,Vector3(x,h*.5-.1,z),.9,.57,h,"Cliff" if i%3 else "CliffLight",5)
		column.rotation.y = i*.7
		for ledge in range(4):
			var y := h*(.18+ledge*.21)
			var shelf := ctx.rock(terrain,"RidgeLedge%d_%d"%[i,ledge],Vector3(x+.18*sin(i+ledge),y,z+.12),Vector3(.83,.19,.72),"CliffLight")
			shelf.rotation.z = .12*sin(i)
		ctx.rock(terrain,"RidgeMoss%02d"%i,Vector3(x,h-.1,z),Vector3(.62,.13,.66),"Moss")
	# Separated tall peaks give the rear silhouette the concept's vertical rhythm.
	for i in range(6):
		var x := -14+i*5.1
		var h := 7.5+sin(i*2.3)*1.8
		var peak := ctx.cylinder(terrain,"DistantSpire%d"%i,Vector3(x,h*.5,-17),1.0,.35,h,"Cliff",5)
		peak.rotation.z = .06*sin(i)
		ctx.rock(terrain,"PeakCap%d"%i,Vector3(x,h,-17),Vector3(.45,.12,.46),"Moss")
	var shrines := ctx.node(root,"HighlandShrines")
	pavilion(ctx,shrines,"HilltopTemple",Vector3(-5.7,5,-15.8),1.22)
	pavilion(ctx,shrines,"EastTeaPavilion",Vector3(14,4.4,-13.8),.85)
	ctx.place(shrines,"tree","HilltopCherry",Vector3(-12.4,2.6,-13.3),.6,.9)
	ctx.place(shrines,"tree","CascadeCherry",Vector3(11.8,4.4,-14.1),1,.8)
	# Broad stone stairs link the main gate to the elevated sanctuary.
	for i in range(19):
		var y := (i+1)*5.0/19
		ctx.box(shrines,"PilgrimStair%02d"%i,Vector3(-5.7,y*.5,-9.4-i*.34),Vector3(2.1,y,.4),"Stone" if i%2 else "StoneLight")
		if i%4 == 0:
			for side in [-1,1]:
				ctx.box(shrines,"StairPost%d_%d"%[i,side],Vector3(-5.7+side*1.25,y+.35,-9.4-i*.34),Vector3(.24,.7,.24),"StoneDark")
	for side in [-1,1]:
		ctx.place(shrines,"lantern","TempleLantern%d"%side,Vector3(-5.7+side*2.0,5,-13.8),0,.8)
	banner(ctx,shrines,"TemplePrayerSilks",Vector3(-9,5,-16.1),.2)
	brazier(ctx,shrines,"WesternOffering",Vector3(-3.2,0,-9.7))
	brazier(ctx,shrines,"EasternOffering",Vector3(3.2,0,-9.7))

	var wetlands := ctx.node(root,"EasternWetlands")
	# An irregular shoreline and winding stream replace the tiny rectangular pond edge.
	var shore := [Vector2(12.6,-9.6),Vector2(15.7,-9.6),Vector2(16.4,-5),Vector2(15.8,-1),Vector2(17.1,2),Vector2(16,8),Vector2(13.6,12.2),Vector2(12.4,11.7),Vector2(12.8,8.2),Vector2(12.3,5.1),Vector2(12.6,3),Vector2(12.5,-1.9)]
	var faces: Array = []
	var polygon := PackedVector2Array(shore)
	var indices := Geometry2D.triangulate_polygon(polygon)
	for i in range(0,indices.size(),3):
		var a := polygon[indices[i]]
		var b := polygon[indices[i+1]]
		var c := polygon[indices[i+2]]
		ctx.tri(faces,Vector3(a.x,-.015,a.y),Vector3(c.x,-.015,c.y),Vector3(b.x,-.015,b.y))
	ctx.surface(wetlands,"LotusLakeAndStream",faces,"Water")
	for i in range(shore.size()):
		var a: Vector2 = shore[i]
		var b: Vector2 = shore[(i+1)%shore.size()]
		for j in range(5):
			var p := a.lerp(b,j/5.0)
			ctx.rock(wetlands,"ShoreRock%d_%d"%[i,j],Vector3(p.x,.02,p.y),Vector3(.45,.22,.39),"StoneDark" if j%3 else "Moss")
	for i in range(25):
		var p := Vector3(ctx.rng.randf_range(13,15.8),.025,ctx.rng.randf_range(1,10))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),polygon):
			continue
		ctx.place(wetlands,"lotus","LotusCluster%02d"%i,p,ctx.rng.randf()*TAU,ctx.rng.randf_range(.7,1.25))
		if i%3 == 0:
			ring_mesh(ctx,wetlands,"WaterRipple%02d"%i,p,.65,.008,"Ripple")
		ctx.cylinder(wetlands,"LilyPad%02d"%i,p+Vector3(.5,0,.1),.24,.24,.02,"Leaf",10)
	# Water starts in a visible upper basin and falls over two successive cliff ledges.
	ctx.box(wetlands,"UpperSpring",Vector3(14.4,4.42,-10.7),Vector3(1.7,.04,3.0),"Water")
	ctx.box(wetlands,"MiddleBasin",Vector3(14.4,1.82,-6.9),Vector3(2.1,.04,2.8),"Water")
	for side in [-1,1]:
		for i in range(5):
			ctx.rock(wetlands,"SpringBank%d_%d"%[side,i],Vector3(14.4+side*.98,4.4,-11.8+i*.6),Vector3(.22,.18,.38),"Moss" if i%2 else "StoneDark")
		for i in range(4):
			ctx.rock(wetlands,"ShelfBank%d_%d"%[side,i],Vector3(14.4+side*1.16,1.8,-7.7+i*.65),Vector3(.22,.16,.36),"StoneDark")
	waterfall(ctx,wetlands,"UpperFalls",Vector3(14.4,1.84,-9.2),2.58,1.6)
	waterfall(ctx,wetlands,"LowerFalls",Vector3(14.4,.02,-5.5),1.8,1.9)
	# The second bridge crosses the stream between the shore paths.
	var crossing := ctx.node(wetlands,"StreamCrossing",Vector3(14.4,.12,-.4))
	make_bridge(ctx,crossing)
	var bridge := crossing.get_node("GardenBridge") as Node3D
	bridge.position = Vector3.ZERO
	bridge.scale = Vector3(1.0,1.25,1.2)
	for side in [-1,1]:
		ctx.place(wetlands,"lantern","BridgeLantern%d"%side,Vector3(14.4+side*.9,0,-1.5),0,.6)
	for i in range(9):
		var p := Vector3(12.6+i*.1,.04,6+i*.65)
		ctx.cylinder(wetlands,"WetlandSteppingStone%d"%i,p,.53,.51,.16,"Stone",6)

	var gardens := ctx.node(root,"OuterGardens")
	var trees := [Vector3(-16.0,1,-3),Vector3(-15.8,1,-6.5),Vector3(-14.2,2.6,-12.4),Vector3(17,0,-4),Vector3(-14.4,0,8.4),Vector3(7.2,0,15.3)]
	for i in range(trees.size()):
		ctx.place(gardens,"tree","CherryGrove%d"%i,trees[i],i*.7,.42 if i == 5 else .72+(i%3)*.14)
	var bamboo_positions := [Vector3(-17,1,-5),Vector3(-15,1,-7),Vector3(-16.5,0,1),Vector3(-16.5,0,4),Vector3(17.3,0,-2),Vector3(17.4,0,1),Vector3(16.6,0,7),Vector3(3,0,-14)]
	for i in range(bamboo_positions.size()):
		ctx.place(gardens,"bamboo","BambooThicket%d"%i,bamboo_positions[i],i*1.3,1.0+(i%3)*.2)
	var planted_boundary := PackedVector2Array()
	for point in ISLAND_RIM:
		planted_boundary.append(point * LANDSCAPE_SCALE * .96)
	for i in range(100):
		var p := Vector3(ctx.rng.randf_range(-16,16),0,ctx.rng.randf_range(-11,14))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),planted_boundary):
			continue
		# Keep the playable ground, shore water and terraces clear of tall props.
		if (absf(p.x)<12.7 and p.z>-9.4 and p.z<12.2) or (p.x>12 and p.z<12) or (p.x<-12 and p.z<0) or (absf(p.x)<2 and p.z>5):
			continue
		fern(ctx,gardens,"GroundFern%03d"%i,p,ctx.rng.randf_range(.65,1.5))
		if i%3 == 0:
			ctx.rock(gardens,"MossyOutcrop%03d"%i,p,Vector3(.65,.35,.5),"Moss")
	for i in range(22):
		var p := Vector3(-16.5+ctx.rng.randf()*2,1.03,-7+ctx.rng.randf()*6)
		fern(ctx,gardens,"TerraceFern%02d"%i,p,.8)
		if i%2 == 0:
			ctx.rock(gardens,"BlossomCarpet%02d"%i,p,Vector3(.16,.025,.13),"BlossomDark")
	# A worn approach remains low in the foreground, preserving views of the field.
	var approach := ctx.node(root,"PilgrimApproach")
	for i in range(13):
		var z := 11.9+i*.26
		ctx.box(approach,"OldFlagstone%02d"%i,Vector3(sin(i*.35)*.35,.03,z),Vector3(2.25,.10,.24),"Stone" if i%3 else "StoneLight")
		if i in [4,12]:
			for side in [-1,1]:
				ctx.place(approach,"lantern","PathLight%d_%d"%[i,side],Vector3(side*1.9,0,z+.6),0,.38)
	banner(ctx,approach,"EntryPrayerFlags",Vector3(-3.8,0,15.3),-.2)
	banner(ctx,approach,"EasternPrayerFlags",Vector3(4,0,15.3),.3)
	approach.get_node("EntryPrayerFlags").scale = Vector3.ONE*.65
	approach.get_node("EasternPrayerFlags").scale = Vector3.ONE*.65
	make_ruins(ctx,root)

static func make_ruins(ctx: AuthoringContext, root: Node3D) -> void:
	var ruins := ctx.node(root,"WesternRuins",Vector3(-14,0,10.4))
	ruins.scale = Vector3.ONE*.6
	for i in range(9):
		var slab := ctx.box(ruins,"BrokenPaving%d"%i,Vector3((i%3-1)*1.1,.04,(i/3-1)*1.05),Vector3(1,.17,.94),"StoneDark" if i%2 else "Stone")
		slab.rotation.y = ctx.rng.randf_range(-.14,.14)
	for side in [-1,1]:
		var pillar := ctx.node(ruins,"CarvedPillar%d"%side,Vector3(side*2.1,0,-.4))
		ctx.box(pillar,"Foot",Vector3(0,.2,0),Vector3(1.2,.4,1.2),"StoneDark")
		ctx.box(pillar,"Shaft",Vector3(0,1.6,0),Vector3(.7,2.7,.8),"Stone")
		for y in [.5,2.3,2.9]:
			ctx.box(pillar,"Collar%s"%y,Vector3(0,y,0),Vector3(.9,.15,1),"StoneLight")
		for j in range(3):
			var glyph := ctx.box(pillar,"InsetRune%d"%j,Vector3(0,1+j*.46,.411),Vector3(.18,.24,.02),"SpiritDim")
			glyph.rotation.z = PI/4
		ctx.rock(pillar,"Overgrowth",Vector3(.1,3.04,0),Vector3(.55,.12,.54),"Moss")
		for j in range(4):
			ctx.line(pillar,"HangingVine%d"%j,[Vector3((j-1.5)*.17,3,.48),Vector3((j-1.5)*.17+.05,2.7,.49),Vector3((j-1.5)*.17,2.15-j*.15,.47)],.026,"Leaf")
	var fallen := ctx.box(ruins,"FallenLintel",Vector3(.4,.36,-1.7),Vector3(3.6,.65,.9),"Stone")
	fallen.rotation = Vector3(.1,.22,-.12)
	var monolith := ctx.rock(ruins,"SpiritMonolith",Vector3(0,1.25,-.5),Vector3(.72,1.35,.48),"StoneDark")
	monolith.rotation = Vector3.ZERO
	var spiral: Array = []
	for i in range(25):
		var t := i/24.0
		spiral.append(Vector3(sin(t*TAU*1.5)*.22,.55+t*1.45,.005))
	ctx.line(ruins,"MonolithInscription",spiral,.023,"Spirit")
	ring_mesh(ctx,ruins,"OfferingCircle",Vector3(0,.15,1),.9,.018,"SpiritDim")
	ctx.place(ruins,"lantern","RuinLantern",Vector3(-2.7,0,1.4),0,.7)
	for i in range(12):
		var a := i*TAU/12
		fern(ctx,ruins,"ReclaimedFern%d"%i,Vector3(cos(a)*2.9,0,sin(a)*2.5),.8)

static func guardian(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, yaw: float) -> void:
	var n := ctx.node(parent,title,pos)
	n.rotation.y = yaw
	n.scale = Vector3.ONE*.82
	ctx.box(n,"WeatheredPlinth",Vector3(0,.16,0),Vector3(1.8,.32,2.0),"StoneDark")
	ctx.box(n,"CarvedPlinthLip",Vector3(0,.36,0),Vector3(1.65,.12,1.86),"StoneLight")
	ctx.rock(n,"Haunches",Vector3(0,1.0,-.3),Vector3(.64,.65,.68),"Stone")
	ctx.rock(n,"UprightChest",Vector3(0,1.45,.1),Vector3(.52,.8,.48),"StoneLight")
	for side in [-1,1]:
		ctx.rod(n,"Foreleg%d"%side,Vector3(side*.38,1.35,.35),Vector3(side*.42,.58,.65),.17,"StoneLight",.21)
		ctx.rock(n,"Paw%d"%side,Vector3(side*.43,.53,.77),Vector3(.3,.18,.39),"StoneLight")
		for toe in range(3):
			ctx.rock(n,"Toe%d_%d"%[side,toe],Vector3(side*.43+(toe-1)*.15,.51,1.02),Vector3(.07,.08,.13),"Stone")
	ctx.rock(n,"GuardianHead",Vector3(0,2.2,.3),Vector3(.62,.54,.52),"StoneLight")
	ctx.rock(n,"Muzzle",Vector3(0,2.03,.77),Vector3(.4,.23,.28),"StoneLight")
	ctx.rock(n,"Nose",Vector3(0,2.14,.99),Vector3(.21,.12,.1),"StoneDark")
	ctx.box(n,"MouthCarving",Vector3(0,1.94,.98),Vector3(.45,.045,.035),"StoneDark")
	for side in [-1,1]:
		ctx.rock(n,"Ear%d"%side,Vector3(side*.5,2.58,.16),Vector3(.2,.27,.14),"Stone")
		ctx.rock(n,"EyeSocket%d"%side,Vector3(side*.3,2.31,.73),Vector3(.16,.1,.055),"StoneDark")
		ctx.rock(n,"SpiritEye%d"%side,Vector3(side*.3,2.31,.785),Vector3(.06,.045,.025),"SpiritDim")
		ctx.line(n,"Brow%d"%side,[Vector3(side*.12,2.4,.77),Vector3(side*.3,2.46,.73),Vector3(side*.48,2.39,.62)],.065,"StoneLight")
		ctx.line(n,"Whisker%d"%side,[Vector3(side*.25,2.09,.96),Vector3(side*.63,2.07,.85),Vector3(side*.72,2.28,.69)],.035,"Gold")
		ctx.cylinder(n,"Fang%d"%side,Vector3(side*.23,1.92,.98),.0,.055,.19,"Gold")
	# Repeated spiral locks give the guardian a carved cloud mane.
	for i in range(13):
		var a := i*TAU/13
		var center := Vector3(cos(a)*.57,2.19+sin(a)*.61,.15)
		var curl: Array = []
		for j in range(12):
			var t := j/11.0
			curl.append(center+Vector3(cos(t*TAU*1.3)*(.2-.14*t),sin(t*TAU*1.3)*(.2-.14*t),.08*t))
		ctx.line(n,"CloudMane%02d"%i,curl,.055,"Stone")
	ctx.line(n,"CurledTail",[Vector3(.1,.8,-.75),Vector3(.65,1,-.9),Vector3(.81,1.5,-.75),Vector3(.6,1.69,-.57),Vector3(.42,1.5,-.48)],.13,"Stone")
	for side in [-1,1]:
		for j in range(4):
			var seal := ctx.box(n,"PlinthRelief%d_%d"%[side,j],Vector3((j-1.5)*.33,.2,side*1.006),Vector3(.16,.11,.035),"Jade")
			seal.rotation.z = PI/4

static func make_sanctuary_details(ctx: AuthoringContext, root: Node3D) -> void:
	var details := ctx.node(root,"SanctuaryDetails")
	guardian(ctx,details,"WesternCloudLion",Vector3(-4.95,0,-9.5),.2)
	guardian(ctx,details,"EasternCloudLion",Vector3(4.95,0,-9.5),-.2)
	# Low vegetation crosses the logical field boundary, without covering destinations.
	var grass_faces: Array = []
	var petal_faces: Array = []
	var boundary := PackedVector2Array()
	for point in ISLAND_RIM:
		boundary.append(point*LANDSCAPE_SCALE*.98)
	for i in range(2100):
		var p := Vector3(ctx.rng.randf_range(-16.5,16.5),.012,ctx.rng.randf_range(-9.1,14.6))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),boundary):
			continue
		if p.x > -15.9 and p.x < -13.1 and p.z > .5 and p.z < 7.5:
			continue
		if absf(p.x)>12.5 and p.x>0 and p.z<12:
			continue # Wetland water remains clear.
		if GroundZones.is_within_paving_margin(Vector2(p.x,p.z), GroundZones.VEGETATION_CLEARANCE):
			continue
		if sin(p.x*.7)+cos(p.z*.8)<.2:
			continue
		for blade in range(3):
			var a := ctx.rng.randf()*TAU
			var side := Vector3(cos(a),0,sin(a))*.022
			var tip := p+Vector3(sin(a)*.07,ctx.rng.randf_range(.08,.23),cos(a)*.07)
			ctx.tri(grass_faces,p-side,p+side,tip)
			ctx.tri(grass_faces,p+side,p-side,tip)
		if i%4==0:
			var q := p+Vector3(.16,.003,0)
			ctx.tri(petal_faces,q+Vector3(-.055,0,0),q+Vector3(0,0,.04),q+Vector3(.055,0,0))
			ctx.tri(petal_faces,q+Vector3(-.055,0,0),q+Vector3(.055,0,0),q+Vector3(0,0,-.04))
	ctx.surface(details,"MeadowGrassAndCreviceShoots",grass_faces,"Grass")
	ctx.surface(details,"WindblownPetals",petal_faces,"BlossomDark")
	# Rubble and ferns feather the terrain into the garden rather than framing a board.
	for i in range(42):
		var side := -1 if i%2 else 1
		var p := Vector3(side*ctx.rng.randf_range(11.7,12.35),.02,ctx.rng.randf_range(-7.5,11.2))
		var slab := ctx.rock(details,"BuriedStone%02d"%i,p,Vector3(ctx.rng.randf_range(.15,.45),.08,ctx.rng.randf_range(.2,.5)),"Stone")
		slab.rotation.z = ctx.rng.randf_range(-.13,.13)
		if i%3==0:
			fern(ctx,details,"EdgeFern%02d"%i,p+Vector3(.1,0,.1),.48)
	# Fallen carved stones beside the approach echo the concept's reclaimed ruins.
	for side in [-1,1]:
		for i in range(4):
			var p := Vector3(side*(4.5+i*.55),.15,13.1+sin(i)*.8)
			var block := ctx.box(details,"ApproachRubble%d_%d"%[side,i],p,Vector3(.6,.3,.7),"Stone")
			block.rotation.y = i*.43
			fern(ctx,details,"ApproachFern%d_%d"%[side,i],p+Vector3(.3,0,.2),.65)
