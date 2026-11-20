extends RefCounted
## Required keys and value types for BattlefieldLevelPlan sections.
## Regenerate by dumping the loaded plan structure when the schema changes.

const SCHEMA := {
	"approach": {
		"banners": [
			{
				"position": "Vector3",
				"scale": "float",
				"title": "String",
				"yaw": "float"
			}
		],
		"count": "int",
		"depth": "float",
		"height": "float",
		"lantern_offset_x": "float",
		"lantern_rows": [
			"int"
		],
		"lantern_scale": "float",
		"lantern_z_offset": "float",
		"width": "float",
		"x_frequency": "float",
		"x_wave": "float",
		"y": "float",
		"z_start": "float",
		"z_step": "float"
	},
	"braziers": [
		{
			"position": "Vector3",
			"title": "String"
		}
	],
	"bridge": {
		"cap_height": "float",
		"cap_size": "Vector3",
		"deck_arch_height": "float",
		"deck_arch_radius": "float",
		"deck_half_span": "int",
		"deck_planks": "int",
		"deck_size": "Vector3",
		"deck_spacing": "float",
		"post_offset_z": "float",
		"post_size": "Vector3",
		"post_y_offset": "float",
		"rail_half_span": "int",
		"rail_height": "float",
		"rail_posts": "int",
		"rail_radius": "float",
		"rail_spacing": "float"
	},
	"foundation": {
		"bedrock_inset": "float",
		"bedrock_y": "float",
		"shore_height": "float",
		"upper_stratum_inset": "float",
		"upper_stratum_y": "float"
	},
	"gardens": {
		"bamboo": [
			{
				"position": "Vector3",
				"scale": "float",
				"title": "String",
				"yaw": "float"
			}
		],
		"blossom_interval": "int",
		"blossom_size": "Vector3",
		"boundary_scale": "float",
		"clear_boxes": [
			{
				"use_abs_x": "bool",
				"x_max": "float",
				"x_min": "float",
				"z_max": "float",
				"z_min": "float"
			}
		],
		"fern_count": "int",
		"fern_scale_range": "Vector2",
		"fern_x_range": "Vector2",
		"fern_z_range": "Vector2",
		"outcrop_interval": "int",
		"outcrop_size": "Vector3",
		"terrace_fern_count": "int",
		"terrace_fern_scale": "float",
		"terrace_fern_x_range": "Vector2",
		"terrace_fern_y": "float",
		"terrace_fern_z_range": "Vector2",
		"trees": [
			{
				"position": "Vector3",
				"scale": "float",
				"title": "String",
				"yaw": "float"
			}
		]
	},
	"lighting": {
		"ambient_color": "Color",
		"ambient_energy": "float",
		"background_color": "Color",
		"background_energy": "float",
		"fill_color": "Color",
		"fill_energy": "float",
		"fill_rotation": "Vector3",
		"glow_enabled": "bool",
		"glow_intensity": "float",
		"moon_color": "Color",
		"moon_energy": "float",
		"moon_rotation": "Vector3",
		"moon_shadow_distance": "float",
		"ssao_enabled": "bool",
		"ssao_intensity": "float",
		"ssao_radius": "float"
	},
	"pavilions": [
		{
			"position": "Vector3",
			"scale": "float",
			"title": "String"
		}
	],
	"prop_templates": {
		"banner": {
			"finial_size": "Vector3",
			"finial_y": "float",
			"flag_bottom_drop": "float",
			"flag_bottom_half_width": "float",
			"flag_center": "int",
			"flag_count": "int",
			"flag_depth": "float",
			"flag_half_width": "float",
			"flag_spacing": "float",
			"flag_tip_depth": "float",
			"flag_tip_drop": "float",
			"flag_tip_x": "float",
			"flag_y": "float",
			"flag_y_slope": "float",
			"foot_bottom": "float",
			"foot_height": "float",
			"foot_top": "float",
			"foot_y": "float",
			"pole_bottom_y": "float",
			"pole_radius": "float",
			"pole_top_y": "float",
			"post_offset_x": "float",
			"stitch_count": "int",
			"stitch_size": "Vector3",
			"stitch_y_offset": "float",
			"stitch_y_step": "float",
			"stitch_z": "float",
			"suspension_points": [
				"Vector3"
			],
			"suspension_radius": "float"
		},
		"brazier": {
			"bowl": {
				"bottom_radius": "float",
				"height": "float",
				"material": "String",
				"position": "Vector3",
				"top_radius": "float"
			},
			"coals": {
				"bottom_radius": "float",
				"height": "float",
				"material": "String",
				"position": "Vector3",
				"top_radius": "float"
			},
			"flame_count": "int",
			"flame_height_step": "float",
			"flame_material": "String",
			"flame_radius": "float",
			"flame_size": "Vector3",
			"flame_tilt": "float",
			"flame_y": "float",
			"plinth": {
				"bottom_radius": "float",
				"height": "float",
				"material": "String",
				"position": "Vector3",
				"top_radius": "float"
			},
			"stem": {
				"bottom_radius": "float",
				"height": "float",
				"material": "String",
				"position": "Vector3",
				"top_radius": "float"
			}
		},
		"guardian": {
			"brow_points": [
				"Vector3"
			],
			"brow_radius": "float",
			"chest_position": "Vector3",
			"chest_size": "Vector3",
			"ear_position": "Vector3",
			"ear_size": "Vector3",
			"eye_socket_position": "Vector3",
			"eye_socket_size": "Vector3",
			"fang_height": "float",
			"fang_position": "Vector3",
			"fang_top": "float",
			"foreleg_end": "Vector3",
			"foreleg_radius": "float",
			"foreleg_start": "Vector3",
			"foreleg_top": "float",
			"haunches_position": "Vector3",
			"haunches_size": "Vector3",
			"head_position": "Vector3",
			"head_size": "Vector3",
			"mane_center_radius": "float",
			"mane_count": "int",
			"mane_curl_count": "int",
			"mane_curl_radius": "float",
			"mane_curl_taper": "float",
			"mane_curl_z": "float",
			"mane_line_radius": "float",
			"mane_y": "float",
			"mane_y_radius": "float",
			"mane_z": "float",
			"mouth_position": "Vector3",
			"mouth_size": "Vector3",
			"muzzle_position": "Vector3",
			"muzzle_size": "Vector3",
			"nose_position": "Vector3",
			"nose_size": "Vector3",
			"paw_position": "Vector3",
			"paw_size": "Vector3",
			"plinth_lip_position": "Vector3",
			"plinth_lip_size": "Vector3",
			"plinth_position": "Vector3",
			"plinth_size": "Vector3",
			"relief_count": "int",
			"relief_size": "Vector3",
			"relief_x_center": "float",
			"relief_x_step": "float",
			"relief_y": "float",
			"relief_z": "float",
			"scale": "float",
			"spirit_eye_position": "Vector3",
			"spirit_eye_size": "Vector3",
			"tail_points": [
				"Vector3"
			],
			"tail_radius": "float",
			"toe_count": "int",
			"toe_size": "Vector3",
			"toe_spacing": "float",
			"toe_y": "float",
			"toe_z": "float",
			"whisker_points": [
				"Vector3"
			],
			"whisker_radius": "float"
		},
		"pavilion": {
			"balustrade_size": "Vector3",
			"balustrade_x": "float",
			"balustrade_y": "int",
			"balustrade_z": "float",
			"eave_center": "int",
			"eave_count": "int",
			"eave_size": "Vector3",
			"eave_spacing": "float",
			"eave_y": "float",
			"eave_z": "float",
			"floor_position": "Vector3",
			"floor_size": "Vector3",
			"foundation_position": "Vector3",
			"foundation_size": "Vector3",
			"gilt_foot_bottom": "float",
			"gilt_foot_height": "float",
			"gilt_foot_top": "float",
			"gilt_foot_y": "float",
			"lantern_position": "Vector3",
			"lantern_scale": "float",
			"lintel_size": "Vector3",
			"lintel_y": "float",
			"lintel_z": "float",
			"pillar_bottom": "float",
			"pillar_height": "float",
			"pillar_top": "float",
			"pillar_x": "float",
			"pillar_y": "float",
			"pillar_z": "float",
			"rail_count": "int",
			"rail_size": "Vector3",
			"rail_x": "float",
			"rail_y": "float",
			"rail_z_start": "float",
			"rail_z_step": "float",
			"roof_height": "float",
			"roof_position": "Vector3",
			"roof_radius": "float",
			"roof_scale_z": "float",
			"screen_count": "int",
			"screen_size": "Vector3",
			"screen_x_start": "float",
			"screen_x_step": "float",
			"screen_y": "float",
			"screen_z": "float",
			"scroll_size": "Vector3",
			"scroll_y": "float",
			"scroll_z": "float",
			"upper_roof_height": "float",
			"upper_roof_position": "Vector3",
			"upper_roof_radius": "float"
		},
		"waterfall": {
			"ribbon_center": "int",
			"ribbon_count": "int",
			"ribbon_depth": "float",
			"ribbon_span_divisor": "int",
			"ribbon_width_scale": "float",
			"ribbon_z_frequency": "float",
			"ribbon_z_wave": "float",
			"splash_count": "int",
			"splash_radius_base": "float",
			"splash_radius_step": "float",
			"splash_scale_z": "float",
			"splash_thickness": "float",
			"splash_y": "float",
			"splash_y_step": "float",
			"splash_z": "float",
			"spray_count": "int",
			"spray_size": "Vector3",
			"spray_x_scale": "float",
			"spray_y_range": "Vector2",
			"spray_z_range": "Vector2",
			"whitewater_offset": "Vector3",
			"whitewater_radius": "float"
		}
	},
	"ridge": {
		"base_height": "float",
		"bottom_radius": "float",
		"center_height": "float",
		"center_max_x": "float",
		"center_min_x": "float",
		"column_y_offset": "float",
		"count": "int",
		"height_frequency": "float",
		"height_wave": "float",
		"ledge_count": "int",
		"ledge_size": "Vector3",
		"ledge_start": "float",
		"ledge_step": "float",
		"ledge_tilt": "float",
		"ledge_x_wave": "float",
		"ledge_z_offset": "float",
		"moss_offset": "Vector3",
		"moss_size": "Vector3",
		"sides": "int",
		"spacing": "float",
		"start_x": "float",
		"top_radius": "float",
		"yaw_step": "float",
		"z": "float",
		"z_frequency": "float",
		"z_wave": "float"
	},
	"ruins": {
		"collar_heights": [
			"float"
		],
		"fallen_lintel": {
			"position": "Vector3",
			"rotation": "Vector3",
			"size": "Vector3"
		},
		"fern_count": "int",
		"fern_radius_x": "float",
		"fern_radius_z": "float",
		"fern_scale": "float",
		"lantern": {
			"position": "Vector3",
			"scale": "float",
			"title": "String",
			"yaw": "int"
		},
		"monolith": {
			"position": "Vector3",
			"size": "Vector3"
		},
		"offering_circle": {
			"position": "Vector3",
			"radius": "float",
			"thickness": "float"
		},
		"paving_count": "int",
		"paving_rotation": "float",
		"paving_size": "Vector3",
		"paving_x_step": "float",
		"paving_y": "float",
		"paving_z_step": "float",
		"pillar_offset": "float",
		"pillar_z": "float",
		"position": "Vector3",
		"rune_count": "int",
		"rune_size": "Vector3",
		"rune_start_y": "float",
		"rune_step_y": "float",
		"rune_z": "float",
		"scale": "float",
		"spiral": {
			"count": "int",
			"height_span": "float",
			"height_start": "float",
			"line_radius": "float",
			"radius": "float",
			"z": "float"
		},
		"vine_count": "int"
	},
	"sanctuary": {
		"garden_bridge_position": "Vector3",
		"gate": {
			"position": "Vector3",
			"title": "String"
		},
		"gate_cherries": [
			{
				"position": "Vector3",
				"scale": "float",
				"title": "String",
				"yaw": "float"
			}
		],
		"gate_lanterns": [
			{
				"position": "Vector3",
				"scale": "float",
				"title": "String",
				"yaw": "int"
			}
		],
		"margins": {
			"creeping_moss_count": "int",
			"creeping_size_x_range": "Vector2",
			"creeping_size_y": "float",
			"creeping_size_z_range": "Vector2",
			"creeping_x_base": "float",
			"creeping_x_jitter": "float",
			"creeping_y": "float",
			"creeping_z_jitter": "float",
			"creeping_z_start": "float",
			"creeping_z_step": "float",
			"ground_cover_count": "int",
			"ground_cover_size": "Vector3",
			"ground_cover_x_start": "float",
			"ground_cover_x_step": "float",
			"ground_cover_y": "float",
			"ground_cover_z_back": "float",
			"ground_cover_z_front": "float",
			"west_path_count": "int",
			"west_path_size": "Vector3",
			"west_path_start": "Vector3",
			"west_path_step": "Vector3"
		},
		"west_pool": {
			"bank_size": "Vector3",
			"bank_stones": "int",
			"bank_x": "float",
			"bank_y": "float",
			"bank_z_start": "float",
			"bank_z_step": "float",
			"lotus_count": "int",
			"lotus_scale": "float",
			"lotus_x_range": "Vector2",
			"lotus_y": "float",
			"lotus_z_range": "Vector2",
			"name": "String",
			"position": "Vector3",
			"water_size": "Vector3"
		}
	},
	"sanctuary_details": {
		"approach_fern_offset": "Vector3",
		"approach_fern_scale": "float",
		"approach_rubble_count": "int",
		"approach_rubble_size": "Vector3",
		"approach_rubble_x_start": "float",
		"approach_rubble_x_step": "float",
		"approach_rubble_y": "float",
		"approach_rubble_yaw_step": "float",
		"approach_rubble_z": "float",
		"approach_rubble_z_wave": "float",
		"blade_height_range": "Vector2",
		"blade_radius": "float",
		"blade_side": "float",
		"blades": "int",
		"boundary_scale": "float",
		"grass_density_threshold": "float",
		"grass_frequency_x": "float",
		"grass_frequency_z": "float",
		"grass_samples": "int",
		"grass_west_garden": {
			"x_max": "float",
			"x_min": "float",
			"z_max": "float",
			"z_min": "float"
		},
		"grass_x_range": "Vector2",
		"grass_y": "float",
		"grass_z_range": "Vector2",
		"guardians": [
			{
				"position": "Vector3",
				"title": "String",
				"yaw": "float"
			}
		],
		"petal_half_depth": "float",
		"petal_half_width": "float",
		"petal_interval": "int",
		"petal_offset": "Vector3",
		"rubble_count": "int",
		"rubble_fern_interval": "int",
		"rubble_fern_offset": "Vector3",
		"rubble_fern_scale": "float",
		"rubble_size_x_range": "Vector2",
		"rubble_size_y": "float",
		"rubble_size_z_range": "Vector2",
		"rubble_tilt": "float",
		"rubble_x_range": "Vector2",
		"rubble_y": "float",
		"rubble_z_range": "Vector2",
		"wetland_clear": {
			"x_min": "float",
			"z_max": "float"
		}
	},
	"shrine_banners": [
		{
			"position": "Vector3",
			"title": "String",
			"yaw": "float"
		}
	],
	"shrine_lanterns": [
		{
			"position": "Vector3",
			"scale": "float",
			"title": "String",
			"yaw": "int"
		}
	],
	"shrine_stairs": {
		"count": "int",
		"depth": "float",
		"height": "float",
		"post_height": "float",
		"post_interval": "int",
		"post_offset_x": "float",
		"post_size": "float",
		"width": "float",
		"x": "float",
		"z_start": "float",
		"z_step": "float"
	},
	"shrine_trees": [
		{
			"position": "Vector3",
			"scale": "float",
			"title": "String",
			"yaw": "float"
		}
	],
	"spires": {
		"base_height": "float",
		"bottom_radius": "float",
		"cap_size": "Vector3",
		"count": "int",
		"height_frequency": "float",
		"height_wave": "float",
		"sides": "int",
		"spacing": "float",
		"start_x": "float",
		"tilt": "float",
		"top_radius": "float",
		"z": "float"
	},
	"terraces": [
		{
			"center": "Vector3",
			"height": "float",
			"radius": "Vector2",
			"title": "String"
		}
	],
	"terrain": {
		"bottom_y": "float",
		"boulder_drop": "float",
		"boulder_radius": "float",
		"boulder_size": "Vector3",
		"boulder_skip_index": "int",
		"boulder_skip_titles": [
			"String"
		],
		"boulders": "int",
		"buttress_bottom_radius": "float",
		"buttress_height_frequency": "float",
		"buttress_height_min": "float",
		"buttress_height_span": "float",
		"buttress_radius": "float",
		"buttress_sides": "int",
		"buttress_top_radius": "float",
		"buttresses": "int",
		"insets": [
			"float"
		],
		"layers": "int",
		"middle_height": "float",
		"radius_frequency": "float",
		"radius_wave": "float",
		"shelf_offset_y": "float",
		"shelf_size": "Vector3",
		"sides": "int",
		"vine_line_radius": "float",
		"vine_max_height": "float",
		"vine_radius": "float",
		"vine_step_1": "Vector3",
		"vine_step_2": "Vector3"
	},
	"wetlands": {
		"bridge_lanterns": [
			{
				"position": "Vector3",
				"scale": "float",
				"title": "String",
				"yaw": "int"
			}
		],
		"crossing": {
			"bridge_position": "Vector3",
			"bridge_scale": "Vector3",
			"position": "Vector3"
		},
		"lily_bottom": "float",
		"lily_height": "float",
		"lily_offset": "Vector3",
		"lily_sides": "int",
		"lily_top": "float",
		"lotus_count": "int",
		"lotus_scale_range": "Vector2",
		"lotus_x_range": "Vector2",
		"lotus_y": "float",
		"lotus_z_range": "Vector2",
		"lower_falls": {
			"height": "float",
			"position": "Vector3",
			"title": "String",
			"width": "float"
		},
		"middle_basin": {
			"position": "Vector3",
			"size": "Vector3"
		},
		"ripple_interval": "int",
		"ripple_radius": "float",
		"ripple_thickness": "float",
		"shelf_banks": {
			"count": "int",
			"offset": "float",
			"size": "Vector3",
			"x": "float",
			"y": "float",
			"z_start": "float",
			"z_step": "float"
		},
		"shore": "PackedVector2Array",
		"shore_rock_moss_interval": "int",
		"shore_rock_size": "Vector3",
		"shore_rock_y": "float",
		"shore_rocks_per_edge": "int",
		"shore_y": "float",
		"spring_banks": {
			"count": "int",
			"offset": "float",
			"size": "Vector3",
			"x": "float",
			"y": "float",
			"z_start": "float",
			"z_step": "float"
		},
		"stepping_stones": {
			"bottom": "float",
			"count": "int",
			"height": "float",
			"sides": "int",
			"start": "Vector3",
			"step": "Vector3",
			"top": "float"
		},
		"upper_falls": {
			"height": "float",
			"position": "Vector3",
			"title": "String",
			"width": "float"
		},
		"upper_spring": {
			"position": "Vector3",
			"size": "Vector3"
		}
	}
}
