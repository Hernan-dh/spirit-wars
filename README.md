# Spirit Wars — The Moonwell

The first battlefield is a compact, moonlit shrine courtyard inspired by
`references/sw_concept_1.png`: cool stone and jade, warm lanterns, pink blossoms,
lotus water, bamboo, swept roofs, and cyan spirit inscriptions.

Open `project.godot` in Godot 4.7 and press **F6** on
`scenes/battlefields/moonwell_courtyard.tscn`, or **F5** to run the project.
The scene is the project's main scene and uses the configured Forward+ renderer.

## Editing the battlefield

Everything in the environment is saved in the scene, so it is visible without
running the game or an editor tool. `Board_7x7` contains exactly 49 individually
editable stone tiles, named `Hex_row_column` with one-based display names. Their
`row` and `column` metadata are zero-based; `axial_q` / `axial_r` provide axial
coordinates for future tactics logic. The pointy-top hexes use an odd-row offset
layout with a 0.94-unit grid radius, small seams, and level walking surfaces at
y = 0.35. Each tile includes a matching convex collision shape.

`NorthernSanctuary`, `Gardens`, `LotusPools`, `GardenBridge`, and
`IslandFoundation` organize the surroundings. Reusable lantern, blossom tree,
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
- **Left click** a unit from either team to select it. Click empty space or press **Esc** to clear selection.

Two jade pawns face two ember pawns on opposite rows of the board. Each has a
team-colored body and base plus a team/name label. Selection adds a gold ground
ring and overhead pointer, while the top-right panel names the selected unit.
Only one unit is selected at a time; both teams can be inspected.

`scenes/units/skirmish.tscn` holds the four editable starting positions and team
assignments. `scenes/units/placeholder_unit.tscn` is the reusable pawn; its `team`
and `unit_number` properties also update its appearance in the editor. Selection
uses 3D collision picking on physics layer 2, with board occlusion on layer 1.

Panning stays within eight world units of the opening focus on each ground axis.
Zoom and tilt are limited to keep the view usable and above the battlefield.
Speeds, pan limits, and zoom limits are adjustable on `CameraRig` in the inspector;
keyboard bindings live in Project Settings → Input Map. The small title and
control legend appear only at runtime. There are no movement, combat systems,
turn rules, or tile-selection behavior yet.

## Rebuilding the initial layout

`tools/build_battlefield.gd` is the deterministic authoring source for the
initial layout and reusable props. To regenerate them:

```sh
godot --headless --path . --script tools/build_battlefield.gd
```

Regeneration **overwrites the battlefield and prop scene files**, including any
manual scene edits. Normal game/editor use does not run this script. Temporary
validation scripts and preview renders belong in the ignored `tmp/` directory.
