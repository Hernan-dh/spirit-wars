extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
## Playable hex field: coordinates, authored ground zones and tile contents.

const GRID_SIZE := 14
const HEX_RADIUS := 0.94
const GRID_CENTER_Z := 1.4

static func grid_position(row: int, column: int) -> Vector3:
	var midpoint := (GRID_SIZE - 1) * .5
	return Vector3((column-midpoint)*sqrt(3.0)*HEX_RADIUS + (row%2)*sqrt(3.0)*HEX_RADIUS*.5-sqrt(3.0)*HEX_RADIUS*.25,-.35,(row-midpoint)*1.5*HEX_RADIUS+GRID_CENTER_Z)

static func ground_material(ctx: AuthoringContext, pos: Vector3) -> String:
	# Continuous meadow patches and paths cross cell boundaries, avoiding a checkerboard.
	var pilgrim_path := absf(pos.x - sin(pos.z*.25)*1.3) < 2.5
	var crossing_path := absf(pos.z + .4 - sin(pos.x*.28)*1.1) < 1.8
	if pilgrim_path or crossing_path or Vector2(pos.x,pos.z-1.4).length() < 3.8:
		return "Paving%d"%ctx.rng.randi_range(0,5)
	if pos.x > 7.5 + sin(pos.z*.5):
		return "BankPaving"
	var meadow := sin(pos.x*.36) + cos(pos.z*.42) + sin((pos.x+pos.z)*.23)
	if meadow < -.55 or (pos.x < -7.0 and pos.z > 3):
		return "MeadowLight" if meadow < -1.2 else "Meadow"
	if meadow > 1.25:
		return "TrailEarth"
	return "MossPaving"

static func make_tile(ctx: AuthoringContext, parent: Node, row: int, column: int) -> void:
	var pos := grid_position(row,column)
	var terrain_mat := ground_material(ctx,pos)
	var tile := ctx.node(parent,"Hex_%d_%d"%[row+1,column+1],pos)
	tile.set_meta("row",row)
	tile.set_meta("column",column)
	tile.set_meta("axial_q",column - (row - row%2)/2)
	tile.set_meta("axial_r",row)
	tile.set_meta("terrain",terrain_mat)
	tile.set_meta("surface_height",.35)
	# Full-radius, coplanar faces share the landscape material. No slab or perimeter lip.
	ctx.disk(tile,"WalkingSurface",HEX_RADIUS,.35,"Terrain")
	var sacred := (row == 6 and column == 6)
	var etching: Array = []
	for i in range(6):
		var a := PI/6+i*TAU/6
		var b := a+TAU/6
		var start := Vector3(cos(a)*HEX_RADIUS,.352,sin(a)*HEX_RADIUS)
		var end := Vector3(cos(b)*HEX_RADIUS,.352,sin(b)*HEX_RADIUS)
		var midpoint := pos + (start+end)*.5
		# Only interior shared edges: no rectangular outline around the playable area.
		var adjacent := false
		for other_row in range(maxi(0,row-1), mini(GRID_SIZE,row+2)):
			for other_col in range(maxi(0,column-1), mini(GRID_SIZE,column+2)):
				if other_row == row and other_col == column:
					continue
				var neighbor := grid_position(other_row,other_col)
				if Vector2(neighbor.x-midpoint.x,neighbor.z-midpoint.z).length() < .83 and (other_row > row or (other_row == row and other_col > column)):
					adjacent = true
		if not adjacent:
			continue
		var tangent := (end-start).normalized()
		var across := Vector3(-tangent.z,0,tangent.x)*.005
		# Worn interruptions read as incised surveying marks in the stone.
		for interval in [Vector2(.08,.36),Vector2(.45,.91)]:
			var u := start.lerp(end,interval.x)
			var v := start.lerp(end,interval.y)
			ctx.tri(etching,u-across,u+across,v-across)
			ctx.tri(etching,v-across,u+across,v+across)
	if not etching.is_empty():
		ctx.surface(tile,"WornGridEtching",etching,"Seam")
	if sacred:
		ctx.circle(tile,"MoonwellSeal",Vector3(0,.37,0),.59,"Spirit",.016)
		ctx.circle(tile,"InnerSeal",Vector3(0,.37,0),.43,"Spirit",.009)
		for i in range(6):
			var a := i*TAU/6
			ctx.line(tile,"PetalRune%d"%i,[Vector3.ZERO+Vector3(0,.37,0),Vector3(cos(a-.3)*.28,.37,sin(a-.3)*.28),Vector3(cos(a)*.39,.37,sin(a)*.39),Vector3(cos(a+.3)*.28,.37,sin(a+.3)*.28),Vector3(0,.37,0)],.012,"Spirit")
	var collision := StaticBody3D.new()
	collision.name = "TileBody"
	var shape := CollisionShape3D.new()
	shape.name = "HexCollision"
	var convex := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for y in [.04,.35]:
		for i in range(6):
			var a := PI/6+i*TAU/6
			points.append(Vector3(cos(a)*HEX_RADIUS,y,sin(a)*HEX_RADIUS))
	convex.points = points
	shape.shape = convex
	collision.add_child(shape)
	tile.add_child(collision)
