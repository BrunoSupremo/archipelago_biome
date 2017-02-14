local Cube3 = _radiant.csg.Cube3
local CustomWorldGenerationService = class()

function CustomWorldGenerationService:_add_water_bodies(regions)
   local mod_name = stonehearth.world_generation:get_biome_alias()
   --mod_name is the mod that has the current biome
   local colon_pos = string.find (mod_name, ":", 1, true) or -1
   mod_name = "_add_water_bodies_" .. string.sub (mod_name, 1, colon_pos-1)
   if self[mod_name]~=nil then
      self[mod_name](self,regions)
   else
      self:_add_water_bodies_original(regions)
   end
end

function CustomWorldGenerationService:_add_water_bodies_original(regions)
   local water_height_delta = 1.5

   for _, terrain_region in pairs(regions) do
      terrain_region:force_optimize_by_merge('add water bodies')

      local terrain_bounds = terrain_region:get_bounds()

      -- Water level is 1.5 blocks below terrain.
      -- Avoid filling to integer height so that we can avoid raise and lower layer spam.
      local height = terrain_bounds:get_size().y - water_height_delta

      local water_bounds = Cube3(terrain_bounds)
      water_bounds.max.y = water_bounds.max.y - math.floor(water_height_delta)

      local water_region = terrain_region:intersect_cube(water_bounds)
      stonehearth.hydrology:create_water_body_with_region(water_region, height)
   end
end

function CustomWorldGenerationService:_add_water_bodies_archipelago_biome(regions)
   local water_height_delta = stonehearth.world_generation:get_biome_generation_data():get_landscape_info().water.water_height_delta or 1.5

   for _, terrain_region in pairs(regions) do
      terrain_region:force_optimize_by_merge('add water bodies')

      local terrain_bounds = terrain_region:get_bounds()

      local height = terrain_bounds:get_size().y - water_height_delta

      local water_bounds = Cube3(terrain_bounds)
      water_bounds.max.y = water_bounds.max.y - math.floor(water_height_delta)

      local water_region = terrain_region:intersect_cube(water_bounds)
      stonehearth.hydrology:create_water_body_with_region(water_region, height)
   end
end

return CustomWorldGenerationService