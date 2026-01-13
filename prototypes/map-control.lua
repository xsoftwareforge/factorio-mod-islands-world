-- add new elevation noise layer

local low_freq_noise = "quick_multioctave_noise{x = x + 10000, y = y, seed0 = map_seed, seed1 = 8, input_scale = 1/4, output_scale = 2/3, octaves = 8, octave_output_scale_multiplier = 1.5, octave_input_scale_multiplier = 1/2}"
local distance = "distance_from_nearest_point{x = x, y = y, points = starting_positions}"
local island_local_expressions = {
  low_freq_noise = low_freq_noise,
  distance = distance,
  safe_starting_radius = "max(1, starting_area_radius)",
}

local elev = {
  {
    type = "noise-expression",
    name = "kap-islands-world",
    intended_property = nil,
    description = "A world of many small islands",
    local_expressions = island_local_expressions,
    expression = "max(low_freq_noise - 15, clamp(low_freq_noise + 40 - distance / safe_starting_radius * 60, -40, 5))",
  },
  {
    type = "noise-expression",
    name = "kap-islands-world2",
    intended_property = "elevation",
    description = "A world of many small islands",
    local_expressions = island_local_expressions,
    expression = "max(low_freq_noise - 15, clamp(low_freq_noise + 40 - distance / safe_starting_radius * 60, -40, 5))",
  },
}
data:extend(elev)


-- increse stone patch size in start area
-- data.raw["resource"]["stone"]["autoplace"]["starting_area_size"] = 5500 * (0.005 / 3)

-- register dummy hidden terchnology that show warning message when disabled
local warning_item = {
	{
		type = "technology",
		name = "islands_world_warning_data",
		icon_size = 128,
		icon = "__base__/graphics/technology/steel-processing.png",
		enabled = false,
		effects = {},
		unit =
		{
			count = 1,
			ingredients = {},
			time = 5
		},
		order = "z-z"
	}
}
data:extend(warning_item)



