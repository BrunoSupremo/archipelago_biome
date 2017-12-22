local csg_lib = require 'stonehearth.lib.csg.csg_lib'
local rng = _radiant.math.get_default_rng()
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3

local ChooseWaterLocationOutsideTown = class()

function ChooseWaterLocationOutsideTown:initialize()
   self._sv.min_range = nil
   self._sv.max_range = nil
   self._sv.target_region = nil
   self._sv.callback  = nil
   self._sv.found_location = false
   self._sv.last_hull_index = nil
   self._sv.num_perimeter_points_searched = 0
   self._sv.destroyed = false
end

--Choose a location outside town to create something
--@param min_range - minimum range from the edge of town
--@param max_range - maximum range from the edge of town
--@param callback - fn to call when we've got the region
--@param target_region - optional, area around the target location to ensure is clear, for placing items
function ChooseWaterLocationOutsideTown:create(min_range, max_range, callback, target_region)
   if not target_region then
      -- default to a 15x15 area of flatness which fits just inside a world generation feature cell
      local cube = Cube3(Point3.zero):inflated(Point3(7, 0, 7))
      target_region = Region3(cube)
   end

   self._sv.min_range = min_range
   self._sv.max_range = max_range
   self._sv.target_region = target_region
   self._sv.callback  = callback
end

function ChooseWaterLocationOutsideTown:activate()
   self._max_range_squared = self._sv.max_range * self._sv.max_range
   self._min_range_2d = Point2(self._sv.min_range, self._sv.min_range)
   self._max_y = radiant.terrain.get_terrain_component():get_bounds().max.y
   self._closed = {}

   self._log = radiant.log.create_logger('game_master.choose_water_location_outside_town')
                              :set_prefix('choose loc outside city')

   self:_destroy_find_location_timer()

   if not self._sv.found_location and not self._sv.destroyed then
      self._log:info('On Activate, try to find a location outside town!')
      self:_create_search_thread()
   end
end

function ChooseWaterLocationOutsideTown:destroy()
   self:_destroy_job()
   self:_destroy_find_location_timer()
   self._sv.callback = nil -- make sure we no longer have access to callback, since yielded coroutine could return and try to create camp on a destroyed encounter
   self._sv.destroyed = true
   self.__saved_variables:mark_changed()
end

function ChooseWaterLocationOutsideTown:_get_camp_region(location)
   if not self._sv.target_region then
      return nil
   end
   return self._sv.target_region:translated(location)
end

function ChooseWaterLocationOutsideTown:_is_camp_too_close(location, camp_region, territory)
   if not camp_region then
      -- if the user didn't specify a region, just create a region with a single point in it
      camp_region = Region3()
      camp_region:add_point(location)
   end

   -- Make sure the camp_region is at least min_range from any territory marked by the player (or all players)
   local territory = stonehearth.terrain:get_total_territory()
   local claimed_region = territory:get_region()
   local temp = camp_region:project_onto_xz_plane():inflated(self._min_range_2d)
   local result = temp:intersects_region(claimed_region)
   return result
end

function ChooseWaterLocationOutsideTown:_try_location(location, camp_region)
   if location.y ~= 39 then
      return false
   end

   local test_region

   if camp_region then
      -- Check that there is no terrain above the surface of the region
      if radiant.terrain.intersects_region(camp_region) then
         self._log:info('location %s intersects terrain. trying again.', location)
         return false
      end

      -- Check that the region is supported by terrain
      local intersection = radiant.terrain.intersect_region(camp_region:translated(-Point3.unit_y))
      if intersection:get_area() ~= camp_region:get_area() then
         self._log:info('location %s not flat. trying again.', location)
         return false
      end

      test_region = camp_region
   else
      test_region = Region3()
      test_region:add_point(location)
   end

   -- Check that we're not inside a water body
   -- local entities = radiant.terrain.get_entities_in_region(test_region)
   -- for _, entity in pairs(entities) do
   --    local water_component = entity:get_component('stonehearth:water')
   --    if water_component then
   --       return false
   --    end
   -- end

   -- Avoid tunnels
   local test_point = Point3(location)
   test_point.y = self._max_y
   local surface_point = radiant.terrain.get_point_on_terrain(test_point)
   if location ~= surface_point then
      return false
   end

   -- give the callback a shot...
   self._log:info('About to check if I have a callback!')
   if self._sv.callback then
      self._log:info('Choose location got a callback! Calling it!')
      if not self:_invoke_callback('check_location', location, camp_region) then
         return false
      end
   end

   --if everything is fine, succeed!
   self._log:info('found location %s', location)
   self:_finalize_location(location, camp_region)

   return true
