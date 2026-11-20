@tool
class_name BattlefieldLevelPlan
extends Resource
## Authored level placements, counts and lighting for the moonwell courtyard.
## The authoring modules consume this resource so level tuning is not spread
## through the generator code. Edit the resource in the inspector or in
## tools/battlefield/level_plan.tres.

const RESOURCE_PATH := "res://tools/battlefield/level_plan.tres"

@export var island_rim := PackedVector2Array()
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

static func load_default() -> BattlefieldLevelPlan:
	return load(RESOURCE_PATH) as BattlefieldLevelPlan
