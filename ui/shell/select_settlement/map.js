$.widget( "stonehearth.stonehearthMap", $.stonehearth.stonehearthMap, {

	_create: function() {
		var self = this;

		self._in_archipelago = document.getElementById("selectSettlement").classList.contains("archipelago_biome:biome:archipelago");
		self._suspended = false;
		map_icons = new Image();
		if (self._in_archipelago){
			map_icons.src = '/archipelago_biome/ui/shell/select_settlement/images/map_icons.png';
			map_icons.onload = function(){
				self._buildMap();
			}
		}else{
			self._buildMap();
		}
	},

	_drawMap: function(context) {
		var self = this;

		var grid = self.options.mapGrid;
		for (var y = 0; y < grid.length; y++) {
			for (var x = 0; x < grid[y].length; x++) {
				self._drawCell(context, x, y, grid[y][x]);
				grid[y][x].has_water = grid[y][x].terrain_code == 'water';
			}
		}

		if (self._in_archipelago==false){
			return false;
		}
		var cellSize = self.options.cellSize;
		var area_size=15
		for (var y = 0; y < grid.length - area_size; y++) {
			for (var x = 0; x < grid[y].length - area_size; x++) {
				if(grid[y][x].has_water){
					var full_water_area = true;
					for (var yArea = y; yArea < y+area_size; yArea++) {
						for (var xArea = x; xArea < x+area_size; xArea++) {
							if(!grid[yArea][xArea].has_water){break;}
						}
						if(!grid[yArea][xArea].has_water){
							full_water_area=false;
							break;
						}
					}
					if(full_water_area){
						for (var yArea = y; yArea < y+area_size; yArea++) {
							for (var xArea = x; xArea < x+area_size; xArea++) {
								grid[yArea][xArea].has_water = false;
							}
						}
						context.globalAlpha = 0.5;
						context.drawImage(map_icons,Math.floor(Math.random() * 14)*100,0,100,100,(x+3)*cellSize,(y+3)*cellSize,100,100);
						context.globalAlpha = 1;
					}
				}
			}
		}
	}
});