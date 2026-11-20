extends SceneTree
## Regenerates the structural schema used to validate tools/battlefield/level_plan.tres.
## godot --headless --path . --script tools/build_level_plan_schema.gd

const LevelPlan = preload("res://tools/battlefield/level_plan.gd")
const OUTPUT := "res://tools/battlefield/level_plan_schema.json"

var _unsupported := false

func _initialize() -> void:
	var plan := load(LevelPlan.RESOURCE_PATH) as BattlefieldLevelPlan
	if plan == null:
		push_error("Could not load the level plan at %s." % LevelPlan.RESOURCE_PATH)
		quit(1)
		return
	var schema := {}
	for section in LevelPlan.SECTIONS:
		schema[section] = _describe(plan.get(section))
	if _unsupported:
		push_error("The level plan contains unsupported value types; schema not written.")
		quit(1)
		return
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file == null:
		push_error("Could not write the level plan schema at %s." % OUTPUT)
		quit(1)
		return
	file.store_string(JSON.stringify(schema, "  ") + "\n")
	file.close()
	print("Saved level plan schema: %s" % OUTPUT)
	quit()

func _describe(value: Variant):
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _describe(value[key])
		return result
	if value is Array:
		if value.is_empty():
			return "Array"
		return [_describe(value[0])]
	return _type_name(value)

func _type_name(value: Variant) -> String:
	match typeof(value):
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR3: return "Vector3"
		TYPE_COLOR: return "Color"
		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
		TYPE_ARRAY: return "Array"
		TYPE_DICTIONARY: return "Dictionary"
		_:
			_unsupported = true
			push_error("Unsupported level plan value type: %d." % typeof(value))
			return "Unsupported"