end

function ChooseWaterLocationOutsideTown:_create_search_thread()
   assert(not self._job)
   -- start a background job to find a location.
   self._job = radiant.create_background_task('choose location outside town', function()
         self:_try_finding_location()
      end)
end

function ChooseWaterLocationOutsideTown:_try_finding_location()
   local territory = stonehearth.terrain:get_total_territory()

   if next(territory:get_convex_hull()) == nil then
      self._log:always('could not choose location outside town because territory is empty')
   end

   local perf_timer = radiant.create_perf_timer()
   perf_timer:start()

   local function stop_timer(perf_timer, result, num_points)
      if perf_timer:is_running() then
         local ms = perf_timer:stop()
         if ms > 200 then
            local error_str = string.format('choose_water_location_outside_town took %dms to complete. Perimeter points searched: %d. Result: %s', ms, num_points, result)
            self._log:always(error_str)
         end
      end
   end

   while true do
      self._sv.num_perimeter_points_searched = self._sv.num_perimeter_points_searched + 1

      -- refetch from territory every iteration in case things have changed
      local convex_hull = territory:get_convex_hull()
      local num_convex_hull_points = #convex_hull

      if num_convex_hull_points > 0 then
         local perimeter_point = self:_get_unused_perimeter_point(convex_hull)
         local town_center = territory:get_centroid()

         local success = self:_try_one_perimeter_point(perimeter_point, town_center, territory)
         if success or self._sv.destroyed then
            stop_timer(perf_timer, 'found a location', self._sv.num_perimeter_points_searched)
            break
         end
      end

      if self._sv.num_perimeter_points_searched >= num_convex_hull_points then
         self._log:warning('all convex hull points searched. aborting camp placement.')
         stop_timer(perf_timer, 'aborting. all convex hull points searched.', self._sv.num_perimeter_points_searched)
         if self._sv.callback then
            self:_invoke_callback('abort')
         end
         self:destroy()
         break
      end

      if self._sv.num_perimeter_points_searched % num_convex_hull_points == 0 then
         -- clear the closed set every cycle around the perimeter in case the pathable geometry has changed
         self._closed = {}
         stop_timer(perf_timer, 'could not find location yet. will try again later', self._sv.num_perimeter_points_searched)
         self:_try_later()
         return
      end
   end

   self:destroy()
end

local max_fn = function(a, b)
   return a > b
end

