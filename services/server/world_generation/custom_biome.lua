local CustomBiome = class()

function CustomBiome:_generate_color_map()
   local palette = self._palettes[self._season]
   local minimap_palette = self._palettes.minimap
   local elevations = self:_get_terrain_elevations()
   local color_map = {
      water = minimap_palette and minimap_palette.water or '#1CBFFF',
      trees = minimap_palette and minimap_palette.trees or '#263C2C'
   }

   for _, elevation in ipairs(elevations) do
      local terrain_type, step = self:get_terrain_type_and_step(elevation)
      local terrain_code = self:_assemble_terrain_code(terrain_type, step)
      local color

      if terrain_type == 'plains' then
         color = step <= 1 and palette.dirt or palette.grass
      elseif terrain_type == 'foothills' then
         color = palette.grass_hills
      elseif terrain_type == 'mountains' then
         color = palette['rock_layer_' .. step]
      else
         error('unknown terrain type')
      end

      if minimap_palette and minimap_palette[terrain_code] then
         color = minimap_palette[terrain_code]
      end

      color_map[terrain_code] = color
   end

   self._color_map = color_map
end

return CustomBiome