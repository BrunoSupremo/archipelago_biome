local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3
--local log = radiant.log.create_logger('meu_log')

local CustomHeightMapRenderer = class()

local STRATA_HEIGHT = 2
local NUM_STRATA = 2
local STRATA_PERIOD = STRATA_HEIGHT * NUM_STRATA

function CustomHeightMapRenderer:_add_soil_strata_to_region(region3, cube3)
   local mod_name = stonehearth.world_generation:get_biome_alias()
   --mod_name is the mod that has the current biome
   local colon_pos = string.find (mod_name, ":", 1, true) or -1
   mod_name = "_add_soil_strata_to_region_" .. string.sub (mod_name, 1, colon_pos-1)
   if self[mod_name]~=nil then
      self[mod_name](self,region3, cube3)
   else
      self:_add_soil_strata_to_region_original(region3, cube3)
   end
end

function CustomHeightMapRenderer:_add_soil_strata_to_region_original(region3, cube3)
   local y_min = cube3.min.y
   local y_max = cube3.max.y
   local j_min = math.floor(cube3.min.y / STRATA_HEIGHT) * STRATA_HEIGHT
   local j_max = cube3.max.y

   for j = j_min, j_max, STRATA_HEIGHT do
      local lower = math.max(j, y_min)
      local upper = math.min(j+STRATA_HEIGHT, y_max)
      local block_type = j % STRATA_PERIOD == 0 and self._block_types.soil_light or self._block_types.soil_dark

      region3:add_unique_cube(Cube3(
            Point3(cube3.min.x, lower, cube3.min.z),
            Point3(cube3.max.x, upper, cube3.max.z),
            block_type
         ))
   end
end

function CustomHeightMapRenderer:_add_soil_strata_to_region_archipelago_biome(region3, cube3)
   local y_min = cube3.min.y
   local y_max = cube3.max.y
   local j_min = math.floor(cube3.min.y / STRATA_HEIGHT) * STRATA_HEIGHT
   local j_max = cube3.max.y

   for j = j_min, j_max, STRATA_HEIGHT do
      local lower = math.max(j, y_min)
      local upper = math.min(j+STRATA_HEIGHT, y_max)
      local block_type = j % STRATA_PERIOD == 0 and self._block_types.sand_soil_light or self._block_types.sand_soil_dark

      region3:add_unique_cube(Cube3(
            Point3(cube3.min.x, lower, cube3.min.z),
            Point3(cube3.max.x, upper, cube3.max.z),
            block_type
         ))
   end
end

function CustomHeightMapRenderer:_add_plains_to_region(region3, rect, height)
   local mod_name = stonehearth.world_generation:get_biome_alias()
   --mod_name is the mod that has the current biome
   local colon_pos = string.find (mod_name, ":", 1, true) or -1
   mod_name = "_add_plains_to_region_" .. string.sub (mod_name, 1, colon_pos-1)
   if self[mod_name]~=nil then
      self[mod_name](self,region3,rect,height)
   else
      self:_add_plains_to_region_original(region3, rect, height)
   end
end

function CustomHeightMapRenderer:_add_plains_to_region_original(region3, rect, height)
   local terrain_info = self._biome:get_terrain_info()
   local plains_max_height = terrain_info.plains.height_max
   local material = height < plains_max_height and self._block_types.dirt or self._block_types.grass

   self:_add_soil_strata_to_region(region3, Cube3(
         Point3(rect.min.x, 0,        rect.min.y),
         Point3(rect.max.x, height-1, rect.max.y)
      ))

   region3:add_unique_cube(Cube3(
         Point3(rect.min.x, height-1, rect.min.y),
         Point3(rect.max.x, height,   rect.max.y),
         material
      ))
end

function CustomHeightMapRenderer:_add_plains_to_region_archipelago_biome(region3, rect, height)
   local terrain_info = self._biome:get_terrain_info()
   local plains_max_height = terrain_info.plains.height_max
   local material = height < plains_max_height and self._block_types.dirt or self._block_types.sand

   self:_add_soil_strata_to_region_archipelago_biome(region3, Cube3(
         Point3(rect.min.x, 0,        rect.min.y),
         Point3(rect.max.x, height-1, rect.max.y)
      ))

   region3:add_unique_cube(Cube3(
         Point3(rect.min.x, height-1, rect.min.y),
         Point3(rect.max.x, height,   rect.max.y),
         material
      ))
end

