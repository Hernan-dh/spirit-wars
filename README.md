# Spirit Wars — The Moonwell

The first battlefield is a moonlit sanctuary landscape inspired by
`references/sw_concept_1.png`: cool stone and jade, warm lanterns, pink blossoms,
lotus water, bamboo, swept roofs, and cyan spirit inscriptions.

Open `project.godot` in Godot 4.7 and press **F6** on
`scenes/battlefields/moonwell_courtyard.tscn`, or **F5** to run the project.
The scene is the project's main scene and uses the configured Compatibility renderer.

## Editing the battlefield

Everything in the environment is saved in the scene, so it is visible without
running the game or an editor tool. `BattlefieldGrid` contains exactly 196 individually
editable ground hexes in a 14×14 layout, named `Hex_row_column` with one-based
display names. Their
`row` and `column` metadata are zero-based; `axial_q` / `axial_r` provide axial
coordinates for future tactics logic. The pointy-top hexes use an odd-row offset
layout with a 0.94-unit grid radius, small seams, and level walking surfaces at
world y = 0. Each tile includes a matching convex collision shape. Tile roots sit
at y = −0.35; their `surface_height` metadata is the local walking height (0.35),
used by unit placement and movement highlights. Moving a tile node also moves its
mesh, collision, and destination. `terrain` metadata identifies its authored surface
palette; surface types currently have equal movement cost.

The landscape footprint is approximately **37.4 × 36.2 units**, twice the original
width and depth (four times its ground area). The playable field now spans
approximately 23.6 × 20.2 units inside it,
using the original hex radius. There is no raised board foundation. Shallow stone,
moss, meadow, and earth surfaces follow continuous patches and crossing paths,
with subtle hex boundaries for tactical readability. All 196 cells are walkable;
water, cliffs, trees, and structures sit outside the playable footprint.

Named groups organize the surroundings:

- `HighlandTerraces`: five individually editable moss-capped landforms, eroded rock buttresses, hanging vines, and a rear mountain ridge.
- `HighlandShrines`: hilltop temple, tea pavilion, pilgrim staircase, prayer silks, and offering braziers.
- `EasternWetlands`: irregular lake and stream, two waterfall stages, lotus clusters, stepping stones, and an arched crossing.
- `OuterGardens`: cherry groves, bamboo thickets, ferns, mossy outcrops, and fallen blossoms.
- `WesternRuins`: broken paving, carved pillars, vines, and an inscribed spirit monolith.
- `PilgrimApproach`: weathered flagstones, lanterns, and prayer banners.
- `NorthernSanctuary`, `GroundMargins`, `LotusPools`, `GardenBridge`, and `IslandFoundation`: the gate approach, low ground cover, western pond, connecting path, and continuous island ground.

Terrace crowns, rock strata, shore water, and roofs are saved native meshes;
they can be moved, scaled, duplicated, or given different materials in the
inspector. The lake outline and terrace profiles are also defined in the authoring
script for geometry changes. Scenery is decorative; movement and picking use
the ground hexes. Waterfall ribbons and ripples are static editable meshes.

Reusable lantern, blossom tree,
bamboo grove, lotus, and spirit gate scenes live in `scenes/props/`. Edit those
source scenes to change their instances, or use Godot's **Editable Children**
for local changes. Meshes and materials are native Godot resources; no external
asset tools or packages are required.

`MoonlitAtmosphere`, `Moonlight`, and `SoftDuskFill` control the lighting.
`CameraRig/Camera3D` gives the angled orthographic opening view. Runtime controls:

- **WASD / arrow keys** pan relative to the current camera heading; hold **Shift** for faster movement.
- **Middle-mouse drag** grabs and pans the battlefield.
- **Right-mouse drag** rotates and tilts around the current focus; **Q / E** rotate horizontally.
- **Mouse wheel** zooms in and out.
- **R** restores the opening position, angle, and zoom.
- **Left click** a unit from either team to select or inspect it. Click empty space or press **Esc** to clear selection.
- During the active team's turn, **click a gold-ringed hex** to move the selected unit up to three hexes in one move. Gold rings mark every empty destination reachable within three steps; units cannot move through occupied hexes or off the field.
- **Spirit Pulse** uses the selected unit's ability: a team-colored expanding burst (visual starter ability; no damage yet).
- **End Turn** hands local control to the other team, even if actions remain. Jade starts.

Two jade pawns face two ember pawns on rows 12 and 3 of the field. Each has a
team-colored body and base plus a team/name label. Selection adds a gold ground
ring and overhead pointer, while the top-right panel names the selected unit.
Only one unit is selected at a time; both teams can be inspected. Only the active
team can act. Each unit can move once and use one ability, in either order, per
team turn. Selecting another unit does not reset those allowances. Ending the
turn clears selection and refreshes only the incoming team's actions. The panel
shows the turn, active team, and selected unit's remaining actions. Both teams
are controlled locally; there is no AI or networking.

`scenes/units/skirmish.tscn` holds the four editable starting positions and team
assignments. `scenes/units/placeholder_unit.tscn` is the reusable pawn; its `team`
and `unit_number` properties also update its appearance in the editor. Selection
uses 3D collision picking on physics layer 2, with hex ground picking on layer 1.

Panning stays within 18 world units of the opening focus on each ground axis.
The opening orthographic size is 39 units; zoom spans 10–58 units so you can
inspect the field closely or see the whole expanded landscape.
Zoom and tilt are limited to keep the view usable and above the battlefield.
Speeds, pan limits, and zoom limits are adjustable on `CameraRig` in the inspector;
keyboard bindings live in Project Settings → Input Map. The small title and
control legend appear only at runtime. Combat, health, and victory rules are not
implemented yet. Turn and movement rules live in `scripts/unit_selection.gd`;
pawns store their own action allowances in `scripts/placeholder_unit.gd`.

## Rebuilding the initial layout

`tools/build_battlefield.gd` is the deterministic authoring source for the
layout and reusable props. `GRID_SIZE`, `HEX_RADIUS`, `GRID_CENTER_Z`, and
`grid_position()` define the grid; `ground_material()` defines the ground patches
and crossing paths. The scene root groups and grid cells remain editable directly
in Godot without running the generator. The HUD reads the saved grid dimensions
and cell count, and the movement controller discovers all cells in `BattlefieldGrid`.
To regenerate them:

```sh
godot --headless --path . --script tools/build_battlefield.gd
```

Regeneration **overwrites the battlefield and prop scene files**, including any
manual scene edits. Normal game/editor use does not run this script. Temporary
validation scripts and preview renders belong in the ignored `tmp/` directory.
