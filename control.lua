local STARTING_RESOURCES = {
  {name = "iron-ore", radius = 9, amount = 1200},
  {name = "copper-ore", radius = 9, amount = 1200},
  {name = "stone", radius = 7, amount = 900},
  {name = "coal", radius = 8, amount = 1000},
}

local OFFSET_VECTORS = {
  {x = 1, y = 0},
  {x = 0, y = 1},
  {x = -1, y = 0},
  {x = 0, y = -1},
  {x = 0.7, y = 0.7},
  {x = -0.7, y = 0.7},
  {x = -0.7, y = -0.7},
  {x = 0.7, y = -0.7},
}

local function is_land_tile(surface, position)
  local tile = surface.get_tile(position)
  return tile and not tile.collides_with("water-tile")
end

local function find_land_near(surface, target, search_radius)
  local step = 1
  for radius = 0, search_radius, step do
    for dx = -radius, radius, step do
      for dy = -radius, radius, step do
        local position = {
          x = math.floor(target.x + dx),
          y = math.floor(target.y + dy),
        }
        if is_land_tile(surface, position) then
          return position
        end
      end
    end
  end
  return nil
end

local function create_resource_patch(surface, name, center, radius, amount)
  local radius_sq = radius * radius
  local placed = 0
  for dx = -radius, radius do
    for dy = -radius, radius do
      if (dx * dx + dy * dy) <= radius_sq then
        local position = {x = center.x + dx, y = center.y + dy}
        if is_land_tile(surface, position) and surface.count_entities_filtered{position = position, type = "resource"} == 0 then
          local entity = surface.create_entity{name = name, amount = amount, position = position}
          if entity then
            placed = placed + 1
          end
        end
      end
    end
  end
  return placed
end

local function place_resource_patch(surface, resource, spawn, starting_radius, resource_index)
  local max_center = math.max(2, math.floor(starting_radius - 2))
  local offset = math.max(8, math.floor(starting_radius * 0.35))
  if offset > max_center then
    offset = max_center
  end
  local search_radius = math.min(24, max_center)

  for radius = resource.radius, 2, -1 do
    for offset_index = 0, #OFFSET_VECTORS - 1 do
      local vector = OFFSET_VECTORS[((resource_index - 1 + offset_index) % #OFFSET_VECTORS) + 1]
      local target = {x = spawn.x + vector.x * offset, y = spawn.y + vector.y * offset}
      local center = find_land_near(surface, target, search_radius)
      if center then
        if create_resource_patch(surface, resource.name, center, radius, resource.amount) > 0 then
          return true
        end
      end
    end

    local center = find_land_near(surface, spawn, max_center)
    if center then
      if create_resource_patch(surface, resource.name, center, radius, resource.amount) > 0 then
        return true
      end
    end
  end

  return false
end

local function ensure_starting_resources(surface)
  if not (surface and surface.valid) then
    return
  end

  global.islands_world_starting_resources_done = global.islands_world_starting_resources_done or {}
  if global.islands_world_starting_resources_done[surface.index] then
    return
  end

  local force = game.forces["player"]
  if not force then
    return
  end

  local spawn = force.get_spawn_position(surface)
  local starting_radius = surface.get_starting_area_radius and surface.get_starting_area_radius() or 96
  if starting_radius <= 0 then
    starting_radius = 96
  end

  local start_area = {
    {spawn.x - starting_radius, spawn.y - starting_radius},
    {spawn.x + starting_radius, spawn.y + starting_radius},
  }

  local all_present = true
  for index, resource in ipairs(STARTING_RESOURCES) do
    if surface.count_entities_filtered{area = start_area, name = resource.name} == 0 then
      if not place_resource_patch(surface, resource, spawn, starting_radius, index) then
        all_present = false
      end
    end
    if surface.count_entities_filtered{area = start_area, name = resource.name} == 0 then
      all_present = false
    end
  end

  if all_present then
    global.islands_world_starting_resources_done[surface.index] = true
  end
end

local function enable_islands_world()
  local surface = game.surfaces[1]
  if surface then
    local mgs = surface.map_gen_settings
    mgs.property_expression_names.elevation = "kap-islands-world2"
    surface.map_gen_settings = mgs
    ensure_starting_resources(surface)
  end
end

script.on_configuration_changed(function(f)
  if f.mod_changes["islands_world"] and f.mod_changes["islands_world"]["old_version"] and f.mod_changes["islands_world"]["old_version"] < "0.17" then
    for _, surface in pairs(game.surfaces) do
      local mgs = surface.map_gen_settings
      if mgs.property_expression_names.elevation and mgs.property_expression_names.elevation == "0_16-elevation" then
        mgs.property_expression_names.elevation = "kap-islands-world"
        surface.map_gen_settings = mgs
      end
    end
  end

  if f.mod_changes["islands_world"] then
    global.islands_world_starting_resources_done = {}
    ensure_starting_resources(game.surfaces[1])
  end
end)

script.on_load(function()
  commands.add_command("enable_islands_world", "", enable_islands_world)
end)

script.on_init(function()
  commands.add_command("enable_islands_world", "", enable_islands_world)
  ensure_starting_resources(game.surfaces[1])
end)

script.on_event(defines.events.on_chunk_generated, function(event)
  if not global.islands_world_starting_resources_done or not global.islands_world_starting_resources_done[event.surface.index] then
    ensure_starting_resources(event.surface)
  end
end)