function CustomHeightMapRenderer:_add_foothills_to_region(region3, rect, height)
   local mod_name = stonehearth.world_generation:get_biome_alias()
   --log:error('nome %s', mod_name)
   --mod_name is the mod that has the current biome
   local colon_pos = string.find (mod_name, ":", 1, true) or -1
   mod_name = "_add_foothills_to_region_" .. string.sub (mod_name, 1, colon_pos-1)
   if self[mod_name]~=nil then
      self[mod_name](self,region3,rect,height)
   else
      self:_add_foothills_to_region_original(region3, rect, height)
   end
end

function CustomHeightMapRenderer:_add_foothills_to_region_original(region3, rect, height)
   local terrain_info = self._biome:get_terrain_info()
   local foothills_step_size = terrain_info.foothills.step_size
   local plains_max_height = terrain_info.plains.height_max

   local has_grass = height % foothills_step_size == 0
   local soil_top = has_grass and height-1 or height

   self:_add_soil_strata_to_region(region3, Cube3(
         Point3(rect.min.x, 0,        rect.min.y),
         Point3(rect.max.x, soil_top, rect.max.y)
      ))

   if has_grass then
      local material = self._block_types.grass_hills
      if material == nil then
         material = self._block_types.grass
      end
      region3:add_unique_cube(Cube3(
            Point3(rect.min.x, soil_top, rect.min.y),
            Point3(rect.max.x, height,   rect.max.y),
            material
         ))
   end
end

function CustomHeightMapRenderer:_add_foothills_to_region_archipelago_biome(region3, rect, height)
   self:_add_soil_strata_to_region_original(region3, Cube3(
      Point3(rect.min.x, 0,        rect.min.y),
      Point3(rect.max.x, height-1, rect.max.y)
   ))

   local material = self._block_types.grass_hills or self._block_types.grass

   region3:add_unique_cube(Cube3(
         Point3(rect.min.x, height-1, rect.min.y),
         Point3(rect.max.x, height,   rect.max.y),
         material
      ))
end

function CustomHeightMapRenderer:_add_mountains_to_region(region3, rect, height)
   local mod_name = stonehearth.world_generation:get_biome_alias()
   --mod_name is the mod that has the current biome
   local colon_pos = string.find (mod_name, ":", 1, true) or -1
   mod_name = "_add_mountains_to_region_" .. string.sub (mod_name, 1, colon_pos-1)
   if self[mod_name]~=nil then
      self[mod_name](self,region3,rect,height)
   else
      self:_add_mountains_to_region_original(region3, rect, height)
   end
end

function CustomHeightMapRenderer:_add_mountains_to_region_original(region3, rect, height)
   local rock_layers = self._rock_layers
   local num_rock_layers = self._num_rock_layers
   local i, block_min, block_max
   local stop = false

   block_min = 0

   for i=1, num_rock_layers do
      if (i == num_rock_layers) or (height <= rock_layers[i].max_height) then
         block_max = height
         stop = true
      else
         block_max = rock_layers[i].max_height
      end

      region3:add_unique_cube(Cube3(
            Point3(rect.min.x, block_min, rect.min.y),
            Point3(rect.max.x, block_max, rect.max.y),
            rock_layers[i].terrain_tag
         ))

      if stop then return end
      block_min = block_max
   end
end

function CustomHeightMapRenderer:_add_mountains_to_region_archipelago_biome(region3, rect, height)
   local rock_layers = self._rock_layers
   local num_rock_layers = self._num_rock_layers
   local i, block_min, block_max
   local stop = false

   block_min = 0

   local max_foothills_height = 55
   local max_grass_layer = max_foothills_height + 20

   for i=1, num_rock_layers do
      if (i == num_rock_layers) or (height <= rock_layers[i].max_height) then
         block_max = height
         stop = true
      else
         block_max = rock_layers[i].max_height
      end

      local has_grass = stop and block_max > max_foothills_height and block_max < max_grass_layer
      local rock_top = has_grass and block_max-1 or block_max

      region3:add_unique_cube(Cube3(
         Point3(rect.min.x, block_min, rect.min.y),
         Point3(rect.max.x, rock_top, rect.max.y),
         rock_layers[i].terrain_tag
      ))
      
      if has_grass then 
         local material = self._block_types.grass_hills or self._block_types.grass
         region3:add_unique_cube(Cube3(
            Point3(rect.min.x, rock_top, rect.min.y),
            Point3(rect.max.x, block_max, rect.max.y),
            material
         ))
      end

      if stop then return end
      block_min = block_max
   end
end

return CustomHeightMapRenderer
