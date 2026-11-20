extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
const GroundZones = preload("res://tools/battlefield/ground_zones.gd")
const LevelPlan = preload("res://tools/battlefield/level_plan.gd")
## Surrounding landscape features: island rim, terraces, wetlands, gardens,
## ruins and sanctuary details. Placement and tuning data lives in the shared
## LevelPlan resource; everything generated here is baked into ordinary nodes.

static func make_bridge(ctx: AuthoringContext, root: Node3D) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.bridge
	var bridge := ctx.node(root,"GardenBridge")
	var deck_size: Vector3 = data["deck_size"]
	for i in range(int(data["deck_planks"])):
		var x := (i - int(data["deck_half_span"])) * float(data["deck_spacing"])
		var y := float(data["deck_arch_height"])*(1.0-pow(x/float(data["deck_arch_radius"]),2))
		ctx.box(bridge,"DeckPlank%02d"%i,Vector3(x,y,0),deck_size,"WoodLight")
	for side in [-1,1]:
		var rail: Array = []
		for i in range(int(data["rail_posts"])):
			var x := (i - int(data["rail_half_span"])) * float(data["rail_spacing"])
			var y := float(data["deck_arch_height"])*(1.0-pow(x/float(data["deck_arch_radius"]),2))
			ctx.box(bridge,"Post%d_%d"%[side,i],Vector3(x,y+float(data["post_y_offset"]),side*float(data["post_offset_z"])),data["post_size"],"Wood")
			ctx.rock(bridge,"Cap%d_%d"%[side,i],Vector3(x,y+float(data["cap_height"]),side*float(data["post_offset_z"])),data["cap_size"],"Gold")
			rail.append(Vector3(x,y+float(data["rail_height"]),side*float(data["post_offset_z"])))
		ctx.line(bridge,"ArchedRail%d"%side,rail,float(data["rail_radius"]),"WoodLight")

# The expanded landscape is baked to ordinary scene nodes by this authoring tool.
# Nothing here runs in the game; each named terrace, rock and plant can be edited.
static func terrace(ctx: AuthoringContext, parent: Node, title: String, center: Vector3, radius: Vector2, height: float) -> Node3D:
	var plan := LevelPlan.load_default()
	if plan == null:
		return null
	var data: Dictionary = plan.terrain
	var layers := int(data["layers"])
	var sides := int(data["sides"])
	var insets: Array = data["insets"]
	var n := ctx.node(parent, title, center)
	var rings: Array = []
	for layer in range(layers):
		var points: Array = []
		for i in range(sides):
			var a := TAU * i / float(sides)
			var r := 1.0 + sin(i * float(data["radius_frequency"])) * float(data["radius_wave"])
			var inset: float = insets[layer]
			var y: float = [float(data["bottom_y"]), height*float(data["middle_height"]), height][layer]
			points.append(Vector3(cos(a)*radius.x*r*inset, y, sin(a)*radius.y*r*inset))
		rings.append(points)
	for layer in range(layers - 1):
		var faces: Array = []
		for i in range(sides):
			var j := (i+1)%sides
			ctx.tri(faces, rings[layer][i], rings[layer+1][i], rings[layer][j])
			ctx.tri(faces, rings[layer][j], rings[layer+1][i], rings[layer+1][j])
		ctx.surface(n, "Bedrock" if layer == 0 else "WeatheredRim", faces, "Cliff" if layer == 0 else "CliffLight")
	var top: Array = []
	for i in range(sides):
		ctx.tri(top, Vector3(0,height,0), rings[layers-1][(i+1)%sides], rings[layers-1][i])
	ctx.surface(n,"MossyCrown",top,"Moss")
	var boulder_count := int(data["boulders"])
	var boulder_size: Vector3 = data["boulder_size"]
	var skip_titles: Array = data["boulder_skip_titles"]
	for i in range(boulder_count):
		if i == int(data["boulder_skip_index"]) and title in skip_titles:
			continue # Keep the spring and spillway free of crown boulders.
		var a := TAU*i/float(boulder_count)
		var p := Vector3(
			cos(a)*radius.x*float(data["boulder_radius"]),
			height-float(data["boulder_drop"]),
			sin(a)*radius.y*float(data["boulder_radius"])
		)
		ctx.rock(n,"CrownBoulder%02d"%i,p,boulder_size,"Moss" if i%3 else "Stone")
	# Offset facets, shelves and vines break up the large, smooth cliff faces.
	var buttress_count := int(data["buttresses"])
	for i in range(buttress_count):
		var a := TAU*i/float(buttress_count)
		var h := height*(float(data["buttress_height_min"])+float(data["buttress_height_span"])*(sin(i*float(data["buttress_height_frequency"]))*.5+.5))
		var p := Vector3(cos(a)*radius.x*float(data["buttress_radius"]),h*.5,sin(a)*radius.y*float(data["buttress_radius"]))
		var buttress := ctx.cylinder(n,"ErodedButtress%02d"%i,p,float(data["buttress_bottom_radius"]),float(data["buttress_top_radius"]),h,"CliffLight" if i%3 else "Cliff",int(data["buttress_sides"]))
		buttress.rotation.y = a
		ctx.rock(n,"MossShelf%02d"%i,p+Vector3(0,h*float(data["shelf_offset_y"]),0),data["shelf_size"],"Moss")
		if i%2 == 0:
			var start := Vector3(cos(a)*radius.x*float(data["vine_radius"]),height,sin(a)*radius.y*float(data["vine_radius"]))
			var step_2: Vector3 = data["vine_step_2"]
			ctx.line(n,"CliffVine%02d"%i,[start,start+data["vine_step_1"],start+Vector3(step_2.x,-minf(height*.55,float(data["vine_max_height"])),step_2.z)],float(data["vine_line_radius"]),"Leaf")
	return n

