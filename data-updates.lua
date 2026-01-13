
-- add map presets
if angelsmods and angelsmods.refining then
	data.raw["map-gen-presets"]["default"]["kap_islands"] =
{
	order = "w",
	basic_settings =
	{
		autoplace_controls = {
--[[
			["angels-ore1"] = {
				frequency = "high",
				size = "high"
			},
			["angels-ore2"] = {
				frequency = "high",
				size = "high"
			},
			["angels-ore3"] = {
				frequency = "high",
				size = "high"
			},
			["angels-ore4"] = {
				frequency = "high",
				size = "high"
			},
			["angels-fissure"] = {
				frequency = "high",
				size = "high"
			},
]]--
			["coal"] = {
				frequency = "high",
				size = "high"
			},
			["crude-oil"] = {
				frequency = "high",
				size = "high"
			},
		},
		property_expression_names = {
			elevation = "kap-islands-world2",
		},
	}
}
--[[
	if angelsmods.industry or (bobmods and bobmods.plates) then
		data.raw["map-gen-presets"]["default"]["kap_islands"].basic_settings.autoplace_controls["angels-ore5"] = {frequency = "high", size = "high"}
		data.raw["map-gen-presets"]["default"]["kap_islands"].basic_settings.autoplace_controls["angels-ore6"] = {frequency = "high", size = "high"}
	end
]]--
else
	data.raw["map-gen-presets"]["default"]["kap_islands"] =
{
	order = "w",
	basic_settings =
	{
		autoplace_controls = {
			["iron-ore"] = {
				frequency = "high",
				size = "high"
			},
			["copper-ore"] = {
				frequency = "high",
				size = "high"
			},
			["coal"] = {
				frequency = "high",
				size = "high"
			},
			["stone"] = {
				frequency = "high",
			},
			["crude-oil"] = {
				frequency = "high",
				size = "high"
			},
			["uranium-ore"] = {
				size = "high"
			},
		},
		property_expression_names = {
			elevation = "kap-islands-world2",
		},
	}
}
end

