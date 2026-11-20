extends SceneTree
## Rebuild the authored courtyard: godot --path . --rendering-method gl_compatibility --script tools/build_battlefield.gd
## Generated scenes keep editable tiles/props and baked static scenery batches.
## Materials, prop scenes, landscape features and scene assembly live in
## tools/battlefield/; this entry point only sets up the shared authoring context.

const AuthoringContext = preload("res://tools/battlefield/authoring_context.gd")
const Materials = preload("res://tools/battlefield/materials.gd")
const Props = preload("res://tools/battlefield/props.gd")
const SceneAssembly = preload("res://tools/battlefield/scene_assembly.gd")
const GeneratedResources = preload("res://tools/generated_resources.gd")

const RNG_SEED := 72819

func _initialize() -> void:
	# The dummy renderer drops MultiMesh buffers when saving. Fail before overwriting
	# assets; use Compatibility with a display (or xvfb-run) for offline generation.
	if DisplayServer.get_name() == "headless":
		push_error("Rebuild requires the Compatibility renderer to save MultiMesh transforms. Run without --headless; use xvfb-run on a display-less machine.")
		quit(1)
		return
	GeneratedResources.reset()
	var ctx = AuthoringContext.new()
	ctx.rng.seed = RNG_SEED
	Materials.build(ctx)
	Props.build(ctx)
	SceneAssembly.build(ctx)
	quit()