static func ring_mesh(ctx: AuthoringContext, parent: Node, title: String, center: Vector3, radius: float, thickness: float, mat: String) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius-thickness
	torus.outer_radius = radius+thickness
	torus.rings = 40
	torus.ring_segments = 6
	return ctx.mesh(parent,title,torus,mat,center)

static func fern(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, size := 1.0) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.prop_templates["fern"]
	var n := ctx.node(parent,title,pos)
	n.scale *= size
	n.set_meta("batch_scenery", true)
	if ctx.fern_geometry != null:
		ctx.mesh(n, "FeatheredFronds", ctx.fern_geometry, String(data["material"]))
		return
	var fronds: Array = []
	var frond_count := int(data["fronds"])
	var steps := int(data["steps"])
	var length := float(data["length"])
	var step_overlap := float(data["step_overlap"])
	var height := float(data["height"])
	var height_base := float(data["height_base"])
	var height_frequency := float(data["height_frequency"])
	var stem_half := float(data["stem_half_width"])
	var leaf_width := float(data["leaf_width"])
	var leaf_min_width := float(data["leaf_min_width"])
	var leaf_length := float(data["leaf_length"])
	var leaf_mid_lift := float(data["leaf_mid_lift"])
	var leaf_depth := float(data["leaf_depth"])
	for i in range(frond_count):
		var a := i*TAU/float(frond_count)
		var d := Vector3(cos(a),0,sin(a))
		var side := Vector3(-sin(a),0,cos(a))
		for j in range(steps):
			var t := j/float(steps)
			var mid := d*t*length+Vector3.UP*(sin(t*PI*height_frequency)*height+height_base)
			var next := d*(t+step_overlap)*length+Vector3.UP*(sin((t+step_overlap)*PI*height_frequency)*height+height_base)
			ctx.tri(fronds,mid-side*stem_half,mid+side*stem_half,next)
			ctx.tri(fronds,mid+side*stem_half,mid-side*stem_half,next)
			for direction in [-1,1]:
				var tip: Vector3 = mid+side*direction*(leaf_width*(1.0-t)+leaf_min_width)+d*leaf_length
				var middle := mid.lerp(tip,.5)+Vector3.UP*leaf_mid_lift
				ctx.tri(fronds,mid,middle-d*leaf_depth,tip)
				ctx.tri(fronds,mid,tip,middle+d*leaf_depth)
				ctx.tri(fronds,mid,tip,middle-d*leaf_depth)
				ctx.tri(fronds,mid,middle+d*leaf_depth,tip)
	ctx.fern_geometry = ctx.surface(n,"FeatheredFronds",fronds,String(data["material"])).mesh

static func banner(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, yaw := 0.0) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.prop_templates["banner"]
	var n := ctx.node(parent,title,pos)
	n.rotation.y = yaw
	for side in [-1,1]:
		var x: float = side*float(data["post_offset_x"])
		ctx.cylinder(n,"StoneFoot%d"%side,Vector3(x,float(data["foot_y"]),0),float(data["foot_bottom"]),float(data["foot_top"]),float(data["foot_height"]),"StoneDark")
		ctx.rod(n,"Pole%d"%side,Vector3(x,float(data["pole_bottom_y"]),0),Vector3(x,float(data["pole_top_y"]),0),float(data["pole_radius"]),"Wood")
		ctx.rock(n,"Finial%d"%side,Vector3(x,float(data["finial_y"]),0),data["finial_size"],"Gold")
	ctx.line(n,"Suspension",data["suspension_points"],float(data["suspension_radius"]),"Gold")
	var flag_count := int(data["flag_count"])
	for i in range(flag_count):
		var x := (i-float(data["flag_center"]))*float(data["flag_spacing"])
		var y := float(data["flag_y"])+absf(x)*float(data["flag_y_slope"])
		var half_width := float(data["flag_half_width"])
		var bottom_half_width := float(data["flag_bottom_half_width"])
		var bottom_drop := float(data["flag_bottom_drop"])
		var depth := float(data["flag_depth"])
		var cloth := [Vector3(x-half_width,y,0),Vector3(x+half_width,y,0),Vector3(x+bottom_half_width,y-bottom_drop,depth),Vector3(x-half_width,y,0),Vector3(x+bottom_half_width,y-bottom_drop,depth),Vector3(x-float(data["flag_tip_x"]),y-float(data["flag_tip_drop"]),float(data["flag_tip_depth"]))]
		var flag := ctx.surface(n,"HangingSilk%d"%i,cloth,"Cloth")
		flag.material_override = ctx.two_sided(flag.material_override)
		for j in range(int(data["stitch_count"])):
			var seal := ctx.box(n,"GoldStitch%d_%d"%[i,j],Vector3(x,y+float(data["stitch_y_offset"])+j*float(data["stitch_y_step"]),float(data["stitch_z"])),data["stitch_size"],"Gold")
			seal.rotation.z = PI/4
