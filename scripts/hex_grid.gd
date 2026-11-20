extends RefCounted
## Single source of truth for battlefield hex geometry and axial coordinates.
## Authoring tools and the runtime controller both read these values so the
## saved grid and the movement rules cannot drift apart.

const SIZE := 14
const RADIUS := 0.94
const CENTER_Z := 1.4
const SIDES := 6
const TILE_ROOT_Y := -0.35
const SURFACE_HEIGHT := 0.35

const AXIAL_Q_META := "axial_q"
const AXIAL_R_META := "axial_r"
const SURFACE_HEIGHT_META := "surface_height"

const AXIAL_NEIGHBORS := [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
]

static func cell_count() -> int:
	return SIZE * SIZE

static func grid_position(row: int, column: int) -> Vector3:
	var midpoint := (SIZE - 1) * .5
	var spacing := sqrt(3.0) * RADIUS
	var x := (column - midpoint) * spacing + (row % 2) * spacing * .5 - spacing * .25
	var z := (row - midpoint) * 1.5 * RADIUS + CENTER_Z
	return Vector3(x, TILE_ROOT_Y, z)

static func axial_of(row: int, column: int) -> Vector2i:
	return Vector2i(column - floori(row * .5), row)

static func has_cell(tile: Node) -> bool:
	return tile != null and tile.has_meta(AXIAL_Q_META) and tile.has_meta(AXIAL_R_META)

static func cell_of(tile: Node) -> Vector2i:
	return Vector2i(int(tile.get_meta(AXIAL_Q_META)), int(tile.get_meta(AXIAL_R_META)))

static func surface_height(tile: Node) -> float:
	return float(tile.get_meta(SURFACE_HEIGHT_META, SURFACE_HEIGHT))

static func tile_position(tile: Node3D) -> Vector3:
	return tile.to_global(Vector3(0, surface_height(tile), 0))

static func distance(a: Vector2i, b: Vector2i) -> int:
	var delta := a - b
	return maxi(absi(delta.x), maxi(absi(delta.y), absi(delta.x + delta.y)))
