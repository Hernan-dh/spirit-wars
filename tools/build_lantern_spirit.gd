extends SceneTree
## Author the reusable native-mesh Lantern Spirit; no external asset imports required.
## godot --headless --path . --script tools/build_lantern_spirit.gd
const GeneratedResources = preload("res://tools/generated_resources.gd")
var visual: Node3D
var gold: StandardMaterial3D
var red: StandardMaterial3D
var paper: StandardMaterial3D
var blue: StandardMaterial3D
var ink: StandardMaterial3D

func mat(color: String, glow := 0.0, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.5
	m.metallic = metal
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = glow
	return m

func node(parent: Node, label: String) -> Node3D:
	var n := Node3D.new()
	n.name = label
	parent.add_child(n)
	n.owner = visual
	return n

func mesh(parent: Node3D, label: String, geometry: Mesh, material: Material, position := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = geometry
	n.material_override = material
	parent.add_child(n)
	n.owner = visual
	n.position = position
	return n

func lathe(parent: Node3D, label: String, profile: Array[Vector2], material: Material, segments := 32) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for i in segments:
			var a := TAU * i / segments
			var b := TAU * (i + 1) / segments
			var p := profile[row]
			var q := profile[row + 1]
			var points := [Vector3(p.x*cos(a),p.y,p.x*sin(a)), Vector3(q.x*cos(a),q.y,q.x*sin(a)), Vector3(q.x*cos(b),q.y,q.x*sin(b)), Vector3(p.x*cos(b),p.y,p.x*sin(b))]
			for index in [0,2,1,0,3,2]:
				st.add_vertex(points[index])
	st.generate_normals()
	return mesh(parent, label, st.commit(), material)

func tube(parent: Node3D, label: String, points: Array[Vector3], radius: float, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		var direction := (points[i+1]-points[i]).normalized()
		var side := direction.cross(Vector3.FORWARD).normalized()
		if side.length_squared() < 0.1:
			side = direction.cross(Vector3.UP).normalized()
		var up := direction.cross(side).normalized()
		for j in 6:
			var a := TAU*j/6
			var b := TAU*(j+1)/6
			var v := side*cos(a)*radius + up*sin(a)*radius
			var w := side*cos(b)*radius + up*sin(b)*radius
			for p in [points[i]+v,points[i+1]+v,points[i+1]+w,points[i]+v,points[i+1]+w,points[i]+w]:
				st.add_vertex(p)
	st.generate_normals()
	mesh(parent,label,st.commit(),material)

func ribbon(parent: Node3D, label: String, points: Array[Vector3], width: float, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		var w := Vector3(width*0.5,0,0)
		for p in [points[i]-w, points[i+1]-w,points[i+1]+w,points[i]-w,points[i+1]+w,points[i]+w]:
			st.add_vertex(p)
	st.generate_normals()
	var m := material.duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh(parent,label,st.commit(),m)

func _initialize() -> void:
	GeneratedResources.reset()
	visual = Node3D.new()
	visual.name = "LanternVisual"
	gold = mat("dca94e",0.12,0.65)
	red = mat("ba302d")
	paper = mat("ffb348",0.8)
	blue = mat("193d5a",0.0,0.28)
	ink = mat("b84a20",0.1)
	var body := node(visual,"FloatingBody")
	lathe(body,"PaperLantern",[Vector2(0,0.83),Vector2(.19,.83),Vector2(.36,.94),Vector2(.46,1.18),Vector2(.47,1.43),Vector2(.37,1.66),Vector2(.22,1.72),Vector2(0,1.72)],paper,32)
	for i in 12:
		var angle := TAU*i/12
		var points: Array[Vector3] = []
		for p in [Vector2(.19,.83),Vector2(.36,.94),Vector2(.465,1.18),Vector2(.475,1.43),Vector2(.37,1.66),Vector2(.22,1.72)]:
			points.append(Vector3(p.x*cos(angle),p.y,p.x*sin(angle)))
		tube(body,"LanternRib%d" % i,points,.014,gold)
	lathe(body,"LowerCollar",[Vector2(.17,.77),Vector2(.24,.8),Vector2(.25,.85),Vector2(.19,.89)],gold,12)
	lathe(body,"RoofUnderside",[Vector2(.2,1.64),Vector2(.57,1.73),Vector2(.65,1.8)],red,8)
	lathe(body,"SweptPagodaRoof",[Vector2(.71,1.88),Vector2(.60,1.79),Vector2(.46,1.83),Vector2(.28,1.97),Vector2(.10,2.12),Vector2(0,2.15)],blue,8)
	for i in 8:
		var a := TAU*i/8
		var ridge: Array[Vector3] = []
		for p in [Vector2(.08,2.13),Vector2(.28,1.99),Vector2(.46,1.85),Vector2(.60,1.81),Vector2(.71,1.90)]:
			ridge.append(Vector3(p.x*cos(a),p.y,p.x*sin(a)))
		tube(body,"GildedRoofRidge%d"%i,ridge,.022,gold)
		var next := TAU*(i+1)/8
		tube(body,"Eave%d"%i,[Vector3(.71*cos(a),1.89,.71*sin(a)),Vector3(.71*cos(next),1.89,.71*sin(next))],.024,gold)
	lathe(body,"Finial",[Vector2(.09,2.08),Vector2(.10,2.14),Vector2(.055,2.22),Vector2(0,2.29)],gold,12)
	var hook: Array[Vector3] = []
	for i in 21:
		var a := -PI*.5 + i*PI*1.65/20
		hook.append(Vector3(.14+.16*cos(a),2.38+.16*sin(a),0))
	tube(body,"HangingHook",hook,.024,gold)
	# A red knot and individual curved strands form a hanging silk tassel.
	lathe(body,"TasselKnot",[Vector2(0,.72),Vector2(.065,.69),Vector2(.07,.64),Vector2(0,.60)],gold,12)
	var tassel := node(body,"Tassel")
	for i in 12:
		var a := TAU*i/12
		tube(tassel,"SilkStrand%d"%i,[Vector3(.035*cos(a),.64,.035*sin(a)),Vector3(.04*cos(a),.47,.04*sin(a)),Vector3(.11+.06*cos(a),.26,.06*sin(a)),Vector3(.18+.055*cos(a),.22,.055*sin(a))],.016,red)
	# Four cardinal prayer papers, with hand-authored seal strokes on each face.
	for i in 4:
		var charm := node(body,"Talisman%d"%i)
		charm.rotation.y = TAU*i/4
		ribbon(charm,"VermilionBorder",[Vector3(.25,1.7,.40),Vector3(.28,1.46,.50),Vector3(.34,1.16,.53)],.16,red)
		ribbon(charm,"PrayerPaper",[Vector3(.25,1.68,.408),Vector3(.28,1.46,.508),Vector3(.34,1.18,.538)],.125,mat("ffd482",.15))
		for j in 4:
			var y := 1.57-j*.085
			var x := .265+j*.017
			tube(charm,"SealStroke%d"%j,[Vector3(x-.035,y,.525),Vector3(x+.025,y-.018,.525),Vector3(x-.01,y-.04,.525)],.008,ink)
		tube(charm,"SealSpine",[Vector3(.265,1.62,.53),Vector3(.32,1.25,.55)],.009,ink)
	# Long streaming red/gold prayer silks.
	for i in 2:
		var stream := node(body,"Streamer%d"%i)
		stream.rotation.y = PI*i
		ribbon(stream,"Silk",[Vector3(-.48,1.75,0),Vector3(-.66,1.48,.03),Vector3(-.60,1.14,.10),Vector3(-.83,.90,.18),Vector3(-.68,.79,.22)],.10,red if i == 0 else gold)
	var fire := mat("ff7629",1.4)
	var core := mat("ffe6a0",1.2)
	for i in 2:
		var wisp := node(visual,"Wisp%d"%i)
		wisp.position = Vector3(-.81 if i==0 else .83,1.10 if i==0 else .76,.04)
		lathe(wisp,"Flame",[Vector2(0,-.13),Vector2(.095,-.08),Vector2(.13,.04),Vector2(.07,.17),Vector2(.035,.27),Vector2(0,.38)],fire,12)
		lathe(wisp,"Heart",[Vector2(0,-.13),Vector2(.07,-.06),Vector2(.055,.07),Vector2(0,.19)],core,12)
		wisp.get_node("Flame").rotation.z = -.22 if i==0 else .3
	var light := OmniLight3D.new()
	light.name = "InnerLight"
	body.add_child(light)
	light.owner = visual
	light.position = Vector3(0,1.3,0)
	light.light_color = Color("ff9d42")
	light.light_energy = .65
	light.omni_range = 2.8
	light.shadow_enabled = false
	GeneratedResources.externalize(visual, "res://scenes/units/lantern_visual.tscn")
	var packed := PackedScene.new()
	packed.pack(visual)
	var error := ResourceSaver.save(packed,"res://scenes/units/lantern_visual.tscn")
	visual.free()
	quit(error)