static func brazier(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.prop_templates["brazier"]
	var n := ctx.node(parent,title,pos)
	var part_keys := ["plinth", "stem", "bowl", "coals"]
	var part_names := ["Plinth", "Stem", "BronzeBowl", "Coals"]
	for i in range(part_keys.size()):
		var part: Dictionary = data[part_keys[i]]
		ctx.cylinder(n,part_names[i],part["position"],float(part["bottom_radius"]),float(part["top_radius"]),float(part["height"]),String(part["material"]))
	var flame_count := int(data["flame_count"])
	var flame_size: Vector3 = data["flame_size"]
	for i in range(flame_count):
		var a := i*TAU/float(flame_count)
		var flame := ctx.rock(n,"SpiritFlame%d"%i,Vector3(cos(a)*float(data["flame_radius"]),float(data["flame_y"]),sin(a)*float(data["flame_radius"])),Vector3(flame_size.x,flame_size.y+i*float(data["flame_height_step"]),flame_size.z),String(data["flame_material"]))
		flame.rotation.z = sin(a)*float(data["flame_tilt"])
static func pavilion(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, size := 1.0) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.prop_templates["pavilion"]
	var n := ctx.node(parent,title,pos)
	n.scale *= size
	ctx.box(n,"Foundation",data["foundation_position"],data["foundation_size"],"StoneDark")
	ctx.box(n,"StoneFloor",data["floor_position"],data["floor_size"],"StoneLight")
	for x in [-1,1]:
		for z in [-1,1]:
			var p := Vector3(x*float(data["pillar_x"]),float(data["pillar_y"]),z*float(data["pillar_z"]))
			ctx.cylinder(n,"Pillar%d_%d"%[x,z],p,float(data["pillar_bottom"]),float(data["pillar_top"]),float(data["pillar_height"]),"Wood")
			ctx.cylinder(n,"GiltFoot%d_%d"%[x,z],Vector3(p.x,float(data["gilt_foot_y"]),p.z),float(data["gilt_foot_bottom"]),float(data["gilt_foot_top"]),float(data["gilt_foot_height"]),"Gold")
	for side in [-1,1]:
		for j in range(int(data["eave_count"])):
			var x := (j-int(data["eave_center"]))*float(data["eave_spacing"])
			ctx.box(n,"EaveBracket%d_%d"%[side,j],Vector3(x,float(data["eave_y"]),side*float(data["eave_z"])),data["eave_size"],"Wood")
			ctx.box(n,"BracketScroll%d_%d"%[side,j],Vector3(x,float(data["scroll_y"]),side*float(data["scroll_z"])),data["scroll_size"],"Gold")
		for j in range(int(data["screen_count"])):
			ctx.box(n,"RearScreen%d_%d"%[side,j],Vector3(side*(float(data["screen_x_start"])+j*float(data["screen_x_step"])),float(data["screen_y"]),float(data["screen_z"])),data["screen_size"],"WoodLight")
	ctx.box(n,"LintelFront",Vector3(0,float(data["lintel_y"]),float(data["lintel_z"])),data["lintel_size"],"WoodLight")
	ctx.box(n,"LintelRear",Vector3(0,float(data["lintel_y"]),-float(data["lintel_z"])),data["lintel_size"],"WoodLight")
	var r := ctx.roof(n,"SweptRoof",data["roof_position"],float(data["roof_radius"]),float(data["roof_height"]))
	r.scale.z = float(data["roof_scale_z"])
	ctx.roof(n,"UpperRoof",data["upper_roof_position"],float(data["upper_roof_radius"]),float(data["upper_roof_height"]))
	ctx.place(n,"lantern","OfferingLantern",data["lantern_position"],0,float(data["lantern_scale"]))
	for side in [-1,1]:
		ctx.box(n,"Balustrade%d"%side,Vector3(side*float(data["balustrade_x"]),float(data["balustrade_y"]),float(data["balustrade_z"])),data["balustrade_size"],"WoodLight")
		for j in range(int(data["rail_count"])):
			ctx.box(n,"RailSpindle%d_%d"%[side,j],Vector3(side*float(data["rail_x"]),float(data["rail_y"]),float(data["rail_z_start"])+j*float(data["rail_z_step"])),data["rail_size"],"Wood")
static func waterfall(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, height: float, width: float) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.prop_templates["waterfall"]
	var n := ctx.node(parent,title,pos)
	# Opaque ribbons avoid sorting artifacts in the project's Compatibility renderer.
	var ribbon_count := int(data["ribbon_count"])
	var ribbon_span := width/float(data["ribbon_span_divisor"])
	for i in range(ribbon_count):
		var x := (i-int(data["ribbon_center"]))*ribbon_span
		var z := float(data["ribbon_z_wave"])*sin(i*float(data["ribbon_z_frequency"]))
		ctx.box(n,"FallingRibbon%d"%i,Vector3(x,height*.5,z),Vector3(ribbon_span*float(data["ribbon_width_scale"]),height,float(data["ribbon_depth"])),"FallingWater" if i%2 else "Ripple")
		var whitewater: Vector3 = data["whitewater_offset"]
		ctx.rod(n,"Whitewater%d"%i,Vector3(x,height,whitewater.z+z),Vector3(x+whitewater.x,whitewater.y,whitewater.z+z),float(data["whitewater_radius"]),"Foam")
	for i in range(int(data["splash_count"])):
		var ripple := ring_mesh(ctx,n,"SplashRing%d"%i,Vector3(0,float(data["splash_y"])+i*float(data["splash_y_step"]),float(data["splash_z"])),float(data["splash_radius_base"])+i*float(data["splash_radius_step"]),float(data["splash_thickness"]),"Foam")
		ripple.scale.z = float(data["splash_scale_z"])
	var spray_y: Vector2 = data["spray_y_range"]
	var spray_z: Vector2 = data["spray_z_range"]
	for i in range(int(data["spray_count"])):
		ctx.rock(n,"Spray%d"%i,Vector3(ctx.rng.randf_range(-width*float(data["spray_x_scale"]),width*float(data["spray_x_scale"])),ctx.rng.randf_range(spray_y.x,spray_y.y),ctx.rng.randf_range(spray_z.x,spray_z.y)),data["spray_size"],"Foam")
static func make_expanded_landscape(ctx: AuthoringContext, root: Node3D) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var terrain := ctx.node(root,"HighlandTerraces")
	for spec: Dictionary in plan.terraces:
		var center: Vector3 = spec["center"]
		var radius: Vector2 = spec["radius"]
		terrace(ctx,terrain,String(spec["title"]),center,radius,float(spec["height"]))
	# Narrow, irregular columns read as eroded mountain strata, rather than walls.
	var ridge: Dictionary = plan.ridge
	for i in range(int(ridge["count"])):
		var x := float(ridge["start_x"])+i*float(ridge["spacing"])
		var z := float(ridge["z"]) + sin(i*float(ridge["z_frequency"]))*float(ridge["z_wave"])
		var h := float(ridge["base_height"]) + (sin(i*float(ridge["height_frequency"]))+1.0)*float(ridge["height_wave"])
		if x > float(ridge["center_min_x"]) and x < float(ridge["center_max_x"]):
			h = float(ridge["center_height"])
		var column := ctx.cylinder(terrain,"RidgeColumn%02d"%i,Vector3(x,h*.5+float(ridge["column_y_offset"]),z),float(ridge["bottom_radius"]),float(ridge["top_radius"]),h,"Cliff" if i%3 else "CliffLight",int(ridge["sides"]))
		column.rotation.y = i*float(ridge["yaw_step"])
		for ledge in range(int(ridge["ledge_count"])):
			var y := h*(float(ridge["ledge_start"])+ledge*float(ridge["ledge_step"]))
			var shelf := ctx.rock(terrain,"RidgeLedge%d_%d"%[i,ledge],Vector3(x+float(ridge["ledge_x_wave"])*sin(i+ledge),y,z+float(ridge["ledge_z_offset"])),ridge["ledge_size"],"CliffLight")
			shelf.rotation.z = float(ridge["ledge_tilt"])*sin(i)
		ctx.rock(terrain,"RidgeMoss%02d"%i,Vector3(x,h,z)+ridge["moss_offset"],ridge["moss_size"],"Moss")
	# Separated tall peaks give the rear silhouette the concept's vertical rhythm.
	var spires: Dictionary = plan.spires
	for i in range(int(spires["count"])):
		var x := float(spires["start_x"])+i*float(spires["spacing"])
		var h := float(spires["base_height"])+sin(i*float(spires["height_frequency"]))*float(spires["height_wave"])
		var peak := ctx.cylinder(terrain,"DistantSpire%d"%i,Vector3(x,h*.5,float(spires["z"])),float(spires["bottom_radius"]),float(spires["top_radius"]),h,"Cliff",int(spires["sides"]))
		peak.rotation.z = float(spires["tilt"])*sin(i)
		ctx.rock(terrain,"PeakCap%d"%i,Vector3(x,h,float(spires["z"])),spires["cap_size"],"Moss")
	var shrines := ctx.node(root,"HighlandShrines")
	for spec: Dictionary in plan.pavilions:
		var position: Vector3 = spec["position"]
		pavilion(ctx,shrines,String(spec["title"]),position,float(spec["scale"]))
	for spec: Dictionary in plan.shrine_trees:
		var position: Vector3 = spec["position"]
		ctx.place(shrines,"tree",String(spec["title"]),position,float(spec["yaw"]),float(spec["scale"]))
	# Broad stone stairs link the main gate to the elevated sanctuary.
	var stairs: Dictionary = plan.shrine_stairs
	for i in range(int(stairs["count"])):
		var y := (i+1)*float(stairs["height"])/float(stairs["count"])
		var z := float(stairs["z_start"])+i*float(stairs["z_step"])
		ctx.box(shrines,"PilgrimStair%02d"%i,Vector3(float(stairs["x"]),y*.5,z),Vector3(float(stairs["width"]),y,float(stairs["depth"])),"Stone" if i%2 else "StoneLight")
		if i%int(stairs["post_interval"]) == 0:
			for side in [-1,1]:
				ctx.box(shrines,"StairPost%d_%d"%[i,side],Vector3(float(stairs["x"])+side*float(stairs["post_offset_x"]),y+float(stairs["post_height"])*.5,z),Vector3(float(stairs["post_size"]),float(stairs["post_height"]),float(stairs["post_size"])),"StoneDark")
	for spec: Dictionary in plan.shrine_lanterns:
		var position: Vector3 = spec["position"]
		ctx.place(shrines,"lantern",String(spec["title"]),position,float(spec["yaw"]),float(spec["scale"]))
	for spec: Dictionary in plan.shrine_banners:
		var position: Vector3 = spec["position"]
		banner(ctx,shrines,String(spec["title"]),position,float(spec["yaw"]))
	for spec: Dictionary in plan.braziers:
		var position: Vector3 = spec["position"]
		brazier(ctx,shrines,String(spec["title"]),position)

	var wetlands := ctx.node(root,"EasternWetlands")
	var wetland: Dictionary = plan.wetlands
	# An irregular shoreline and winding stream replace the tiny rectangular pond edge.
	var shore: PackedVector2Array = wetland["shore"]
	var faces: Array = []
	var polygon := PackedVector2Array(shore)
	var indices := Geometry2D.triangulate_polygon(polygon)
	var shore_y := float(wetland["shore_y"])
	for i in range(0,indices.size(),3):
		var a := polygon[indices[i]]
		var b := polygon[indices[i+1]]
		var c := polygon[indices[i+2]]
		ctx.tri(faces,Vector3(a.x,shore_y,a.y),Vector3(c.x,shore_y,c.y),Vector3(b.x,shore_y,b.y))
	ctx.surface(wetlands,"LotusLakeAndStream",faces,"Water")
	var shore_rock_size: Vector3 = wetland["shore_rock_size"]
	for i in range(shore.size()):
		var a: Vector2 = shore[i]
		var b: Vector2 = shore[(i+1)%shore.size()]
		for j in range(int(wetland["shore_rocks_per_edge"])):
			var p := a.lerp(b,j/float(wetland["shore_rocks_per_edge"]))
			ctx.rock(wetlands,"ShoreRock%d_%d"%[i,j],Vector3(p.x,float(wetland["shore_rock_y"]),p.y),shore_rock_size,"StoneDark" if j%int(wetland["shore_rock_moss_interval"]) else "Moss")
	var lotus_x: Vector2 = wetland["lotus_x_range"]
	var lotus_z: Vector2 = wetland["lotus_z_range"]
	var lotus_scale: Vector2 = wetland["lotus_scale_range"]
	for i in range(int(wetland["lotus_count"])):
		var p := Vector3(ctx.rng.randf_range(lotus_x.x,lotus_x.y),float(wetland["lotus_y"]),ctx.rng.randf_range(lotus_z.x,lotus_z.y))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),polygon):
			continue
		ctx.place(wetlands,"lotus","LotusCluster%02d"%i,p,ctx.rng.randf()*TAU,ctx.rng.randf_range(lotus_scale.x,lotus_scale.y))
		if i%int(wetland["ripple_interval"]) == 0:
			ring_mesh(ctx,wetlands,"WaterRipple%02d"%i,p,float(wetland["ripple_radius"]),float(wetland["ripple_thickness"]),"Ripple")
		ctx.cylinder(wetlands,"LilyPad%02d"%i,p+wetland["lily_offset"],float(wetland["lily_bottom"]),float(wetland["lily_top"]),float(wetland["lily_height"]),"Leaf",int(wetland["lily_sides"]))
	# Water starts in a visible upper basin and falls over two successive cliff ledges.
	var upper_spring: Dictionary = wetland["upper_spring"]
	ctx.box(wetlands,"UpperSpring",upper_spring["position"],upper_spring["size"],"Water")
	var middle_basin: Dictionary = wetland["middle_basin"]
	ctx.box(wetlands,"MiddleBasin",middle_basin["position"],middle_basin["size"],"Water")
	var spring_banks: Dictionary = wetland["spring_banks"]
	var shelf_banks: Dictionary = wetland["shelf_banks"]
	for side in [-1,1]:
		for i in range(int(spring_banks["count"])):
			ctx.rock(wetlands,"SpringBank%d_%d"%[side,i],Vector3(float(spring_banks["x"])+side*float(spring_banks["offset"]),float(spring_banks["y"]),float(spring_banks["z_start"])+i*float(spring_banks["z_step"])),spring_banks["size"],"Moss" if i%2 else "StoneDark")
		for i in range(int(shelf_banks["count"])):
			ctx.rock(wetlands,"ShelfBank%d_%d"%[side,i],Vector3(float(shelf_banks["x"])+side*float(shelf_banks["offset"]),float(shelf_banks["y"]),float(shelf_banks["z_start"])+i*float(shelf_banks["z_step"])),shelf_banks["size"],"StoneDark")
	var upper_falls: Dictionary = wetland["upper_falls"]
	waterfall(ctx,wetlands,String(upper_falls["title"]),upper_falls["position"],float(upper_falls["height"]),float(upper_falls["width"]))
	var lower_falls: Dictionary = wetland["lower_falls"]
	waterfall(ctx,wetlands,String(lower_falls["title"]),lower_falls["position"],float(lower_falls["height"]),float(lower_falls["width"]))
	# The second bridge crosses the stream between the shore paths.
	var crossing_data: Dictionary = wetland["crossing"]
	var crossing := ctx.node(wetlands,"StreamCrossing",crossing_data["position"])
	make_bridge(ctx,crossing)
	var bridge := crossing.get_node("GardenBridge") as Node3D
	bridge.position = crossing_data["bridge_position"]
	bridge.scale = crossing_data["bridge_scale"]
	for spec: Dictionary in wetland["bridge_lanterns"]:
		var position: Vector3 = spec["position"]
		ctx.place(wetlands,"lantern",String(spec["title"]),position,float(spec["yaw"]),float(spec["scale"]))
	var stones: Dictionary = wetland["stepping_stones"]
	var stone_start: Vector3 = stones["start"]
	var stone_step: Vector3 = stones["step"]
	for i in range(int(stones["count"])):
		ctx.cylinder(wetlands,"WetlandSteppingStone%d"%i,stone_start+stone_step*i,float(stones["bottom"]),float(stones["top"]),float(stones["height"]),"Stone",int(stones["sides"]))

	var gardens := ctx.node(root,"OuterGardens")
	var garden: Dictionary = plan.gardens
	for spec: Dictionary in garden["trees"]:
		var position: Vector3 = spec["position"]
		ctx.place(gardens,"tree",String(spec["title"]),position,float(spec["yaw"]),float(spec["scale"]))
	for spec: Dictionary in garden["bamboo"]:
		var position: Vector3 = spec["position"]
		ctx.place(gardens,"bamboo",String(spec["title"]),position,float(spec["yaw"]),float(spec["scale"]))
	var planted_boundary := PackedVector2Array()
	for point in plan.island_rim:
		planted_boundary.append(point * plan.landscape_scale * float(garden["boundary_scale"]))
	var fern_x: Vector2 = garden["fern_x_range"]
	var fern_z: Vector2 = garden["fern_z_range"]
	var fern_scale: Vector2 = garden["fern_scale_range"]
	for i in range(int(garden["fern_count"])):
		var p := Vector3(ctx.rng.randf_range(fern_x.x,fern_x.y),0,ctx.rng.randf_range(fern_z.x,fern_z.y))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),planted_boundary):
			continue
		# Keep the playable ground, shore water and terraces clear of tall props.
		if _inside_clear_box(p,garden["clear_boxes"]):
			continue
		fern(ctx,gardens,"GroundFern%03d"%i,p,ctx.rng.randf_range(fern_scale.x,fern_scale.y))
		if i%int(garden["outcrop_interval"]) == 0:
			ctx.rock(gardens,"MossyOutcrop%03d"%i,p,garden["outcrop_size"],"Moss")
	var terrace_x: Vector2 = garden["terrace_fern_x_range"]
	var terrace_z: Vector2 = garden["terrace_fern_z_range"]
	for i in range(int(garden["terrace_fern_count"])):
		var p := Vector3(ctx.rng.randf_range(terrace_x.x,terrace_x.y),float(garden["terrace_fern_y"]),ctx.rng.randf_range(terrace_z.x,terrace_z.y))
		fern(ctx,gardens,"TerraceFern%02d"%i,p,float(garden["terrace_fern_scale"]))
		if i%int(garden["blossom_interval"]) == 0:
			ctx.rock(gardens,"BlossomCarpet%02d"%i,p,garden["blossom_size"],"BlossomDark")
	# A worn approach remains low in the foreground, preserving views of the field.
	var approach := ctx.node(root,"PilgrimApproach")
	var approach_data: Dictionary = plan.approach
	for i in range(int(approach_data["count"])):
		var z := float(approach_data["z_start"])+i*float(approach_data["z_step"])
		ctx.box(approach,"OldFlagstone%02d"%i,Vector3(sin(i*float(approach_data["x_frequency"]))*float(approach_data["x_wave"]),float(approach_data["y"]),z),Vector3(float(approach_data["width"]),float(approach_data["height"]),float(approach_data["depth"])),"Stone" if i%3 else "StoneLight")
		if i in approach_data["lantern_rows"]:
			for side in [-1,1]:
				ctx.place(approach,"lantern","PathLight%d_%d"%[i,side],Vector3(side*float(approach_data["lantern_offset_x"]),0,z+float(approach_data["lantern_z_offset"])),0,float(approach_data["lantern_scale"]))
	for spec: Dictionary in approach_data["banners"]:
		var position: Vector3 = spec["position"]
		banner(ctx,approach,String(spec["title"]),position,float(spec["yaw"]))
		approach.get_node(String(spec["title"])).scale = Vector3.ONE*float(spec["scale"])
	make_ruins(ctx,root)

