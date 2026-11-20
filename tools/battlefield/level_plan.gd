@tool
class_name BattlefieldLevelPlan
extends Resource
## Authored level placements, counts and lighting for the moonwell courtyard.
## The authoring modules consume this resource so level tuning is not spread
## through the generator code. Edit the resource in the inspector or in
## tools/battlefield/level_plan.tres.

const RESOURCE_PATH := "res://tools/battlefield/level_plan.tres"
const LevelPlanSchema = preload("res://tools/battlefield/level_plan_schema.gd")

static var _validated := false

@export var island_rim := PackedVector2Array()
@export var moonwell_cell := Vector2i(6, 6)
@export var landscape_scale := 2.0
@export var foundation: Dictionary = {}
@export var bridge: Dictionary = {}
@export var terrain: Dictionary = {}
@export var terraces: Array = []
@export var ridge: Dictionary = {}
@export var spires: Dictionary = {}
@export var pavilions: Array = []
@export var shrine_trees: Array = []
@export var shrine_stairs: Dictionary = {}
@export var shrine_lanterns: Array = []
@export var shrine_banners: Array = []
@export var braziers: Array = []
@export var wetlands: Dictionary = {}
@export var gardens: Dictionary = {}
@export var approach: Dictionary = {}
@export var ruins: Dictionary = {}
@export var sanctuary_details: Dictionary = {}
@export var sanctuary: Dictionary = {}
@export var lighting: Dictionary = {}
@export var prop_templates: Dictionary = {}

static func load_default() -> BattlefieldLevelPlan:
	var plan := load(RESOURCE_PATH) as BattlefieldLevelPlan
	if plan == null:
		push_error("Could not load the battlefield level plan at %s." % RESOURCE_PATH)
		return null
	if not _validated:
		plan.validate()
		_validated = true
	return plan

func validate() -> bool:
	var ok := true
	for section in LevelPlanSchema.SCHEMA:
		var expected: Variant = LevelPlanSchema.SCHEMA[section]
		var actual: Variant = get(section)
		if not _matches(actual, expected, String(section)):
			ok = false
	if island_rim.is_empty():
		push_error("Level plan island_rim must not be empty.")
		ok = false
	if typeof(moonwell_cell) != TYPE_VECTOR2I:
		push_error("Level plan moonwell_cell must be a Vector2i.")
		ok = false
	return ok

func _matches(value: Variant, schema: Variant, path: String) -> bool:
	if schema is Dictionary:
		if not value is Dictionary:
			push_error("%s must be a Dictionary." % path)
			return false
		var ok := true
		for key in schema:
			if not value.has(key):
				push_error("%s is missing key '%s'." % [path, key])
				ok = false
			elif not _matches(value[key], schema[key], "%s.%s" % [path, key]):
				ok = false
		return ok
	if schema is Array:
		if not value is Array:
			push_error("%s must be an Array." % path)
			return false
		if schema.is_empty():
			return true
		if value.is_empty():
			push_error("%s must not be empty." % path)
			return false
		var ok := true
		for i in range(value.size()):
			if not _matches(value[i], schema[0], "%s[%d]" % [path, i]):
				ok = false
		return ok
	return _matches_type(value, String(schema), path)

func _matches_type(value: Variant, expected: String, path: String) -> bool:
	var ok := false
	match expected:
		"bool": ok = typeof(value) == TYPE_BOOL
		"int": ok = typeof(value) == TYPE_INT
		"float": ok = typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT
		"String": ok = typeof(value) == TYPE_STRING
		"Vector2": ok = typeof(value) == TYPE_VECTOR2
		"Vector3": ok = typeof(value) == TYPE_VECTOR3
		"Color": ok = typeof(value) == TYPE_COLOR
		"PackedVector2Array": ok = typeof(value) == TYPE_PACKED_VECTOR2_ARRAY
		"Array": ok = typeof(value) == TYPE_ARRAY
		"Dictionary": ok = typeof(value) == TYPE_DICTIONARY
		_: ok = true
	if not ok:
		push_error("%s should be %s." % [path, expected])
	return ok
