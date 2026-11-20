extends RefCounted
const HexGrid = preload("res://scripts/hex_grid.gd")
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
const GroundZones = preload("res://tools/battlefield/ground_zones.gd")
const LevelPlan = preload("res://tools/battlefield/level_plan.gd")
## Playable hex field: authored ground zones and tile contents.
## Grid dimensions and coordinates come from scripts/hex_grid.gd.

const COLLISION_FLOOR_Y := 0.04
const ETCH_HEIGHT := HexGrid.SURFACE_HEIGHT + 0.002
const ETCH_HALF_WIDTH := 0.005
# Shared edges sit at the hex apothem; the small margin accepts authored rounding.
const ADJACENT_EDGE_DISTANCE := sqrt(3.0) * HexGrid.RADIUS * 0.5 + 0.016
const SACRED_MARK_HEIGHT := HexGrid.SURFACE_HEIGHT + 0.02

static var _hex_collision_shape: ConvexPolygonShape3D
static var _moonwell_cell := Vector2i(-1, -1)

static func ground_material(ctx: AuthoringContext, pos: Vector3) -> String:
	return GroundZones.material_for(Vector2(pos.x, pos.z), ctx.rng)

static func make_tile(ctx: AuthoringContext, parent: Node, row: int, column: int) -> void:
	var pos := HexGrid.grid_position(row,column)
	var terrain_mat := ground_material(ctx,pos)
	var tile := ctx.node(parent,"Hex_%d_%d"%[row+1,column+1],pos)
	var axial := HexGrid.axial_of(row,column)
	tile.set_meta("row",row)
	tile.set_meta("column",column)
	tile.set_meta(HexGrid.AXIAL_Q_META,axial.x)
	tile.set_meta(HexGrid.AXIAL_R_META,axial.y)
	tile.set_meta("terrain",terrain_mat)
	tile.set_meta(HexGrid.SURFACE_HEIGHT_META,HexGrid.SURFACE_HEIGHT)
	# Full-radius, coplanar faces share the landscape material. No slab or perimeter lip.
	ctx.disk(tile,"WalkingSurface",HexGrid.RADIUS,HexGrid.SURFACE_HEIGHT,"Terrain")
	var sacred := Vector2i(row, column) == _moonwell_cell_value()
	var etching: Array = []
	for i in range(HexGrid.SIDES):
		var a := PI/HexGrid.SIDES+i*TAU/HexGrid.SIDES
		var b := a+TAU/HexGrid.SIDES
		var start := Vector3(cos(a)*HexGrid.RADIUS,ETCH_HEIGHT,sin(a)*HexGrid.RADIUS)
		var end := Vector3(cos(b)*HexGrid.RADIUS,ETCH_HEIGHT,sin(b)*HexGrid.RADIUS)
		var midpoint := pos + (start+end)*.5
		# Only interior shared edges: no rectangular outline around the playable area.
		var adjacent := false
		for other_row in range(maxi(0,row-1), mini(HexGrid.SIZE,row+2)):
			for other_col in range(maxi(0,column-1), mini(HexGrid.SIZE,column+2)):
				if other_row == row and other_col == column:
					continue
				var neighbor := HexGrid.grid_position(other_row,other_col)
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
		for i in range(HexGrid.SIDES):
			var a := i*TAU/HexGrid.SIDES
			ctx.line(tile,"PetalRune%d"%i,[seal_origin,Vector3(cos(a-.3)*.28,SACRED_MARK_HEIGHT,sin(a-.3)*.28),Vector3(cos(a)*.39,SACRED_MARK_HEIGHT,sin(a)*.39),Vector3(cos(a+.3)*.28,SACRED_MARK_HEIGHT,sin(a+.3)*.28),seal_origin],.012,"Spirit")
	var collision := StaticBody3D.new()
	collision.name = "TileBody"
	var shape := CollisionShape3D.new()
	shape.name = "HexCollision"
	shape.shape = _shared_collision_shape()
	collision.add_child(shape)
	tile.add_child(collision)

static func _moonwell_cell_value() -> Vector2i:
	if _moonwell_cell.x < 0:
		_moonwell_cell = LevelPlan.load_default().moonwell_cell
	return _moonwell_cell

static func _shared_collision_shape() -> ConvexPolygonShape3D:
	if _hex_collision_shape != null:
		return _hex_collision_shape
	var convex := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for y in [COLLISION_FLOOR_Y, HexGrid.SURFACE_HEIGHT]:
		for i in range(HexGrid.SIDES):
			var a := PI/HexGrid.SIDES+i*TAU/HexGrid.SIDES
			points.append(Vector3(cos(a)*HexGrid.RADIUS,y,sin(a)*HexGrid.RADIUS))
	convex.points = points
	_hex_collision_shape = convex
	return _hex_collision_shape