static func make_ruins(ctx: AuthoringContext, root: Node3D) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.ruins
	var ruins := ctx.node(root,"WesternRuins",data["position"])
	ruins.scale = Vector3.ONE*float(data["scale"])
	for i in range(int(data["paving_count"])):
		var slab := ctx.box(ruins,"BrokenPaving%d"%i,Vector3((i%3-1)*float(data["paving_x_step"]),float(data["paving_y"]),(floori(i/3.0)-1)*float(data["paving_z_step"])),data["paving_size"],"StoneDark" if i%2 else "Stone")
		slab.rotation.y = ctx.rng.randf_range(-float(data["paving_rotation"]),float(data["paving_rotation"]))
	var pillar_data: Dictionary = plan.prop_templates["ruin_pillar"]
	var foot: Dictionary = pillar_data["foot"]
	var shaft: Dictionary = pillar_data["shaft"]
	var overgrowth: Dictionary = pillar_data["overgrowth"]
	var vine: Dictionary = pillar_data["vine"]
	for side in [-1,1]:
		var pillar := ctx.node(ruins,"CarvedPillar%d"%side,Vector3(side*float(data["pillar_offset"]),0,float(data["pillar_z"])))
		ctx.box(pillar,"Foot",foot["position"],foot["size"],String(foot["material"]))
		ctx.box(pillar,"Shaft",shaft["position"],shaft["size"],String(shaft["material"]))
		for y in data["collar_heights"]:
			ctx.box(pillar,"Collar%s"%y,Vector3(0,y,0),pillar_data["collar_size"],String(pillar_data["collar_material"]))
		for j in range(int(data["rune_count"])):
			var glyph := ctx.box(pillar,"InsetRune%d"%j,Vector3(0,float(data["rune_start_y"])+j*float(data["rune_step_y"]),float(data["rune_z"])),data["rune_size"],"SpiritDim")
			glyph.rotation.z = PI/4
		ctx.rock(pillar,"Overgrowth",overgrowth["position"],overgrowth["size"],String(overgrowth["material"]))
		for j in range(int(vine["count"])):
			var x := (j-float(vine["center"]))*float(vine["x_step"])
			ctx.line(pillar,"HangingVine%d"%j,[Vector3(x,float(vine["y_start"]),float(vine["z_start"])),Vector3(x+float(vine["x_jitter"]),float(vine["y_mid"]),float(vine["z_mid"])),Vector3(x,float(vine["y_drop"])-j*float(vine["y_step"]),float(vine["z_end"]))],float(vine["radius"]),String(vine["material"]))
	var fallen_data: Dictionary = data["fallen_lintel"]
	var fallen := ctx.box(ruins,"FallenLintel",fallen_data["position"],fallen_data["size"],"Stone")
	fallen.rotation = fallen_data["rotation"]
	var monolith_data: Dictionary = data["monolith"]
	var monolith := ctx.rock(ruins,"SpiritMonolith",monolith_data["position"],monolith_data["size"],"StoneDark")
	monolith.rotation = Vector3.ZERO
	var spiral_data: Dictionary = data["spiral"]
	var spiral: Array = []
	for i in range(int(spiral_data["count"])):
		var t := i/float(int(spiral_data["count"])-1)
		spiral.append(Vector3(sin(t*TAU*1.5)*float(spiral_data["radius"]),float(spiral_data["height_start"])+t*float(spiral_data["height_span"]),float(spiral_data["z"])))
	ctx.line(ruins,"MonolithInscription",spiral,float(spiral_data["line_radius"]),"Spirit")
	var offering: Dictionary = data["offering_circle"]
	ring_mesh(ctx,ruins,"OfferingCircle",offering["position"],float(offering["radius"]),float(offering["thickness"]),"SpiritDim")
	var lantern: Dictionary = data["lantern"]
	ctx.place(ruins,"lantern",String(lantern["title"]),lantern["position"],float(lantern["yaw"]),float(lantern["scale"]))
	for i in range(int(data["fern_count"])):
		var a := i*TAU/float(data["fern_count"])
		fern(ctx,ruins,"ReclaimedFern%d"%i,Vector3(cos(a)*float(data["fern_radius_x"]),0,sin(a)*float(data["fern_radius_z"])),float(data["fern_scale"]))

