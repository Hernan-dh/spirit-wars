extends RefCounted
const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
const GroundZones = preload("res://tools/battlefield/ground_zones.gd")
## Authored palette for the Moonwell courtyard.

const WEATHERED_MATERIAL_KEYS := ["Stone", "StoneLight", "StoneDark", "Foundation", "Cliff", "CliffLight", "Moss", "MossLight", "Jade", "Wood", "WoodLight", "Roof"]
const HIGH_GRAIN_MATERIAL_KEYS := ["Wood", "WoodLight", "Roof"]
const STRATA_MATERIAL_KEYS := ["Cliff", "CliffLight", "Foundation"]
const MOSS_MATERIAL_KEYS := ["Cliff", "CliffLight", "Stone", "Moss"]

static func build(ctx: AuthoringContext) -> void:
	ctx.material("Stone", "657d88")
	ctx.material("StoneLight", "91a0a4")
	ctx.material("StoneDark", "334956")
	ctx.material("Foundation", "233846")
	ctx.material("Moss", "506a48")
	ctx.material("Cliff", "3e5262")
	ctx.material("CliffLight", "647782")
	ctx.material("Grass", "718a53")
	ctx.material("Foam", "a8e4e1", 0.35)
	ctx.material("FallingWater", "62b6c6", 0.4, 0.25)
	ctx.material("MossLight", "8aab75")
	ctx.material("Jade", "30736c")
	ctx.material("Leaf", "3f7967")
	ctx.material("LeafLight", "73a378")
	ctx.material("Bamboo", "4a8172")
	ctx.material("Wood", "452f40")
	ctx.material("WoodLight", "86585a")
	ctx.material("Roof", "254e60", 0.0, 0.22)
	ctx.material("Gold", "cca76c", 0.0, 0.5)
	ctx.material("Seam", "687466")
	ctx.material("Meadow", "566b52")
	ctx.material("MeadowLight", "63765b")
	ctx.material("MossPaving", "657b6c")
	ctx.material("Cloth", "ab5265")
	ctx.material("Blossom", "d887b9")
	ctx.material("BlossomLight", "f4bbd7")
	ctx.material("BlossomDark", "ac609d")
	ctx.material("Ripple", "70c9c7", 0.5)
	ctx.material("Spirit", "6ef5ed", 2.0)
	ctx.material("SpiritDim", "338d96", 0.8)
	ctx.material("Amber", "ff9f42", 0.8)
	# One shared world-space material makes the ground continuous through the grid.
	var ground := ShaderMaterial.new()
	ground.resource_name = "Continuous sanctuary earth and flagstone"
	ground.shader = load("res://materials/sanctuary_ground.gdshader")
	GroundZones.apply_shader_parameters(ground)
	ctx.palette["Terrain"] = ground
	var water := ShaderMaterial.new()
	water.resource_name = "Jade pool ripples"
	water.shader = load("res://materials/lotus_water.gdshader")
	ctx.palette["Water"] = water
	for key in WEATHERED_MATERIAL_KEYS:
		var original: StandardMaterial3D = ctx.palette[key]
		var weathered := ShaderMaterial.new()
		weathered.resource_name = key + " weathered grain"
		weathered.shader = load("res://materials/weathered_surface.gdshader")
		weathered.set_shader_parameter("base_color", original.albedo_color)
		weathered.set_shader_parameter("grain_scale", 18.0 if key in HIGH_GRAIN_MATERIAL_KEYS else 9.0)
		weathered.set_shader_parameter("strata_amount", .38 if key in STRATA_MATERIAL_KEYS else .12)
		weathered.set_shader_parameter("moss_amount", .7 if key in MOSS_MATERIAL_KEYS else .15)
		ctx.palette[key] = weathered
