extends SceneTree
## Deterministic, editable native mesh authoring for the Storm Dragon Wisp.
## godot --headless --path . --script tools/build_storm_dragon_wisp.gd
var visual: Node3D
var body_mat: ShaderMaterial
var arc_mat: ShaderMaterial
var pool_mat: ShaderMaterial
var stone: StandardMaterial3D
var stone_light: StandardMaterial3D
var ice: StandardMaterial3D
var snow: StandardMaterial3D
var pink: StandardMaterial3D
var deep: StandardMaterial3D
var violet: StandardMaterial3D
var magenta: StandardMaterial3D
var cyan: StandardMaterial3D
var spark: StandardMaterial3D
var skin: StandardMaterial3D
var glow: StandardMaterial3D
var eye: StandardMaterial3D

func material(color: String, emission := 0.0, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = .46
	m.metallic = metallic
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = emission
	return m

func node(parent: Node, label: String, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = label
	parent.add_child(n)
	n.owner = visual
	n.position = pos
	return n

func mesh(parent: Node3D, label: String, geometry: Mesh, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = geometry
	n.material_override = mat
	parent.add_child(n)
	n.owner = visual
	return n

func oval(parent: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	var n := mesh(parent, label, sphere, mat)
	n.position = pos
	n.scale = size
	return n

func cone(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = radius
	cone_mesh.height = height
	cone_mesh.radial_segments = 10
	var n := mesh(parent, label, cone_mesh, mat)
	n.position = pos
	return n

func smooth_path(points: Array[Vector3], steps := 5) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for i in range(points.size() - 1):
		for j in steps:
			result.append(points[i].cubic_interpolate(points[i + 1], points[maxi(0, i - 1)], points[mini(points.size() - 1, i + 2)], float(j) / steps))
	result.append(points[-1])
	return result

# Parallel cross sections make the serpentine body continuous and tapered.
func sweep(parent: Node3D, label: String, path: Array[Vector3], widths: Array[float], depths: Array[float], mat: Material, colors: Array[Color] = [], sides := 12) -> MeshInstance3D:
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
			for corner in [Vector2i(i,j), Vector2i(i+1,j), Vector2i(i+1,k), Vector2i(i,j), Vector2i(i+1,k), Vector2i(i,k)]:
				st.set_color(colors[corner.x] if not colors.is_empty() else Color.WHITE)
				st.add_vertex(rings[corner.x][corner.y])
	for end in [0, path.size() - 1]:
		for j in sides:
			st.set_color(colors[end] if not colors.is_empty() else Color.WHITE)
			st.add_vertex(path[end])
			st.add_vertex(rings[end][j] if end == 0 else rings[end][(j + 1) % sides])
			st.add_vertex(rings[end][(j + 1) % sides] if end == 0 else rings[end][j])
	st.generate_normals()
	return mesh(parent, label, st.commit(), mat)

func strand(parent: Node3D, label: String, points: Array[Vector3], radius: float, mat: Material) -> MeshInstance3D:
	var path := smooth_path(points, 4)
	var widths: Array[float] = []
	for i in path.size():
		widths.append(radius * (1.0 - .55 * float(i) / (path.size() - 1)))
	return sweep(parent, label, path, widths, widths, mat, [], 7)

# Broad, tapering flame forms are the wisp's mane and trailing storm.
func plume(parent: Node3D, label: String, points: Array[Vector3], width: float) -> MeshInstance3D:
	var path := smooth_path(points, 6)
	var widths: Array[float] = []
	var depths: Array[float] = []
	var colors: Array[Color] = []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		var w := width * (.55 + .55 * sin(t * PI)) * pow(1.0 - t, .42)
		widths.append(maxf(.001,w))
		depths.append(maxf(.001,w * .52))
		var c := Color("aeefff").lerp(Color("9a6bff"),smoothstep(.05,.58,t))
		c = c.lerp(Color("f47be0"),smoothstep(.58,1.0,t))
		colors.append(c)
	return sweep(parent, label, path, widths, depths, body_mat, colors, 10)

func tuft(parent: Node3D, label: String, points: Array[Vector3], width: float, mat: Material) -> void:
	var path := smooth_path(points, 4)
	var widths: Array[float] = []
	var depths: Array[float] = []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		widths.append(maxf(.002, width * (1.0 - t) * (.55 + sin(t * PI))))
		depths.append(widths[-1] * .5)
	sweep(parent, label, path, widths, depths, mat, [], 8)

func fin(parent: Node3D, label: String, corners: Array[Vector3], mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[0,1,2],[0,2,3]]:
		for index in tri:
			st.add_vertex(corners[index])
	st.generate_normals()
	var m := mat.duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh(parent, label, st.commit(), m)

# A jagged lightning ribbon, saved as ordinary editable geometry.
func bolt(parent: Node3D, label: String, start: Vector3, finish: Vector3, seed_value: int, width := .012, forks := true) -> Node3D:
	var holder := node(parent, label)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var controls: Array[Vector3] = [start]
	var steps := 6
	for i in range(1, steps):
		var t := float(i) / steps
		var p := start.lerp(finish, t)
		var side := (finish - start).cross(Vector3.UP).normalized()
		var lift := (finish - start).cross(side).normalized()
		p += side * rng.randf_range(-.06, .06) + lift * rng.randf_range(-.045, .045)
		controls.append(p)
	controls.append(finish)
	var path := smooth_path(controls, 2)
	var widths: Array[float] = []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		widths.append(width * (1.0 - t * .55))
	var bolt_mesh := sweep(holder, "Core", path, widths, widths, arc_mat, [], 5)
	bolt_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if forks:
		for f in 2:
			var origin := path[mini(int(path.size() / 3) + f * int(path.size() / 4), path.size() - 2)]
			var branch_end := origin + (finish - start).normalized() * .12 + Vector3(rng.randf_range(-.12,.12), rng.randf_range(-.06,.15), rng.randf_range(-.12,.12))
			var branch: Array[Vector3] = [origin, origin.lerp(branch_end,.55) + Vector3(rng.randf_range(-.03,.03),rng.randf_range(-.03,.03),rng.randf_range(-.03,.03)), branch_end]
			var bpath := smooth_path(branch, 3)
			var bwidths: Array[float] = []
			for i in bpath.size():
				bwidths.append(width * .62 * (1.0 - float(i) / (bpath.size() - 1)))
			var branch_mesh := sweep(holder, "Fork%d" % f, bpath, bwidths, bwidths, arc_mat, [], 5)
			branch_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return holder

func head_mane(parent: Node3D, side: float, index: int) -> void:
	var start := Vector3(side*(.040 + index*.008),.160 - index*.050,-.05 - index*.030)
	var mid := start + Vector3(side*(.15 + index*.040),.12 - index*.025,-.08 - index*.025)
	var tip := start + Vector3(side*(.32 + index*.065),.20 - index*.10,-.22 - index*.055)
	plume(parent,"Mane%s%d" % ["L" if side < 0 else "R", index],[start,mid,start.lerp(tip,.72) + Vector3(0,.06,0),tip],.042)

func _initialize() -> void:
	visual = Node3D.new()
	visual.name = "StormDragonVisual"
	body_mat = ShaderMaterial.new()
	body_mat.shader = load("res://materials/storm_wisp.gdshader")
	arc_mat = ShaderMaterial.new()
	arc_mat.shader = load("res://materials/storm_arc.gdshader")
	pool_mat = ShaderMaterial.new()
	pool_mat.shader = load("res://materials/storm_pool.gdshader")
	pool_mat.set_shader_parameter("deep_color",Color(.06,.25,.78,1.0))
	pool_mat.set_shader_parameter("glow_color",Color(.55,.95,1.0,1.0))
	arc_mat.set_shader_parameter("arc_color",Color(.72,.95,1.0,1.0))
	arc_mat.set_shader_parameter("core_color",Color(1,1,1,1))
	stone = material("526570")
	stone_light = material("84979e")
	ice = material("9fdcff",.25,.10)
	snow = material("e9fbff",.12)
	pink = material("ef79c4",.16)
	deep = material("11183c")
	violet = material("9a6bff",.30)
	magenta = material("ef6bdd",.42)
	cyan = material("63ddff",.38)
	spark = material("67e8ff",1.3)
	spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skin = material("5b86e8",.10)
	glow = material("d9fbff",.9)
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye = material("eafcff",1.8)
	eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye.cull_mode = BaseMaterial3D.CULL_DISABLED

	# --- Base: storm pool, ice shards, rock outcrop and lotus petals ---------
	var base := node(visual,"BaseEffects")
	var pool := CylinderMesh.new()
	pool.top_radius = .38
	pool.bottom_radius = .35
	pool.height = .01
	pool.radial_segments = 40
	var disk := mesh(base,"SpiritPool",pool,pool_mat)
	disk.position = Vector3(0,.155,0)
	disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 2:
		var torus := TorusMesh.new()
		torus.inner_radius = .17 + i * .11
		torus.outer_radius = .195 + i * .11
		torus.rings = 40
		torus.ring_segments = 5
		var ripple := mesh(base,"PoolRipple%d" % i,torus,cyan)
		ripple.position = Vector3(0,.17,0)
		ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Pale ice clouds cradle the pool like the concept's frozen plinth.
	var clouds: Array[Vector4] = [
		Vector4(-.31,.19,.16,.115),Vector4(-.40,.21,-.02,.090),
		Vector4(-.25,.21,.27,.072),Vector4(.24,.19,.22,.075)]
	for i in clouds.size():
		var c := clouds[i]
		oval(base,"IceCloud%d" % i,Vector3(c.x,c.y,c.z),Vector3(c.w,c.w*.72,c.w*.88),ice)
	# A small snow-capped stone spire anchors the rear of the islet.
	for i in 3:
		var rock := CylinderMesh.new()
		rock.top_radius = .045 + i*.012
		rock.bottom_radius = .085 + i*.018
		rock.height = .16 + i*.055
		rock.radial_segments = 6
		var n := mesh(base,"StonePeak%d" % i,rock,stone if i != 1 else stone_light)
		n.position = Vector3(.31 - i*.025,.16 + rock.height*.5 + i*.05,-.05 + i*.035)
		n.rotation.y = i * .7
	oval(base,"SnowCap",Vector3(.31,.16 + .16 + .11,.01),Vector3(.075,.035,.068),snow)
	for i in 6:
		var a := TAU * i / 6 + .35
		var petal := oval(base,"LotusPetal%d" % i,Vector3(cos(a)*.44,.165,sin(a)*.44),Vector3(.06,.012,.038),pink)
		petal.rotation.y = -a
	# Curling storm spray at the tail's waterline.
	for i in 4:
		var a := TAU * i / 4 + .4
		tuft(base,"PoolSpray%d" % i,[Vector3(cos(a)*.10,.17,sin(a)*.10),Vector3(cos(a)*.25,.26,sin(a)*.25),Vector3(cos(a)*.33,.40,sin(a)*.33)],.026,cyan)

	# --- Body: a rising double coil with a broad trailing storm ------------
	var storm := node(visual,"StormBody")
	var coil_points: Array[Vector3] = [
		Vector3(.18,.16,.20),Vector3(-.05,.17,.28),Vector3(-.30,.24,.18),
		Vector3(-.38,.36,.02),Vector3(-.22,.46,-.08),Vector3(.02,.48,-.02),
		Vector3(.16,.60,.10),Vector3(-.02,.76,.16),Vector3(-.28,.92,.12),
		Vector3(-.26,1.14,.02),Vector3(.02,1.28,-.04),Vector3(.32,1.40,-.06),
		Vector3(.36,1.62,-.02),Vector3(.16,1.80,.04),Vector3(-.02,1.94,.12),
		Vector3(.10,2.04,.20)]
	var coil := smooth_path(coil_points, 5)
	var coil_widths: Array[float] = []
	var coil_depths: Array[float] = []
	var coil_colors: Array[Color] = []
	var color_stops: Array[Color] = [
		Color("d8f8ff"),Color("9fe6ff"),Color("8b8dff"),Color("a86bff"),
		Color("d473ef"),Color("c07bff"),Color("8f8cff"),Color("6fa5ff"),
		Color("58c9ff"),Color("8f8cff"),Color("b56ff0"),Color("d97ce4"),
		Color("9a8cff"),Color("8fd8ff"),Color("c9f7ff"),Color("e6fcff")]
	var count := coil.size()
	for i in count:
		var t := float(i) / (count - 1)
		var taper := lerpf(.013,.125,smoothstep(0.0,.20,t))
		taper = lerpf(taper,.060,smoothstep(.78,1.0,t))
		coil_widths.append(maxf(.012,taper))
		coil_depths.append(maxf(.012,taper * .80))
		var stop := t * (color_stops.size() - 1)
		var low := clampi(int(floor(stop)),0,color_stops.size()-1)
		var high := clampi(low + 1,0,color_stops.size()-1)
		coil_colors.append(color_stops[low].lerp(color_stops[high],stop - low))
	sweep(storm,"CoiledBody",coil,coil_widths,coil_depths,body_mat,coil_colors,12)
	# A white-hot vein and a few forks run along the coil.
	var vein: Array[Vector3] = []
	for i in range(5,count - 3,2):
		var p := coil[i] + Vector3(0.0,0.0,coil_depths[i] * .86)
		p.x += sin(i * 1.7) * coil_widths[i] * .22
		vein.append(p)
	var vein_mesh := strand(storm,"StormVein",vein,.010,arc_mat)
	vein_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Broad flame plumes flow off the coil, echoing the concept's storm mane.
	plume(storm,"StormPlumeNeck",[Vector3(.04,1.88,.12),Vector3(-.20,2.12,.06),Vector3(-.48,2.20,-.02),Vector3(-.72,2.02,-.10)],.135)
	plume(storm,"StormPlumeRight",[Vector3(.34,1.52,-.02),Vector3(.66,1.72,-.06),Vector3(.94,1.62,-.14),Vector3(1.10,1.38,-.18)],.140)
	plume(storm,"StormPlumeLeft",[Vector3(-.26,1.16,.04),Vector3(-.56,1.36,.00),Vector3(-.86,1.30,-.08),Vector3(-1.02,1.06,-.14)],.140)
	plume(storm,"StormPlumeLowRight",[Vector3(.10,.58,.10),Vector3(.42,.74,.04),Vector3(.68,.68,-.04),Vector3(.80,.44,-.08)],.120)
	plume(storm,"StormPlumeLowLeft",[Vector3(-.24,.44,.00),Vector3(-.48,.56,-.02),Vector3(-.66,.44,-.08),Vector3(-.74,.20,-.10)],.110)
	plume(storm,"StormPlumeBack",[Vector3(-.28,.92,.12),Vector3(-.52,1.04,.08),Vector3(-.72,.96,.02),Vector3(-.82,.74,-.02)],.100)
	plume(storm,"TailFlame",[Vector3(.18,.16,.20),Vector3(.40,.28,.18),Vector3(.56,.48,.10),Vector3(.57,.68,-.02)],.085)
	var arcs := node(storm,"BodyArcs")
	bolt(arcs,"ArcBody0",Vector3(-.40,.50,.10),Vector3(-.20,.71,.18),11,.012)
	bolt(arcs,"ArcBody1",Vector3(.29,.96,.02),Vector3(.48,1.18,.00),23,.011)
	bolt(arcs,"ArcBody2",Vector3(-.02,1.58,-.08),Vector3(.24,1.78,-.05),37,.010)
	bolt(arcs,"ArcBody3",Vector3(.44,1.98,.04),Vector3(.52,.55,.18),51,.009,false)
	bolt(arcs,"ArcBody4",Vector3(-.34,.46,.10),Vector3(-.46,.26,.18),67,.009,false)

	# --- Head: long-jawed eastern dragon with antlers and storm mane --------
	var head := node(storm,"Head",Vector3(.10,2.03,.22))
	head.rotation.x = .01
	head.scale = Vector3(1.12,1.12,1.12)
	oval(head,"Skull",Vector3.ZERO,Vector3(.19,.16,.22),skin)
	oval(head,"LeftCheek",Vector3(-.10,.005,.05),Vector3(.10,.11,.14),violet)
	oval(head,"RightCheek",Vector3(.10,.005,.05),Vector3(.10,.11,.14),violet)
	sweep(head,"LongSnout",[Vector3(0,.055,.08),Vector3(0,.040,.26),Vector3(0,.020,.44),Vector3(0,-.005,.60)],[.130,.110,.080,.048],[.115,.095,.068,.038],body_mat,[Color("2f6dff"),Color("4fa6ff"),Color("8fdcff"),Color("dcf8ff")])
	oval(head,"MuzzleTip",Vector3(0,-.002,.605),Vector3(.058,.042,.042),cyan)
	oval(head,"NoseBridge",Vector3(0,.085,.30),Vector3(.095,.040,.16),skin)
	for side in [-1.0,1.0]:
		oval(head,"Nostril%s" % side,Vector3(side*.028,.020,.63),Vector3(.012,.010,.008),deep)
		var socket := oval(head,"Socket%s" % side,Vector3(side*.128,.095,.285),Vector3(.030,.025,.020),deep)
		socket.rotation.z = side*.30
		var iris := oval(head,"Iris%s" % side,Vector3(side*.145,.100,.300),Vector3(.023,.025,.018),eye)
		iris.rotation.z = side*.30
		oval(head,"Pupil%s" % side,Vector3(side*.150,.101,.313),Vector3(.006,.016,.008),deep)
		strand(head,"Brow%s" % side,[Vector3(side*.035,.165,.34),Vector3(side*.12,.205,.25),Vector3(side*.21,.190,.10)],.026,magenta)
		tuft(head,"CheekSpike%s" % side,[Vector3(side*.155,.050,.29),Vector3(side*.24,.070,.20),Vector3(side*.30,.090,.08)],.026,cyan)
		strand(head,"CheekSeal%s" % side,[Vector3(side*.18,.010,.10),Vector3(side*.23,-.020,.02),Vector3(side*.21,-.045,-.06)],.012,cyan)
		# Antlers fork twice and sweep back over the storm mane.
		sweep(head,"Antler%s" % side,[Vector3(side*.085,.135,-.04),Vector3(side*.18,.30,-.12),Vector3(side*.28,.40,-.25),Vector3(side*.35,.38,-.44)],[.050,.038,.022,.005],[.046,.034,.020,.005],magenta)
		sweep(head,"AntlerFork%s" % side,[Vector3(side*.185,.31,-.13),Vector3(side*.31,.36,-.18),Vector3(side*.40,.45,-.26)],[.024,.014,.004],[.022,.013,.004],violet)
		sweep(head,"AntlerProng%s" % side,[Vector3(side*.22,.37,-.20),Vector3(side*.30,.33,-.31),Vector3(side*.33,.25,-.41)],[.014,.009,.003],[.013,.008,.003],magenta)
		sweep(head,"BackHorn%s" % side,[Vector3(side*.075,.050,-.09),Vector3(side*.22,.080,-.24),Vector3(side*.32,.070,-.41)],[.028,.018,.004],[.026,.016,.004],violet)
		# Webbed jaw fins are separate meshes so they catch the rim light.
		fin(head,"JawFin%s" % side,[Vector3(side*.095,.080,-.03),Vector3(side*.35,.170,-.12),Vector3(side*.29,-.030,-.27),Vector3(side*.070,-.055,-.12)],magenta)
		for i in 4:
			head_mane(head,side,i)
		var whisker := node(head,"Whisker%s" % ("L" if side < 0 else "R"),Vector3(side*.080,-.085,.50))
		strand(whisker,"WhiskerThread",[Vector3.ZERO,Vector3(side*.12,-.010,.02),Vector3(side*.25,.000,-.08),Vector3(side*.38,.080,-.22),Vector3(side*.44,.200,-.38)],.012,spark)
		strand(whisker,"WhiskerBarbA",[Vector3(side*.20,.000,-.05),Vector3(side*.29,.100,-.01),Vector3(side*.34,.155,.02)],.007,spark)
		strand(whisker,"WhiskerBarbB",[Vector3(side*.33,.055,-.17),Vector3(side*.41,.145,-.13)],.006,spark)
	sweep(head,"LowerJaw",[Vector3(0,-.100,.14),Vector3(0,-.140,.32),Vector3(0,-.160,.46)],[.100,.078,.045],[.032,.028,.018],violet)
	oval(head,"MouthCavity",Vector3(0,-.085,.37),Vector3(.100,.055,.190),deep)
	strand(head,"Tongue",[Vector3(0,-.090,.27),Vector3(0,-.125,.37),Vector3(0,-.145,.44)],.024,magenta)
	for side in [-1.0,1.0]:
		for tooth in 3:
			var fang := cone(head,"UpperFang%s%d" % [side,tooth],Vector3(side*(.052 + tooth*.016),-.065 + tooth*.004,.28 + tooth*.085),.011,.040,glow)
			fang.rotation.x = PI
		for tooth in 2:
			var fang := cone(head,"LowerFang%s%d" % [side,tooth],Vector3(side*(.048 + tooth*.016),-.142,.33 + tooth*.095),.009,.030,glow)
			fang.rotation.x = 0.0
	tuft(head,"ChinBeard",[Vector3(0,-.175,.30),Vector3(0,-.235,.18),Vector3(0,-.27,.02)],.044,magenta)
	# A short nasal horn and forehead spikes strengthen the dragon silhouette.
	var nasal := cone(head,"NasalHorn",Vector3(0,.105,.46),.024,.09,magenta)
	nasal.rotation.x = -.45
	for i in 2:
		var spike := cone(head,"CrownSpike%d" % i,Vector3(0,.18 - i*.02,.12 - i*.12),.026 - i*.006,.075,magenta)
		spike.rotation.x = -.55
	sweep(head,"ForeheadCrest",[Vector3(0,.150,.07),Vector3(0,.230,-.04),Vector3(0,.255,-.22)],[.048,.030,.004],[.040,.026,.004],violet)
	var head_arcs := node(head,"HeadArcs")
	bolt(head_arcs,"ArcHorn0",Vector3(.28,.42,-.26),Vector3(.48,.54,-.34),71,.009)
	bolt(head_arcs,"ArcHorn1",Vector3(-.30,.40,-.25),Vector3(-.48,.52,-.33),73,.009)
	bolt(head_arcs,"ArcJaw0",Vector3(.20,-.02,.10),Vector3(.40,.03,.00),79,.008,false)

	var light := OmniLight3D.new()
	light.name = "StormLight"
	storm.add_child(light)
	light.owner = visual
	light.position = Vector3(0,1.55,.18)
	light.light_color = Color("7fd8ff")
	light.light_energy = .55
	light.omni_range = 3.2
	light.shadow_enabled = false

	var packed := PackedScene.new()
	var error := packed.pack(visual)
	if error == OK:
		error = ResourceSaver.save(packed,"res://scenes/units/storm_dragon_visual.tscn")
	visual.free()
	quit(error)
