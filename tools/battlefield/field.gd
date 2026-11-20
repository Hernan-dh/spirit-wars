extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
const GroundZones = preload("res://tools/battlefield/ground_zones.gd")
## Playable hex field: coordinates, authored ground zones and tile contents.

const GRID_SIZE := 14
const HEX_RADIUS := 0.94
const GRID_CENTER_Z := 1.4
const HEX_SIDES := 6
const TILE_ROOT_Y := -0.35
const SURFACE_HEIGHT := 0.35
const COLLISION_FLOOR_Y := 0.04
const ETCH_HEIGHT := 0.352
const ETCH_HALF_WIDTH := 0.005
const ADJACENT_EDGE_DISTANCE := 0.83
const SACRED_MARK_HEIGHT := 0.37
const MOONWELL_CELL := Vector2i(6, 6)

static func grid_position(row: int, column: int) -> Vector3:
	var midpoint := (GRID_SIZE - 1) * .5
	var spacing := sqrt(3.0) * HEX_RADIUS
	var x := (column - midpoint) * spacing + (row % 2) * spacing * .5 - spacing * .25
	var z := (row - midpoint) * 1.5 * HEX_RADIUS + GRID_CENTER_Z
	return Vector3(x, TILE_ROOT_Y, z)

static func ground_material(ctx: AuthoringContext, pos: Vector3) -> String:
	return GroundZones.material_for(Vector2(pos.x, pos.z), ctx.rng)

static func make_tile(ctx: AuthoringContext, parent: Node, row: int, column: int) -> void:
	var pos := grid_position(row,column)
	var terrain_mat := ground_material(ctx,pos)
	var tile := ctx.node(parent,"Hex_%d_%d"%[row+1,column+1],pos)
	tile.set_meta("row",row)
	tile.set_meta("column",column)
	tile.set_meta("axial_q",column - floori(row * .5))
	tile.set_meta("axial_r",row)
	tile.set_meta("terrain",terrain_mat)
	tile.set_meta("surface_height",SURFACE_HEIGHT)
	# Full-radius, coplanar faces share the landscape material. No slab or perimeter lip.
	ctx.disk(tile,"WalkingSurface",HEX_RADIUS,SURFACE_HEIGHT,"Terrain")
	var sacred := Vector2i(row, column) == MOONWELL_CELL
	var etching: Array = []
	for i in range(HEX_SIDES):
		var a := PI/HEX_SIDES+i*TAU/HEX_SIDES
		var b := a+TAU/HEX_SIDES
		var start := Vector3(cos(a)*HEX_RADIUS,ETCH_HEIGHT,sin(a)*HEX_RADIUS)
		var end := Vector3(cos(b)*HEX_RADIUS,ETCH_HEIGHT,sin(b)*HEX_RADIUS)
		var midpoint := pos + (start+end)*.5
		# Only interior shared edges: no rectangular outline around the playable area.
		var adjacent := false
		for other_row in range(maxi(0,row-1), mini(GRID_SIZE,row+2)):
			for other_col in range(maxi(0,column-1), mini(GRID_SIZE,column+2)):
				if other_row == row and other_col == column:
					continue
				var neighbor := grid_position(other_row,other_col)
				if Vector2(neighbor.x-midpoint.x,neighbor.z-midpoint.z).length() < ADJACENT_EDGE_DISTANCE and (other_row > row or (other_row == row and other_col > column)):
					adjacent = true
		if not adjacent:
			continue
		var tangent := (end-start).normalized()
		var across := Vector3(-tangent.z,0,tangent.x)*ETCH_HALF_WIDTH
		# Worn interruptions read as incised surveying marks in the stone.
		for interval in [Vector2(.08,.36),Vector2(.45,.91)]:
			var u := start.lerp(end,interval.x)
			var v := start.lerp(end,interval.y)
			ctx.tri(etching,u-across,u+across,v-across)
			ctx.tri(etching,v-across,u+across,v+across)
	if not etching.is_empty():
		ctx.surface(tile,"WornGridEtching",etching,"Seam")
	if sacred:
		var seal_origin := Vector3(0, SACRED_MARK_HEIGHT, 0)
		ctx.circle(tile,"MoonwellSeal",seal_origin,.59,"Spirit",.016)
		ctx.circle(tile,"InnerSeal",seal_origin,.43,"Spirit",.009)
		for i in range(HEX_SIDES):
			var a := i*TAU/HEX_SIDES
			ctx.line(tile,"PetalRune%d"%i,[seal_origin,Vector3(cos(a-.3)*.28,SACRED_MARK_HEIGHT,sin(a-.3)*.28),Vector3(cos(a)*.39,SACRED_MARK_HEIGHT,sin(a)*.39),Vector3(cos(a+.3)*.28,SACRED_MARK_HEIGHT,sin(a+.3)*.28),seal_origin],.012,"Spirit")
	var collision := StaticBody3D.new()
	collision.name = "TileBody"
	var shape := CollisionShape3D.new()
	shape.name = "HexCollision"
	var convex := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for y in [COLLISION_FLOOR_Y, SURFACE_HEIGHT]:
		for i in range(HEX_SIDES):
			var a := PI/HEX_SIDES+i*TAU/HEX_SIDES
			points.append(Vector3(cos(a)*HEX_RADIUS,y,sin(a)*HEX_RADIUS))
	convex.points = points
	shape.shape = convex
	collision.add_child(shape)
	tile.add_child(collision)
