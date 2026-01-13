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
local NEIGHBOR_OFFSETS = {
  {x = 1, y = 0},
  {x = -1, y = 0},
  {x = 0, y = 1},
  {x = 0, y = -1},
}
local FORCE_LAND_TILE = "grass-1"

local function set_island_tile(island_tiles, x, y)
  local column = island_tiles[x]
  if not column then
    column = {}
    island_tiles[x] = column
  end
  column[y] = true
end

local function is_island_tile(island_tiles, x, y)
  local column = island_tiles[x]
  return column and column[y] or false
end

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

local function ensure_land_patch(surface, center, radius, island_tiles)
  local radius_sq = radius * radius
  local tiles = {}
  for dx = -radius, radius do
    for dy = -radius, radius do
      if (dx * dx + dy * dy) <= radius_sq then
        local position = {x = center.x + dx, y = center.y + dy}
        if island_tiles then
          set_island_tile(island_tiles, position.x, position.y)
        end
        if not is_land_tile(surface, position) then
          tiles[#tiles + 1] = {name = FORCE_LAND_TILE, position = position}
        end
      end
    end
  end
  if #tiles > 0 then
    surface.set_tiles(tiles, true)
  end
end

local function clear_blocking_entities(surface, area)
  local entities = surface.find_entities_filtered{area = area}
  for _, entity in ipairs(entities) do
    if entity.valid then
      local entity_force = entity.force
      local is_neutral = entity_force and entity_force.name == "neutral"
      if is_neutral then
        local entity_type = entity.type
        if entity_type == "tree"
          or entity_type == "simple-entity"
          or entity_type == "simple-entity-with-owner"
          or entity_type == "cliff" then
          entity.destroy()
        end
      end
    end
  end
end

local function build_spawn_island(surface, spawn, search_radius)
  local spawn_tile = {x = math.floor(spawn.x), y = math.floor(spawn.y)}
  if not is_land_tile(surface, spawn_tile) then
    local land = find_land_near(surface, spawn_tile, math.max(4, search_radius))
    if land then
      spawn_tile = land
    end
  end

  local island_tiles = {}
  if not is_land_tile(surface, spawn_tile) then
    ensure_land_patch(surface, spawn_tile, 2, island_tiles)
  end
  set_island_tile(island_tiles, spawn_tile.x, spawn_tile.y)

  local min_x = spawn_tile.x - search_radius
  local max_x = spawn_tile.x + search_radius
  local min_y = spawn_tile.y - search_radius
  local max_y = spawn_tile.y + search_radius

  local queue = {spawn_tile}
  local head = 1
  while head <= #queue do
    local current = queue[head]
    head = head + 1
    for _, offset in ipairs(NEIGHBOR_OFFSETS) do
      local x = current.x + offset.x
      local y = current.y + offset.y
      if x >= min_x and x <= max_x and y >= min_y and y <= max_y then
        if not is_island_tile(island_tiles, x, y) then
          local position = {x = x, y = y}
          if is_land_tile(surface, position) then
            set_island_tile(island_tiles, x, y)
            queue[#queue + 1] = position
          end
        end
      end
    end
  end

  return island_tiles, spawn_tile
end

local function find_island_land_near(surface, island_tiles, target, search_radius)
  if not island_tiles then
    return find_land_near(surface, target, search_radius)
  end

  local step = 1
  for radius = 0, search_radius, step do
    for dx = -radius, radius, step do
      for dy = -radius, radius, step do
        local x = math.floor(target.x + dx)
        local y = math.floor(target.y + dy)
        if is_island_tile(island_tiles, x, y) then
          return {x = x, y = y}
        end
      end
    end
  end
  return nil
end

local function resource_exists_on_island(surface, resource_name, island_tiles, spawn_tile, search_radius)
  if not island_tiles then
    return false
  end

  local area = {
    {spawn_tile.x - search_radius, spawn_tile.y - search_radius},
    {spawn_tile.x + search_radius, spawn_tile.y + search_radius},
  }
  local entities = surface.find_entities_filtered{area = area, name = resource_name}
  for _, entity in ipairs(entities) do
    local x = math.floor(entity.position.x)
    local y = math.floor(entity.position.y)
    if is_island_tile(island_tiles, x, y) then
      return true
    end
  end
  return false
end

local function create_resource_patch(surface, name, center, radius, amount, island_tiles)
  ensure_land_patch(surface, center, radius, island_tiles)
  local area = {
    {center.x - radius, center.y - radius},
    {center.x + radius, center.y + radius},
  }
  clear_blocking_entities(surface, area)
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

local function place_resource_patch(surface, resource, spawn_tile, starting_radius, resource_index, island_tiles)
  local max_center = math.max(2, math.floor(starting_radius - 2))
  local offset = math.max(8, math.floor(starting_radius * 0.35))
  if offset > max_center then
    offset = max_center
  end
  local search_radius = math.min(24, max_center)

  for radius = resource.radius, 2, -1 do
    for offset_index = 0, #OFFSET_VECTORS - 1 do
      local vector = OFFSET_VECTORS[((resource_index - 1 + offset_index) % #OFFSET_VECTORS) + 1]
      local target = {x = spawn_tile.x + vector.x * offset, y = spawn_tile.y + vector.y * offset}
      local center = find_island_land_near(surface, island_tiles, target, search_radius)
      if center then
        if create_resource_patch(surface, resource.name, center, radius, resource.amount, island_tiles) > 0 then
          return true
        end
      end
    end

    local center = find_island_land_near(surface, island_tiles, spawn_tile, max_center)
    if center then
      if create_resource_patch(surface, resource.name, center, radius, resource.amount, island_tiles) > 0 then
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
  local island_tiles, spawn_tile = build_spawn_island(surface, spawn, starting_radius)

  local all_present = true
  for index, resource in ipairs(STARTING_RESOURCES) do
    local present = resource_exists_on_island(surface, resource.name, island_tiles, spawn_tile, starting_radius)
    if not present then
      present = place_resource_patch(surface, resource, spawn_tile, starting_radius, index, island_tiles)
    end
    if not present then
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
