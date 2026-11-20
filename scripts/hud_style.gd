extends RefCounted
## Named presentation tuning for the runtime HUD. Keeping layout and text here
## lets the HUD builder stay focused on state and interaction.

const SpiritPalette = preload("res://scripts/spirit_palette.gd")

const COLOR_ACCENT := Color("cbb58e")
const COLOR_TITLE := Color("e5e6dc")
const COLOR_SUBTITLE := Color("a0bcc4")
const COLOR_HINT := Color("a7bbc3")
const COLOR_GOLD := SpiritPalette.HIGHLIGHT_MOVE
const COLOR_BODY := Color("d6e1e2")
const COLOR_PANEL := Color(0.035, 0.065, 0.09, 0.92)
const COLOR_PANEL_BORDER := Color("52656d")
const COLOR_OVERLAY := Color(0.015, 0.03, 0.045, 0.65)

const FOOTER_TEXT := "WASD / ARROWS / DRAG MMB  Pan     /     SHIFT  Fast pan\nDRAG RMB / Q E  Rotate     /     SCROLL  Zoom     /     R  Reset view"
const OVERLAY_HEADING := "B A T T L E   C O M P L E T E"
const LOCAL_PLAY_HEADING := "LOCAL PLAY  /  BOTH TEAMS"
const ACTIONS_HELP := "Each unit: %d HP / 1 move + 1 attack"
const WAITING_HELP := "Waiting for %s's turn"
const ACTION_STATUS := "Move: %s   /   Attack: %s"
const RESULT_DETAILS := "Encounter ended on turn %d.\nRestart to play again from the beginning."
const ATTACK_HELP := "Attack: %d damage / %d hex range\nMove and attack in either order."
const FIELD_HELP := "Click unit to select / inspect\nGold rings: move up to %d hexes\nRed rings: enemies in attack range\nEmpty space / Esc to clear selection"

const HEADER_EYEBROW_POS := Vector2(38, 27)
const HEADER_EYEBROW_SIZE := 14
const HEADER_TITLE_POS := Vector2(36, 49)
const HEADER_TITLE_SIZE := 34
const HEADER_SUBTITLE_POS := Vector2(39, 94)
const HEADER_SUBTITLE_SIZE := 11
const HEADER_RULE_POS := Vector2(39, 122)
const HEADER_RULE_SIZE := Vector2(48, 2)

const FOOTER_POS := Vector2(38, -64)
const FOOTER_SIZE := 13
const GRID_COUNT_POS := Vector2(-200, -43)
const GRID_COUNT_SIZE := 13

const STATUS_PANEL_POS := Vector2(-350, 30)
const STATUS_PANEL_WIDTH := 312
const STATUS_ROW_GAP := 8
const STATUS_HEADING_SIZE := 12
const TURN_SIZE := 22
const END_TURN_HEIGHT := 42
const SELECTION_SIZE := 16
const ACTIONS_SIZE := 14
const ABILITY_HEIGHT := 40
const HINT_SIZE := 13
const FEEDBACK_SIZE := 14
const FEEDBACK_MIN_SIZE := Vector2(276, 48)

const RESULT_PANEL_WIDTH := 420
const RESULT_ROW_GAP := 18
const RESULT_HEADING_SIZE := 14
const RESULT_TITLE_SIZE := 36
const RESULT_DETAILS_SIZE := 16
const RESTART_HEIGHT := 48

const PANEL_BORDER_WIDTH := 1
const PANEL_CORNER_RADIUS := 6
const PANEL_MARGIN_HORIZONTAL := 18
const PANEL_MARGIN_VERTICAL := 14
