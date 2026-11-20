# Spirit Wars — The Moonwell

The first battlefield is a moonlit sanctuary landscape inspired by
`references/sw_concept_1.png`: cool stone and jade, warm lanterns, pink blossoms,
lotus water, bamboo, swept roofs, and cyan spirit inscriptions.

Open `project.godot` in Godot 4.7 and press **F6** on
`scenes/battlefields/moonwell_courtyard.tscn`, or **F5** to run the project.
The scene is the project's main scene and uses the configured Compatibility renderer.

## Editing the battlefield

Everything in the environment is saved in the scene, so it is visible without
running the game or an editor tool. Generated meshes and materials are saved as
external resources and referenced from the scene, so geometry is not inlined as
base64 text. `BattlefieldGrid` contains exactly 196 individually
editable ground hexes in a 14×14 layout, named `Hex_row_column` with one-based
display names. Their
`row` and `column` metadata are zero-based; `axial_q` / `axial_r` provide axial
coordinates for future tactics logic. The pointy-top hexes use an odd-row offset
layout with a 0.94-unit grid radius, gapless faces, and level walking surfaces at
world y = 0. Each tile includes a matching convex collision shape. Tile roots sit
at y = −0.35; their `surface_height` metadata is the local walking height (0.35),
used by unit placement and movement highlights. Moving a tile node also moves its
mesh, collision, and destination. `terrain` metadata identifies approximate authored terrain zones; the shared ground
shader determines the blended appearance. Surface types have equal movement cost.

The landscape footprint is approximately **37.4 × 36.2 units**, twice the original
width and depth (four times its ground area). The playable field now spans
approximately 23.6 × 20.2 units inside it,
using the original hex radius. The grid has no slab sides, bevels, raised board foundation, or outer border.
A shared world-space material blends irregular weathered flagstones, earth, and moss
across the full ground, including the surrounding landscape. Faint, interrupted
etchings mark internal hex boundaries; selection still reveals gold destination rings.
Low grass, fallen petals, and buried rubble blend the field into the gardens. All 196 cells are walkable;
water, cliffs, trees, and structures sit outside the playable footprint.

Named groups organize the surroundings:

- `HighlandTerraces`: five individually editable moss-capped landforms, eroded rock buttresses, hanging vines, and a rear mountain ridge.
- `HighlandShrines`: hilltop temple, tea pavilion, pilgrim staircase, prayer silks, and offering braziers. Roofs have overlapping curved ceramic tiles, timber brackets, and lattice screens.
- `SanctuaryDetails`: two carved cloud-lion guardians, meadow shoots, windblown petals, buried stones, and feathered ferns.
- `EasternWetlands`: irregular lake and stream, two waterfall stages, lotus clusters, stepping stones, and an arched crossing.
- `OuterGardens`: cherry groves, bamboo thickets, ferns, mossy outcrops, and fallen blossoms.
- `WesternRuins`: broken paving, carved pillars, vines, and an inscribed spirit monolith.
- `PilgrimApproach`: weathered flagstones, lanterns, and prayer banners.
- `NorthernSanctuary`, `GroundMargins`, `LotusPools`, `GardenBridge`, and `IslandFoundation`: the gate approach, low ground cover, western pond, connecting path, and continuous island ground.

Terrace crowns, rock strata, shore water, and roofs are saved native meshes;
they can be moved, scaled, duplicated, or given different materials in the
inspector. Blossom crowns use 15,360 triangles for close views and a native
7,680-triangle mesh LOD for distant views (formerly 69,120 triangles per crown).
The ten battlefield crowns therefore use at most 153,600 triangles, or 76,800
when all use the distant LOD. Both levels retain the blossom centers and colors;
Godot selects the level by screen size, including orthographic zoom, viewport
resolution, and instance scale. Lanterns have window lattice and carved bases.
Stone and cliffs use procedural mineral grain,
strata, and moss weathering. Pool surfaces have gentle animated ripples.
The lake outline and terrace profiles are also defined in
`tools/battlefield/landscape.gd` for geometry changes. Scenery is decorative; movement and picking use
the ground hexes. Waterfall ribbons and ripples are static editable meshes.

Reusable lantern, blossom tree, bamboo grove, lotus, and spirit gate scenes live
in `scenes/props/`. Their static parts are combined by material and shadow mode.
Lanterns and the gate remain scene instances with individually editable lights;
use Godot's **Editable Children** for local changes.

