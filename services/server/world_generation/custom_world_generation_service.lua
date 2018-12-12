local Array2D = require 'stonehearth.services.server.world_generation.array_2D'
local CustomWorldGenerationService = class()

function CustomWorldGenerationService:set_blueprint(blueprint)
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
         landscaper:mark_water_bodies(full_elevation_map, full_feature_map)
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

return CustomWorldGenerationService