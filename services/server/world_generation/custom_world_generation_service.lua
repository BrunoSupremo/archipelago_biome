local Cube3 = _radiant.csg.Cube3
local Array2D = require 'stonehearth.services.server.world_generation.array_2D'
local Timer = require 'stonehearth.services.server.world_generation.timer'
local log = radiant.log.create_logger('world_generation')
local CustomWorldGenerationService = class()

function CustomWorldGenerationService:set_blueprint(blueprint)
   local biome_name = stonehearth.world_generation:get_biome_alias()
   local colon_position = string.find (biome_name, ":", 1, true) or -1
   local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
   local fn = "set_blueprint_" .. mod_name_containing_the_biome
   if self[fn] ~= nil then
      --found a function for the biome being used, named:
      -- self:set_blueprint_<biome_name>(args,...)
      self[fn](self, blueprint)
   else
      --there is no function for this specific biome, so call a copy of the original from stonehearth
      self:set_blueprint_original(blueprint)
   end
end

function CustomWorldGenerationService:set_blueprint_original(blueprint)
   assert(self._biome_generation_data, "cannot find biome_generation_data")
   local seconds = Timer.measure(
      function()
         local tile_size = self._biome_generation_data:get_tile_size()
         local macro_blocks_per_tile = tile_size / self._biome_generation_data:get_macro_block_size()
         local blueprint_generator = self.blueprint_generator
         local micro_map_generator = self._micro_map_generator
         local landscaper = self._landscaper
         local full_micro_map, full_underground_micro_map
         local full_elevation_map, full_underground_elevation_map, full_feature_map, full_habitat_map

         full_micro_map, full_elevation_map = micro_map_generator:generate_micro_map(blueprint.width, blueprint.height)
         full_underground_micro_map, full_underground_elevation_map = micro_map_generator:generate_underground_micro_map(full_micro_map)

         full_feature_map = Array2D(full_elevation_map.width, full_elevation_map.height)

         -- determine which features will be placed in which cells
         landscaper:mark_water_bodies(full_elevation_map, full_feature_map)
         landscaper:mark_trees(full_elevation_map, full_feature_map)
         landscaper:mark_berry_bushes(full_elevation_map, full_feature_map)
         landscaper:mark_plants(full_elevation_map, full_feature_map)
         landscaper:mark_boulders(full_elevation_map, full_feature_map)

         full_habitat_map = self._habitat_manager:derive_habitat_map(full_elevation_map, full_feature_map)

         -- shard the maps and store in the blueprint
         -- micro_maps are overlapping so they need a different sharding function
         -- these maps are at macro_block_size resolution (32x32)
         blueprint_generator:store_micro_map(blueprint, "micro_map", full_micro_map, macro_blocks_per_tile)
         blueprint_generator:store_micro_map(blueprint, "underground_micro_map", full_underground_micro_map, macro_blocks_per_tile)
         -- these maps are at feature_size resolution (16x16)
         blueprint_generator:shard_and_store_map(blueprint, "elevation_map", full_elevation_map)
         blueprint_generator:shard_and_store_map(blueprint, "underground_elevation_map", full_underground_elevation_map)
         blueprint_generator:shard_and_store_map(blueprint, "feature_map", full_feature_map)
         blueprint_generator:shard_and_store_map(blueprint, "habitat_map", full_habitat_map)

         -- location of the world origin in the coordinate system of the blueprint
         blueprint.origin_x = math.floor(blueprint.width * tile_size / 2)
         blueprint.origin_y = math.floor(blueprint.height * tile_size / 2)

         -- create the overview map
         self.overview_map:derive_overview_map(full_elevation_map, full_feature_map, blueprint.origin_x, blueprint.origin_y)

         self._blueprint = blueprint
      end
   )
   log:info('Blueprint population time: %.3fs', seconds)
end

function CustomWorldGenerationService:set_blueprint_archipelago_biome(blueprint)
   assert(self._biome_generation_data, "cannot find biome_generation_data")
         local tile_size = self._biome_generation_data:get_tile_size()
         local macro_blocks_per_tile = tile_size / self._biome_generation_data:get_macro_block_size()
         local blueprint_generator = self.blueprint_generator
         local micro_map_generator = self._micro_map_generator
         local landscaper = self._landscaper
         local full_micro_map, full_underground_micro_map
         local full_elevation_map, full_underground_elevation_map, full_feature_map, full_habitat_map

         full_micro_map, full_elevation_map = micro_map_generator:generate_micro_map(blueprint.width, blueprint.height)
         full_underground_micro_map, full_underground_elevation_map = micro_map_generator:generate_underground_micro_map(full_micro_map)

         full_feature_map = Array2D(full_elevation_map.width, full_elevation_map.height)

         -- determine which features will be placed in which cells
         landscaper:mark_water_bodies_archipelago_biome(full_elevation_map, full_feature_map)
         landscaper:mark_trees(full_elevation_map, full_feature_map)
         landscaper:mark_berry_bushes(full_elevation_map, full_feature_map)
         landscaper:mark_plants(full_elevation_map, full_feature_map)
         landscaper:mark_boulders(full_elevation_map, full_feature_map)
         landscaper:mark_caves(full_elevation_map, full_feature_map)

         full_habitat_map = self._habitat_manager:derive_habitat_map(full_elevation_map, full_feature_map)

         -- shard the maps and store in the blueprint
         -- micro_maps are overlapping so they need a different sharding function
         -- these maps are at macro_block_size resolution (32x32)
         blueprint_generator:store_micro_map(blueprint, "micro_map", full_micro_map, macro_blocks_per_tile)
         blueprint_generator:store_micro_map(blueprint, "underground_micro_map", full_underground_micro_map, macro_blocks_per_tile)
         -- these maps are at feature_size resolution (16x16)
         blueprint_generator:shard_and_store_map(blueprint, "elevation_map", full_elevation_map)
         blueprint_generator:shard_and_store_map(blueprint, "underground_elevation_map", full_underground_elevation_map)
         blueprint_generator:shard_and_store_map(blueprint, "feature_map", full_feature_map)
         blueprint_generator:shard_and_store_map(blueprint, "habitat_map", full_habitat_map)

         -- location of the world origin in the coordinate system of the blueprint
         blueprint.origin_x = math.floor(blueprint.width * tile_size / 2)
         blueprint.origin_y = math.floor(blueprint.height * tile_size / 2)

         -- create the overview map
         self.overview_map:derive_overview_map(full_elevation_map, full_feature_map, blueprint.origin_x, blueprint.origin_y)

         self._blueprint = blueprint
end

function CustomWorldGenerationService:_add_water_bodies(regions)
   local biome_name = stonehearth.world_generation:get_biome_alias()
   local colon_position = string.find (biome_name, ":", 1, true) or -1
   local mod_name_containing_the_biome = string.sub (biome_name, 1, colon_position-1)
   local fn = "_add_water_bodies_" .. mod_name_containing_the_biome
   if self[fn] ~= nil then
      --found a function for the biome being used, named:
      -- self:_add_water_bodies_<biome_name>(args,...)
      self[fn](self, regions)
   else
      --there is no function for this specific biome, so call a copy of the original from stonehearth
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