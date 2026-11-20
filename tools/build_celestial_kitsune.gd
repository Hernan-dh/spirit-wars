extends "res://tools/unit_visual_builder.gd"
## Deterministic, editable native mesh authoring. No runtime generation or imports.
## godot --headless --path . --script tools/build_celestial_kitsune.gd
var fur: StandardMaterial3D
var warm_fur: StandardMaterial3D
var red: StandardMaterial3D
var gold: StandardMaterial3D
var dark: StandardMaterial3D
var light: StandardMaterial3D

func oval(parent: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var n := mesh(parent, label, sphere, mat)
	n.position = pos
	n.scale = size
	return n

func smooth_path(points: Array[Vector3], steps := 5) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for i in range(points.size() - 1):
		for j in steps:
			result.append(points[i].cubic_interpolate(points[i + 1], points[maxi(0, i - 1)], points[mini(points.size() - 1, i + 2)], float(j) / steps))
	result.append(points[-1])
	return result

# Parallel cross sections create continuous, rounded anatomy and tapered fur.
func sweep(parent: Node3D, label: String, path: Array[Vector3], widths: Array[float], depths: Array[float], mat: Material, colors: Array[Color] = []) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	const SIDES := 12
	for i in path.size():
		var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := Vector3.RIGHT.slide(tangent).normalized()
		if side.length_squared() < .01:
			side = Vector3.UP.slide(tangent).normalized()
		var up := tangent.cross(side).normalized()
		var ring := PackedVector3Array()
		for j in SIDES:
			var angle := TAU * j / SIDES
			ring.append(path[i] + side * cos(angle) * widths[i] + up * sin(angle) * depths[i])
		rings.append(ring)
	for i in range(path.size() - 1):
		for j in SIDES:
			var k := (j + 1) % SIDES
			for corner in [Vector2i(i,j), Vector2i(i+1,j), Vector2i(i+1,k), Vector2i(i,j), Vector2i(i+1,k), Vector2i(i,k)]:
				st.set_color(colors[corner.x] if not colors.is_empty() else Color.WHITE)
				st.add_vertex(rings[corner.x][corner.y])
	# Cap both ends for solid ornaments and limbs.
	for end in [0, path.size() - 1]:
		for j in SIDES:
			st.set_color(colors[end] if not colors.is_empty() else Color.WHITE)
			st.add_vertex(path[end])
			st.add_vertex(rings[end][j] if end == 0 else rings[end][(j + 1) % SIDES])
			st.add_vertex(rings[end][(j + 1) % SIDES] if end == 0 else rings[end][j])
	st.generate_normals()
	return mesh(parent, label, st.commit(), mat)

func strand(parent: Node3D, label: String, points: Array[Vector3], radius: float, mat: Material) -> void:
	var path := smooth_path(points, 3)
	var widths: Array[float] = []
	for i in path.size():
		widths.append(radius * (1.0 - .65 * float(i) / (path.size() - 1)))
	sweep(parent, label, path, widths, widths, mat)

func tuft(parent: Node3D, label: String, points: Array[Vector3], width: float, mat: Material) -> void:
	var path := smooth_path(points, 4)
	var widths: Array[float] = []
	var depths: Array[float] = []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		widths.append(maxf(.002, width * (1.0 - t) * (.65 + sin(t * PI))))
		depths.append(widths[-1] * .55)
	sweep(parent, label, path, widths, depths, mat)

func ear(parent: Node3D, side: float) -> void:
	var n := node(parent, "EarLeft" if side < 0 else "EarRight")
	# Rounded, hollow-looking triangular pinna with a smaller vermilion inset.
	var vertices := [Vector3(side*.075,1.79,-.66), Vector3(side*.32,1.78,-.58), Vector3(side*.29,2.22,-.51), Vector3(side*.18,1.88,-.42)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[0,1,2],[1,3,2],[3,0,2],[0,3,1]]:
		for index in tri:
			st.add_vertex(vertices[index])
	st.generate_normals()
	var m := fur.duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh(n,"IvoryPinna",st.commit(),m)
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in [Vector3(side*.13,1.83,-.672),Vector3(side*.275,1.83,-.62),Vector3(side*.278,2.12,-.55)]:
		st.add_vertex(p)
	st.generate_normals()
	m = red.duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh(n,"RoseInnerEar",st.commit(),m)

func leg(parent: Node3D, side: float, rear: bool) -> void:
	var z := .43 if rear else -.43
	var x := side * .23
	var n := node(parent, ("Rear" if rear else "Fore") + ("LeftLeg" if side < 0 else "RightLeg"))
	# Digitigrade hocks and slender wrists; one forepaw is lifted.
	var lift := .15 if not rear and side > 0 else 0.0
	var points: Array[Vector3] = [Vector3(x,.99,z),Vector3(x*1.2,.70,z + (.16 if rear else .02)),Vector3(x*1.15,.39 + lift,z + (.24 if rear else -.02)),Vector3(x*1.12,.17 + lift,z - .09)]
	var path := smooth_path(points)
	var w: Array[float] = []
	var d: Array[float] = []
	for i in path.size():
		var t := float(i)/(path.size()-1)
		w.append(lerpf(.115 if rear else .09,.045,t))
		d.append(lerpf(.16 if rear else .11,.055,t))
	sweep(n,"TaperedLimb",path,w,d,fur)
	oval(n,"Paw",Vector3(x*1.12,.13+lift,z-.14),Vector3(.075,.065,.13),fur)
	oval(n,"RedSock",Vector3(x*1.12,.19+lift,z-.09),Vector3(.048,.058,.058),red)
	for toe in [-1,0,1]:
		strand(n,"Toe%d" % toe,[Vector3(x*1.12+toe*.033,.14+lift,z-.248),Vector3(x*1.12+toe*.033,.11+lift,z-.255)],.008,red)
	if not rear:
		strand(n,"GoldAnklet",[Vector3(x-.047,.26+lift,z-.09),Vector3(x,.245+lift,z-.15),Vector3(x+.047,.26+lift,z-.09)],.014,gold)

func tail(parent: Node3D, index: int, controls: Array[Vector3], tint: Color) -> void:
	var n := node(parent,"Tail%d" % index,Vector3(0,.92,.51))
	var path := smooth_path(controls,8)
	var widths: Array[float] = []
	var depths: Array[float] = []
	var colors: Array[Color] = []
	for i in path.size():
		var t := float(i)/(path.size()-1)
		var width := (.065 + sin(t*PI)*.16) * pow(1.0-t,.35)
		widths.append(maxf(.001,width))
		depths.append(maxf(.001,width*.72))
		var c := Color("e8e8ff").lerp(tint, smoothstep(.10,.72,t))
		c = c.lerp(Color("fff0ff"),smoothstep(.82,1.0,t))
		colors.append(c)
	var tail_mat := ShaderMaterial.new()
	tail_mat.shader = load("res://materials/kitsune_spirit.gdshader")
	sweep(n,"SpiritPlume",path,widths,depths,tail_mat,colors)
	# Lightning-like calligraphy is part of the saved mesh, readable without bloom.
	var vein: Array[Vector3] = []
	for i in range(3,path.size()-2,2):
		var p := path[i]
		p.z -= depths[i] * .96
		p.x += sin(i*1.75+index)*widths[i]*.27
		vein.append(p)
	strand(n,"SacredLightVein",vein,.012,light)
	for fork_index in [12,22]:
		var j := clampi(fork_index, 0, path.size() - 1)
		var p := path[j] + Vector3(0,0,-depths[j])
		strand(n,"Fork%d" % j,[p,p+Vector3(widths[j]*.55,.05,-.005),p+Vector3(widths[j]*.85,.14,0)],.008,light)

func _initialize() -> void:
	material_roughness = .48
	begin_visual("KitsuneVisual")
	fur = material("f3edff",.035)
	warm_fur = material("c5b8e0")
	red = material("d83258",.06)
	gold = material("edb44e",.16,.65)
	dark = material("241f42")
	light = material("e9d7ff",.8)
	light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var body := node(visual,"FoxBody")
	oval(body,"LitheTorso",Vector3(0,.99,.05),Vector3(.265,.31,.61),fur)
	oval(body,"Haunches",Vector3(0,1.00,.43),Vector3(.28,.31,.29),fur)
	oval(body,"RaisedChest",Vector3(0,1.10,-.40),Vector3(.26,.38,.27),fur)
	var neck := oval(body,"ProudNeck",Vector3(0,1.38,-.45),Vector3(.205,.37,.23),fur)
	neck.rotation.x = -.25
	# A pointed ruff breaks the smooth chest into a layered fox silhouette.
	for side in [-1.0,1.0]:
		for i in 4:
			tuft(body,"CheekRuff%s_%d" % [side,i],[Vector3(side*.13,1.52-i*.09,-.49),Vector3(side*(.28+i*.015),1.48-i*.10,-.42),Vector3(side*(.35-i*.01),1.43-i*.12,-.34)],.10,fur)
	for i in 5:
		var x := (i-2)*.065
		tuft(body,"ChestMane%d" % i,[Vector3(x,1.37,-.62),Vector3(x*1.2,1.12,-.69),Vector3(x*.7,.88-absf(x)*.4,-.57)],.09,fur)
	var head := node(body,"Head")
	oval(head,"FoxSkull",Vector3(0,1.66,-.61),Vector3(.23,.23,.26),fur)
	# A long tapering muzzle, with a distinct nose and lower jaw.
	sweep(head,"PointedMuzzle",[Vector3(0,1.61,-.68),Vector3(0,1.59,-.82),Vector3(0,1.56,-1.01)],[.17,.125,.035],[.13,.085,.035],fur)
	oval(head,"LowerJaw",Vector3(0,1.51,-.83),Vector3(.105,.045,.17),fur)
	oval(head,"OnyxNose",Vector3(0,1.565,-1.015),Vector3(.044,.03,.027),dark)
	for side in [-1.0,1.0]:
		ear(head,side)
		var eye := oval(head,"Eye%s" % side,Vector3(side*.171,1.694,-.785),Vector3(.026,.033,.075),dark)
		eye.rotation.z = side*.2
		oval(head,"AmberIris%s" % side,Vector3(side*.192,1.697,-.807),Vector3(.012,.024,.031),gold)
		oval(head,"EyeGlint%s" % side,Vector3(side*.199,1.71,-.819),Vector3(.008,.009,.009),light)
		strand(head,"CrimsonBrow%s" % side,[Vector3(side*.14,1.74,-.82),Vector3(side*.20,1.76,-.75),Vector3(side*.235,1.79,-.67)],.025,red)
		strand(head,"CheekSeal%s" % side,[Vector3(side*.18,1.62,-.79),Vector3(side*.22,1.59,-.70),Vector3(side*.25,1.62,-.63)],.018,red)
		strand(head,"Smile%s" % side,[Vector3(side*.035,1.535,-.99),Vector3(side*.10,1.52,-.86),Vector3(side*.15,1.55,-.77)],.006,dark)
		tuft(head,"CheekTuft%s" % side,[Vector3(side*.15,1.60,-.55),Vector3(side*.29,1.57,-.48),Vector3(side*.37,1.63,-.36)],.105,fur)
	tuft(head,"ForeheadSeal",[Vector3(0,1.89,-.681),Vector3(0,1.82,-.798),Vector3(0,1.75,-.831)],.032,red)
	for side in [-1.0,1.0]:
		leg(body,side,true)
		leg(body,side,false)
	# Vermilion braided collar, gilded bells, central sacred mirror, hanging ties.
	var collar: Array[Vector3] = []
	for i in 33:
		var a := TAU*i/32
		collar.append(Vector3(cos(a)*.25,1.30+sin(a)*.06,-.43+sin(a)*.25))
	strand(body,"VermilionCollar",collar,.037,red)
	for i in 7:
		var a := PI + PI*i/6
		var p := Vector3(cos(a)*.27,1.26,-.43+sin(a)*.27)
		oval(body,"CollarBead%d" % i,p,Vector3(.052,.052,.052),gold)
		if i % 2 == 1:
			oval(body,"Bell%d" % i,p+Vector3(0,-.09,0),Vector3(.064,.074,.064),gold)
			strand(body,"BellSlit%d" % i,[p+Vector3(-.025,-.11,-.06),p+Vector3(.025,-.11,-.06)],.006,dark)
	oval(body,"MirrorRim",Vector3(0,1.17,-.735),Vector3(.11,.14,.035),gold)
	oval(body,"SacredAmethyst",Vector3(0,1.18,-.77),Vector3(.065,.09,.022),material("b684f3",.5,.25))
	for side in [-1.0,1.0]:
		strand(body,"PrayerTie%s" % side,[Vector3(side*.10,1.22,-.70),Vector3(side*.20,1.04,-.69),Vector3(side*.18,.85,-.60)],.025,red)
		oval(body,"TieBead%s" % side,Vector3(side*.18,.87,-.60),Vector3(.038,.045,.038),gold)
		for i in 4:
			strand(body,"Tassel%s_%d" % [side,i],[Vector3(side*.18,.84,-.60),Vector3(side*(.18+i*.013),.70,-.57)],.009,red)
	var tails := node(visual,"Tails")
	# Nine separate plumes form an asymmetrical, ascending fan behind the fox.
	tail(tails,0,[Vector3.ZERO,Vector3(-.35,.10,.33),Vector3(-.95,.05,.45),Vector3(-1.12,.39,.46),Vector3(-.98,.55,.48)],Color("ed73b9"))
	tail(tails,1,[Vector3.ZERO,Vector3(.37,.08,.36),Vector3(.96,.15,.50),Vector3(1.12,.47,.48),Vector3(.96,.63,.48)],Color("a88bf8"))
	tail(tails,2,[Vector3.ZERO,Vector3(-.38,.42,.47),Vector3(-1.04,.68,.53),Vector3(-1.19,1.01,.54),Vector3(-1.03,1.17,.55)],Color("8979f7"))
	tail(tails,3,[Vector3.ZERO,Vector3(.35,.40,.58),Vector3(.98,.77,.63),Vector3(1.05,1.12,.62),Vector3(.87,1.28,.61)],Color("e482e5"))
	tail(tails,4,[Vector3.ZERO,Vector3(-.23,.66,.75),Vector3(-.65,1.18,.78),Vector3(-.58,1.58,.72),Vector3(-.39,1.68,.65)],Color("d863d9"))
	tail(tails,5,[Vector3.ZERO,Vector3(.22,.70,.80),Vector3(.58,1.34,.79),Vector3(.55,1.70,.70),Vector3(.32,1.83,.64)],Color("b18afc"))
	tail(tails,6,[Vector3.ZERO,Vector3(-.45,.31,.20),Vector3(-.78,.45,.09),Vector3(-.97,.72,.10),Vector3(-.90,.86,.12)],Color("66b8ff"))
	tail(tails,7,[Vector3.ZERO,Vector3(.43,.30,.28),Vector3(.72,.53,.24),Vector3(.79,.82,.22),Vector3(.65,.98,.21)],Color("8099ff"))
	tail(tails,8,[Vector3.ZERO,Vector3(-.04,.89,1.03),Vector3(-.08,1.70,1.0),Vector3(.06,1.97,.91),Vector3(.26,2.01,.80)],Color("f68cbb"))
	# A few suspended diamond motes underline the sacred-light silhouette.
	var motes := node(visual,"Motes")
	for i in 8:
		var a := TAU*i/8
		var p := Vector3(cos(a)*1.19,1.55+sin(i*2.4)*.54,.66+sin(a)*.48)
		var gem := SphereMesh.new()
		gem.radius = .027
		gem.height = .11
		gem.radial_segments = 4
		gem.rings = 1
		var n := mesh(motes,"Star%d" % i,gem,light)
		n.position = p
	var glow := OmniLight3D.new()
	glow.name = "SpiritLight"
	visual.add_child(glow)
	glow.owner = visual
	glow.position = Vector3(0,1.6,.7)
	glow.light_color = Color("b186ff")
	glow.light_energy = .35
	glow.omni_range = 2.5
	save_visual("res://scenes/units/kitsune_visual.tscn")