Trees, bamboo, lotus, and ferns are saved as `MultiMeshInstance3D` scenery.
Nonuniformly scaled rocks are merged into static surfaces to preserve their lighting.
Batches stay within their named landscape group and an eight-unit local X/Z cell,
so distant regions can still be culled separately. Batch `instance_names` metadata
maps each instance index to its authored placement name; transforms live in the
MultiMesh resource. To change repeated scenery geometry or placements, edit the
matching authoring module and rebuild. Batches contain baked mesh resources rather than
live prop scene instances. The blossom crown is authored as one surface with LOD
indices before batching, so its lower-detail mesh survives in both the reusable
prop and the saved battlefield. `BLOSSOM_LOD_ERROR` in
`tools/battlefield/props.gd` tunes the screen-size transition; there is no runtime mesh generation or swap script.
All 196 tile roots, metadata, collisions, and gameplay nodes remain
independent. Tile seals and static lines are combined meshes, with no segment nodes.
Meshes and materials are native Godot resources saved under
`generated/meshes/` (binary `.res`) and `generated/materials/` (text `.tres`);
repeated props and scenery batches reference the same files instead of embedding
copies. Identical mesh geometry and material settings are written once, so shared
hex surfaces, grid etchings, pavilion roofs and unit shaders reference a single
file. No external asset tools are required.

`MoonlitAtmosphere`, `Moonlight`, and `SoftDuskFill` control the lighting.
`CameraRig/Camera3D` gives the angled orthographic opening view. Runtime controls:

- **WASD / arrow keys** pan relative to the current camera heading; hold **Shift** for faster movement.
- **Middle-mouse drag** grabs and pans the battlefield.
- **Right-mouse drag** rotates and tilts around the current focus; **Q / E** rotate horizontally.
- **Mouse wheel** zooms in and out.
- **R** restores the opening position, angle, and zoom.
- **Left click** a unit from either team to select or inspect it. Click empty space or press **Esc** to clear selection.
- During the active team's turn, **click a gold-ringed hex** to move the selected unit up to three hexes in one move. Gold rings mark every empty destination reachable within three steps; units cannot move through occupied hexes or off the field.
- **Spirit Pulse / Attack** (Lantern) or **Mirage Rush / Attack** (Kitsune) enters targeting mode. Click a red-ringed enemy within three hexes to deal one damage. **Cancel Attack** exits targeting without spending the attack; **Esc** clears selection. Invalid targets spend no action.
- **End Turn** hands local control to the other team, even if actions remain. Jade starts.
- Defeating a team's last surviving unit ends the battle and displays the winner. Movement, attacks, selection, and turn changes stop. Choose **Restart Encounter** (or press Enter with the button focused) to restore the starting encounter, including all four units at full health, Jade's first turn, and the opening camera.

Each team fields one Lantern Spirit and one Celestial Kitsune on rows 12 and 3 of the field. Each has a
team-colored base plus a team/name label and visible health. Every unit starts with **3 HP**; health persists between turns. A unit at zero health is removed and its hex becomes available. Selection adds a gold ground
ring and overhead pointer, while the top-right panel names the selected unit.
Only one unit is selected at a time; both teams can be inspected. Only the active
team can act. Each unit can move once and attack once, in either order, per
team turn. Selecting another unit does not reset those allowances. Ending the
turn clears selection and refreshes only the incoming team's actions. The panel
shows the turn, active team, and selected unit's remaining actions. Both teams
are controlled locally; there is no AI or networking.

`scenes/units/skirmish.tscn` holds the four editable starting positions and team
assignments. `scenes/units/lantern_spirit.tscn` and
`scenes/units/celestial_kitsune.tscn` are the reusable units; their `team`
and `unit_number` properties also update their bases and labels in the editor. Selection
uses 3D collision picking on physics layer 2, with hex ground picking on layer 1.

Panning stays within 18 world units of the opening focus on each ground axis.
The opening orthographic size is 39 units; zoom spans 10–58 units so you can
inspect the field closely or see the whole expanded landscape.
Zoom and tilt are limited to keep the view usable and above the battlefield.
Speeds, pan limits, and zoom limits are adjustable on `CameraRig` in the inspector;
keyboard bindings live in Project Settings → Input Map. The small title and
control legend appear only at runtime. Attacks use axial hex distance (at most three),
including adjacent targets, and can pass over occupied hexes; no line-of-sight
restriction is applied. The battle ends as soon as either team has no surviving units. Turn, victory, combat, and movement rules live in `scripts/unit_selection.gd`;
pawns store their own action allowances in `scripts/placeholder_unit.gd`.

## Rebuilding the initial layout

`tools/build_battlefield.gd` is the deterministic authoring entry point. It creates
`tools/battlefield/authoring_context.gd`, which holds the shared palette, packed prop
cache, RNG and primitive mesh helpers, then runs the modules in order:

- `materials.gd` authors the palette and weathering shaders.
- `props.gd` builds the reusable lantern, blossom tree, bamboo, lotus and gate scenes.
- `ground_zones.gd` defines the path, plaza and meadow zones shared by the field, shader and vegetation clearing.
- `field.gd` builds tile contents from the shared grid coordinates and ground zones.
- `level_plan.tres` stores the authored placements, counts, terraces, wetlands and lighting tuning; its exported fields are editable in the inspector.
- `landscape.gd` consumes the level plan to build the island foundation, terraces, wetlands, gardens, ruins and sanctuary details.
- `scene_assembly.gd` reads the same plan for the foundation, gate approach, margins, atmosphere and lighting, then adds the camera and starting units.