-- perimeter point and town_center are Point2s
function ChooseWaterLocationOutsideTown:_try_one_perimeter_point(perimeter_point, town_center, territory)
   -- Start the search for solid ground at max_y, so we don't end up finding a tunnel.
   -- Determining the starting point is infrquent so performance should not be an issue.
   town_center = radiant.terrain.get_point_on_terrain(Point3(town_center.x, self._max_y, town_center.y))

   local open = _radiant.sim.create_location_priority_queue()
   open:reserve(1000)

   local function visit_point(location)
      -- faster to do this string processing in lua
      local x, y, z = location:get_xyz()
      local key = string.format('%d,%d,%d', x, y, z)

      if not self._closed[key] then
         self._closed[key] = true

         -- The distance used here is the distance from the centroid of town so that our
         -- depth first traversal occurs away from the town center
         local distance_squared = _radiant.csg.get_xz_distance_squared(location, town_center)
         open:push(location, distance_squared)
      end
   end

   -- Start searching from a point on the edge of town
   local starting_point = radiant.terrain.get_point_on_terrain(Point3(perimeter_point.x, self._max_y, perimeter_point.y))
   visit_point(starting_point, true)

   -- Search outwards from the perimeter point until we find a good location
   local max_nodes_per_loop = 20
   local max_locations_per_loop = 4
   local nodes_processed = 0
   local locations_tried = 0
   local search_point = Point3()

   while not open:empty() do
      local location = open:pop()
      local camp_region = self:_get_camp_region(location)

      if not self:_is_camp_too_close(location, camp_region, territory) then
         if self:_try_location(location, camp_region) then
            return true
         end
         locations_tried = locations_tried + 1
      end

      local x, y, z = location:get_xyz()

      -- we interpret max_range loosely (within 1 of the specified range) so that we don't have to place
      -- this check in the inner loop
      if _radiant.csg.get_xz_distance_squared(starting_point, location) <= self._max_range_squared then
         for dy = -1, 1 do
            for dx = -1, 1 do
               for dz = -1, 1 do
                  -- faster than search_point = location + Point3(dx, dy, dz) because we don't garbage collect
                  -- another object and we only have one c++ call
                  search_point:set(x + dx, y + dy, z + dz)

                  -- If we're looking for a pathable camp location, we would ideally call
                  -- _radiant.sim.is_valid_move() on the adjacent points. This is a bit more involved
                  -- as we need to specify who the path should be valid (in addition to requiring a bit more
                  -- computation). Using standability seems good enough for now.
                  if _physics:is_standable(search_point) then
                     visit_point(search_point)
                  end
               end
            end
         end
      end

      nodes_processed = nodes_processed + 1

      -- yield every so often...
      if nodes_processed >= max_nodes_per_loop or locations_tried >= max_locations_per_loop then
         nodes_processed = 0
         locations_tried = 0
         coroutine.yield()
         if self._sv.destroyed then
            return false
         end
      end
   end

   return false
end

-- Note that the number of points in the hull may be changing over time,
-- so this index rotation should be considered to be approximate
function ChooseWaterLocationOutsideTown:_get_unused_perimeter_point(convex_hull)
   local num_points = #convex_hull
   assert(num_points > 0)
   local index = self._sv.last_hull_index

   if not index then
      index = rng:get_int(1, num_points)
   else
      index = index + 1
      if index > num_points then
         index = 1
      end
   end

   self._sv.last_hull_index = index

   local perimeter_point = convex_hull[index]
   return perimeter_point
end

function ChooseWaterLocationOutsideTown:_finalize_location(location, camp_region)
   self:_destroy_find_location_timer()

   self._sv.found_location = true
   self.__saved_variables:mark_changed()
   if self._sv.callback then
      self:_invoke_callback('set_location', location, camp_region)
      self._sv.callback = nil
   end
end

function ChooseWaterLocationOutsideTown:_destroy_find_location_timer()
   if self._find_location_timer then
      self._find_location_timer:destroy()
      self._find_location_timer = nil
   end
end

function ChooseWaterLocationOutsideTown:_destroy_job()
   if self._job then
      -- destroy not supported yet
      self._job = nil
   end
end

function ChooseWaterLocationOutsideTown:_try_later()
   self:_destroy_job()
   self:_destroy_find_location_timer()
   self._find_location_timer = radiant.set_realtime_timer("ChooseWaterLocationOutsideTown try_later", 10000, function()
         self:_create_search_thread()
      end)
end

function ChooseWaterLocationOutsideTown:_invoke_callback(...)
   if type(self._sv.callback) == 'function' then
      return self._sv.callback(...)
   else
      return radiant.invoke(self._sv.callback, ...)
   end
end

return ChooseWaterLocationOutsideTown