static func guardian(ctx: AuthoringContext, parent: Node, title: String, pos: Vector3, yaw: float) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.prop_templates["guardian"]
	var n := ctx.node(parent,title,pos)
	n.rotation.y = yaw
	n.scale = Vector3.ONE*float(data["scale"])
	ctx.box(n,"WeatheredPlinth",data["plinth_position"],data["plinth_size"],"StoneDark")
	ctx.box(n,"CarvedPlinthLip",data["plinth_lip_position"],data["plinth_lip_size"],"StoneLight")
	ctx.rock(n,"Haunches",data["haunches_position"],data["haunches_size"],"Stone")
	ctx.rock(n,"UprightChest",data["chest_position"],data["chest_size"],"StoneLight")
	for side in [-1,1]:
		var foreleg_start: Vector3 = data["foreleg_start"]
		foreleg_start.x *= side
		var foreleg_end: Vector3 = data["foreleg_end"]
		foreleg_end.x *= side
		ctx.rod(n,"Foreleg%d"%side,foreleg_start,foreleg_end,float(data["foreleg_radius"]),"StoneLight",float(data["foreleg_top"]))
		var paw_position: Vector3 = data["paw_position"]
		paw_position.x *= side
		ctx.rock(n,"Paw%d"%side,paw_position,data["paw_size"],"StoneLight")
		var toe_count := int(data["toe_count"])
		for toe in range(toe_count):
			var toe_x: float = side*float(data["paw_position"].x)+(toe-(toe_count-1)*.5)*float(data["toe_spacing"])
			ctx.rock(n,"Toe%d_%d"%[side,toe],Vector3(toe_x,float(data["toe_y"]),float(data["toe_z"])),data["toe_size"],"Stone")
	ctx.rock(n,"GuardianHead",data["head_position"],data["head_size"],"StoneLight")
	ctx.rock(n,"Muzzle",data["muzzle_position"],data["muzzle_size"],"StoneLight")
	ctx.rock(n,"Nose",data["nose_position"],data["nose_size"],"StoneDark")
	ctx.box(n,"MouthCarving",data["mouth_position"],data["mouth_size"],"StoneDark")
	for side in [-1,1]:
		var ear_position: Vector3 = data["ear_position"]
		ear_position.x *= side
		ctx.rock(n,"Ear%d"%side,ear_position,data["ear_size"],"Stone")
		var eye_socket: Vector3 = data["eye_socket_position"]
		eye_socket.x *= side
		ctx.rock(n,"EyeSocket%d"%side,eye_socket,data["eye_socket_size"],"StoneDark")
		var spirit_eye: Vector3 = data["spirit_eye_position"]
		spirit_eye.x *= side
		ctx.rock(n,"SpiritEye%d"%side,spirit_eye,data["spirit_eye_size"],"SpiritDim")
		var brow: Array = []
		for point in data["brow_points"]:
			var p: Vector3 = point
			p.x *= side
			brow.append(p)
		ctx.line(n,"Brow%d"%side,brow,float(data["brow_radius"]),"StoneLight")
		var whisker: Array = []
		for point in data["whisker_points"]:
			var p: Vector3 = point
			p.x *= side
			whisker.append(p)
		ctx.line(n,"Whisker%d"%side,whisker,float(data["whisker_radius"]),"Gold")
		var fang_position: Vector3 = data["fang_position"]
		fang_position.x *= side
		ctx.cylinder(n,"Fang%d"%side,fang_position,.0,float(data["fang_top"]),float(data["fang_height"]),"Gold")
	# Repeated spiral locks give the guardian a carved cloud mane.
	var mane_count := int(data["mane_count"])
	for i in range(mane_count):
		var a := i*TAU/float(mane_count)
		var center := Vector3(cos(a)*float(data["mane_center_radius"]),float(data["mane_y"])+sin(a)*float(data["mane_y_radius"]),float(data["mane_z"]))
		var curl: Array = []
		var curl_count := int(data["mane_curl_count"])
		for j in range(curl_count):
			var t := j/float(curl_count-1)
			var radius := float(data["mane_curl_radius"])-float(data["mane_curl_taper"])*t
			curl.append(center+Vector3(cos(t*TAU*1.3)*radius,sin(t*TAU*1.3)*radius,float(data["mane_curl_z"])*t))
		ctx.line(n,"CloudMane%02d"%i,curl,float(data["mane_line_radius"]),"Stone")
	ctx.line(n,"CurledTail",data["tail_points"],float(data["tail_radius"]),"Stone")
	for side in [-1,1]:
		for j in range(int(data["relief_count"])):
			var relief_x := (j-float(data["relief_x_center"]))*float(data["relief_x_step"])
			var seal := ctx.box(n,"PlinthRelief%d_%d"%[side,j],Vector3(relief_x,float(data["relief_y"]),side*float(data["relief_z"])),data["relief_size"],"Jade")
			seal.rotation.z = PI/4

