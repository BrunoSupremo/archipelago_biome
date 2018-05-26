local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3
--local log = radiant.log.create_logger('meu_log')

local CustomHeightMapRenderer = class()

local STRATA_HEIGHT = 2
local NUM_STRATA = 2
local STRATA_PERIOD = STRATA_HEIGHT * NUM_STRATA

function CustomHeightMapRenderer:_add_soil_strata_to_region(region3, cube3, sandy)
   local y_min = cube3.min.y
   local y_max = cube3.max.y
   local j_min = math.floor(cube3.min.y / STRATA_HEIGHT) * STRATA_HEIGHT
   local j_max = cube3.max.y

   for j = j_min, j_max, STRATA_HEIGHT do
      local lower = math.max(j, y_min)
      local upper = math.min(j+STRATA_HEIGHT, y_max)
      local block_type
      if sandy then
         block_type = j % STRATA_PERIOD == 0 and self._block_types.sand_soil_light or self._block_types.sand_soil_dark
      else
         block_type = j % STRATA_PERIOD == 0 and self._block_types.soil_light or self._block_types.soil_dark
      end
      region3:add_unique_cube(Cube3(
            Point3(cube3.min.x, lower, cube3.min.z),
            Point3(cube3.max.x, upper, cube3.max.z),
            block_type
         ))
   end
end

function CustomHeightMapRenderer:_add_plains_to_region(region3, rect, height)
   local material = self._block_types.sand

   self:_add_soil_strata_to_region(region3, Cube3(
         Point3(rect.min.x, 0,        rect.min.y),
         Point3(rect.max.x, height-1, rect.max.y)
      ), true)

   region3:add_unique_cube(Cube3(
         Point3(rect.min.x, height-1, rect.min.y),
         Point3(rect.max.x, height,   rect.max.y),
         material
      ))
end

function CustomHeightMapRenderer:_add_foothills_to_region(region3, rect, height)
   self:_add_soil_strata_to_region(region3, Cube3(
      Point3(rect.min.x, 0,        rect.min.y),
      Point3(rect.max.x, height-1, rect.max.y)
   ))

   local material = self._block_types.grass_hills

   region3:add_unique_cube(Cube3(
         Point3(rect.min.x, height-1, rect.min.y),
         Point3(rect.max.x, height,   rect.max.y),
         material
      ))
end

function CustomHeightMapRenderer:_add_mountains_to_region(region3, rect, height)
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
         local material = self._block_types.grass_hills
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