`tools/static_geometry.gd` merges static surfaces and
batches repeated scenery during authoring; `tools/generated_resources.gd` saves the
resulting meshes and materials as shared external resources. Normal game/editor use
does no conversion.
Grid dimensions, `grid_position()`, axial coordinates and neighbors live in
`scripts/hex_grid.gd`, shared by `tools/battlefield/field.gd` and the runtime movement
controller. `ground_material()` reads `ground_zones.gd`, whose parameters are applied
to the shader as uniforms. Team, highlight and effect colors live in
`scripts/spirit_palette.gd`.
`materials/sanctuary_ground.gdshader` defines continuous paths, stone joints, and
moss coverage in world coordinates. `materials/weathered_surface.gdshader` controls
scenery grain and weathering, and `materials/lotus_water.gdshader` controls pool ripples.
These procedural textures work in the configured Compatibility renderer and require
no image imports or external packages. The scene root groups and grid cells remain editable directly
in Godot without running the generator. The HUD layout and presentation tuning live in
`scripts/hud_style.gd`; the HUD reads the saved grid dimensions and cell count, and the
movement controller discovers all cells in `BattlefieldGrid`.
To regenerate them:

```sh
godot --path . --rendering-method gl_compatibility --script tools/build_battlefield.gd
```

Regeneration requires a working graphics display and the Compatibility renderer.
The generator rejects `--headless` before changing files because Godot's dummy
renderer does not serialize MultiMesh transform buffers. On a machine with Xvfb
installed, prefix the command with `xvfb-run -a` for an unattended rebuild.

Regeneration **overwrites the battlefield and prop scene files and their generated
mesh/material files**, including any manual scene edits. Normal game/editor use does
not run this script. Temporary validation scripts and preview renders belong in the
ignored `tmp/` directory.

## Lantern Spirit

The encounter includes the Lantern Spirit from the unit sheet in
`references/sw_concept_2.png`, with materials that match the sanctuary palette in
`references/sw_concept_1.png`. Its glowing amber paper body, gold ribs, blue swept
pagoda roof, hanging hook, prayer seals, red tassel, streaming silks, and two flame
wisps are native editable Godot meshes referenced from `scenes/units/lantern_visual.tscn`.
The generated meshes and materials live in the shared external resource folders.
The spirit hovers and sways, with gently flickering warm light. Jade and Ember
retain their colored bases and labels; selection adds the gold ring and pointer.
Spirit Pulse fires a small arcing firebolt and an expanding amber impact ring.
The existing three HP, three-hex move/range, one-damage attack, and turn rules apply.

`lantern_spirit.tscn` inherits the shared pawn scene and replaces its visible body,
head, pick shape, and label heights. `scripts/lantern_spirit.gd` extends the shared
unit behavior with idle animation and the fire effect. To rebuild the visual mesh
scene after editing its authoring source:

```sh
godot --headless --path . --script tools/build_lantern_spirit.gd
```

This overwrites only `scenes/units/lantern_visual.tscn` and its generated external
resources. No rebuild is needed to play.


## Celestial Kitsune

The Celestial Kitsune follows the upper-right concept in `references/sw_concept_2.png`:
an ivory fox with pointed rose ears, crimson brows and cheek seals, a layered chest
ruff, vermilion collar, gilded bells, amethyst mirror, and nine curling spirit tails.
Each plume blends from ivory into pink, violet, or blue and carries pale sacred-light
veins. The fox breathes, its tails sway independently, and small light motes hover
around the fan. All geometry is referenced from `scenes/units/kitsune_visual.tscn`
and is visible in the editor; no external textures or runtime mesh generation are needed.
`materials/kitsune_spirit.gdshader` supplies the tail colors and gentle emission in
the project's Compatibility renderer. Attack effects share the projectile and ring
helpers and named tuning in `scripts/combat_effects.gd`.

Each team starts with one Kitsune in slot 02. It retains the shared three HP,
three-hex movement and attack range, and one move plus one attack per turn. Movement
turns the fox toward its destination and plays a short bounding hop. Its attack,
**Mirage Rush**, sends three violet-blue fox silhouettes toward the selected enemy,
followed by a sacred-light impact ring. The trio shares one cached effect mesh and
material instead of cloning the full visual, and represents a single attack dealing
one damage. The HUD displays the selected unit's ability name; the Lantern keeps
Spirit Pulse. Effects clean themselves up even after a lethal hit.

`celestial_kitsune.tscn` inherits the shared pawn scene with its own picking volume,
label heights, and visual. `scripts/celestial_kitsune.gd` adds animation and effects;
the common controller still validates all movement, targeting, turns, and damage.
To regenerate just the editable visual after changing its authoring source:

```sh
godot --headless --path . --script tools/build_celestial_kitsune.gd
```

This overwrites only `scenes/units/kitsune_visual.tscn` and its generated external
resources. No rebuild is needed to play.