static func make_sanctuary_details(ctx: AuthoringContext, root: Node3D) -> void:
	var plan := LevelPlan.load_default()
	if plan == null:
		return
	var data: Dictionary = plan.sanctuary_details
	var details := ctx.node(root,"SanctuaryDetails")
	for spec: Dictionary in data["guardians"]:
		var position: Vector3 = spec["position"]
		guardian(ctx,details,String(spec["title"]),position,float(spec["yaw"]))
	# Low vegetation crosses the logical field boundary, without covering destinations.
	var grass_faces: Array = []
	var petal_faces: Array = []
	var boundary := PackedVector2Array()
	for point in plan.island_rim:
		boundary.append(point*plan.landscape_scale*float(data["boundary_scale"]))
	var grass_x: Vector2 = data["grass_x_range"]
	var grass_z: Vector2 = data["grass_z_range"]
	var west_garden: Dictionary = data["grass_west_garden"]
	var wetland_clear: Dictionary = data["wetland_clear"]
	var grass_height: Vector2 = data["blade_height_range"]
	for i in range(int(data["grass_samples"])):
		var p := Vector3(ctx.rng.randf_range(grass_x.x,grass_x.y),float(data["grass_y"]),ctx.rng.randf_range(grass_z.x,grass_z.y))
		if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),boundary):
			continue
		if p.x > float(west_garden["x_min"]) and p.x < float(west_garden["x_max"]) and p.z > float(west_garden["z_min"]) and p.z < float(west_garden["z_max"]):
			continue
		if p.x > float(wetland_clear["x_min"]) and p.z < float(wetland_clear["z_max"]):
			continue # Wetland water remains clear.
		if GroundZones.is_within_paving_margin(Vector2(p.x,p.z), GroundZones.VEGETATION_CLEARANCE):
			continue
		if sin(p.x*float(data["grass_frequency_x"]))+cos(p.z*float(data["grass_frequency_z"]))<float(data["grass_density_threshold"]):
			continue
		for blade in range(int(data["blades"])):
			var a := ctx.rng.randf()*TAU
			var side := Vector3(cos(a),0,sin(a))*float(data["blade_side"])
			var tip := p+Vector3(sin(a)*float(data["blade_radius"]),ctx.rng.randf_range(grass_height.x,grass_height.y),cos(a)*float(data["blade_radius"]))
			ctx.tri(grass_faces,p-side,p+side,tip)
			ctx.tri(grass_faces,p+side,p-side,tip)
		if i%int(data["petal_interval"])==0:
			var q: Vector3 = p+data["petal_offset"]
			var half_width := float(data["petal_half_width"])
			var half_depth := float(data["petal_half_depth"])
			ctx.tri(petal_faces,q+Vector3(-half_width,0,0),q+Vector3(0,0,half_depth),q+Vector3(half_width,0,0))
			ctx.tri(petal_faces,q+Vector3(-half_width,0,0),q+Vector3(half_width,0,0),q+Vector3(0,0,-half_depth))
	ctx.surface(details,"MeadowGrassAndCreviceShoots",grass_faces,"Grass")
	ctx.surface(details,"WindblownPetals",petal_faces,"BlossomDark")
	# Rubble and ferns feather the terrain into the garden rather than framing a board.
	var rubble_x: Vector2 = data["rubble_x_range"]
	var rubble_z: Vector2 = data["rubble_z_range"]
	var rubble_size_x: Vector2 = data["rubble_size_x_range"]
	var rubble_size_z: Vector2 = data["rubble_size_z_range"]
	for i in range(int(data["rubble_count"])):
		var side := -1 if i%2 else 1
		var p := Vector3(side*ctx.rng.randf_range(rubble_x.x,rubble_x.y),float(data["rubble_y"]),ctx.rng.randf_range(rubble_z.x,rubble_z.y))
		var slab := ctx.rock(details,"BuriedStone%02d"%i,p,Vector3(ctx.rng.randf_range(rubble_size_x.x,rubble_size_x.y),float(data["rubble_size_y"]),ctx.rng.randf_range(rubble_size_z.x,rubble_size_z.y)),"Stone")
		slab.rotation.z = ctx.rng.randf_range(-float(data["rubble_tilt"]),float(data["rubble_tilt"]))
		if i%int(data["rubble_fern_interval"])==0:
			fern(ctx,details,"EdgeFern%02d"%i,p+data["rubble_fern_offset"],float(data["rubble_fern_scale"]))
	# Fallen carved stones beside the approach echo the concept's reclaimed ruins.
	for side in [-1,1]:
		for i in range(int(data["approach_rubble_count"])):
			var p := Vector3(side*(float(data["approach_rubble_x_start"])+i*float(data["approach_rubble_x_step"])),float(data["approach_rubble_y"]),float(data["approach_rubble_z"])+sin(i)*float(data["approach_rubble_z_wave"]))
			var block := ctx.box(details,"ApproachRubble%d_%d"%[side,i],p,data["approach_rubble_size"],"Stone")
			block.rotation.y = i*float(data["approach_rubble_yaw_step"])
			fern(ctx,details,"ApproachFern%d_%d"%[side,i],p+data["approach_fern_offset"],float(data["approach_fern_scale"]))

static func _inside_clear_box(p: Vector3, boxes: Array) -> bool:
	for box: Dictionary in boxes:
		var x := absf(p.x) if bool(box.get("use_abs_x", false)) else p.x
		if x >= float(box["x_min"]) and x <= float(box["x_max"]) and p.z >= float(box["z_min"]) and p.z <= float(box["z_max"]):
			return true
	return false
