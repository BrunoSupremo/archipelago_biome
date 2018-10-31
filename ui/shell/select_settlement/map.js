$.widget( "stonehearth.stonehearthMap", {
   options: {
      // callbacks
      hover: null,
      cellSize: 12,
      settlementRadius: 19,
      click: function(cellX, cellY) {
         console.log('Selected cell: ' + cellX + ', ' + cellY);
      }
   },

   oldPalette: {
      water:       '#1cbfff',
      plains_1:    '#927e59',
      plains_2:    '#948a48',
      foothills_1: '#888a4a',
      foothills_2: '#888a4a',
      foothills_3: '#888a4a',
      mountains_1: '#807664',
      mountains_2: '#888071',
      mountains_3: '#948d7f',
      mountains_4: '#aaa59b',
      mountains_5: '#c5c0b5',
      mountains_6: '#d9d5cb',
      mountains_7: '#f2eee3',
      mountains_8: '#f2eee3'
   },

   typeHeights: {
      water:     0,
      plains:    1,
      foothills: 2,
      mountains: 3,
   },

   forestMargin: {
      0: null,
      1: 4,
      2: 3,
      3: 2,
      4: 1,
   },

   setMap: function(mapGrid, mapInfo) {
      var self = this;

      self.options.mapGrid = mapGrid;
      self.options.mapInfo = mapInfo;
      self._drawMap(self.mapContext);
   },

   getMap: function() {
      var self = this;
      return self.options.mapGrid;
   },

   suspend: function() {
      var self = this;

      self._suspended = true;
      self._enableCursor();
   },

   resume: function() {
      var self = this;

      self._suspended = false;
      self._disableCursor();
   },

   suspended: function() {
      var self = this;

      return self._suspended;
   },

   clearCrosshairs: function() {
      var self = this;

      self._clearCrosshairs(self.overlayContext);
   },

   _create: function() {
      var self = this;

      self._suspended = false;
      map_icons = new Image();
      map_icons.src = '/archipelago_biome/ui/shell/select_settlement/images/map_icons.png';
      map_icons.onload = function(){
         self._buildMap();
      }
   },

   _buildMap: function() {
      var self = this;

      self.element.addClass('stonehearthMap');
      var grid = self.options.mapGrid;
      var canvas = $('<canvas>');
      var overlay = $('<canvas>');
      var container = $('<div>').css('position', 'relative');

      self.mapWidth = grid[0].length * self.options.cellSize;
      self.mapHeight = grid.length * self.options.cellSize;

      canvas
         .addClass('mapCanvas')
         .attr('width', self.mapWidth)
         .attr('height', self.mapHeight);

      overlay
         .addClass('mapCanvas')
         .addClass('noCursor')
         .attr('id', 'overlay')
         .attr('width', self.mapWidth)
         .attr('height', self.mapHeight)

         .click(function(e) {
            self._onMouseClick(self, e);
         })

         .mousemove(self, function(e) {
            self._onMouseMove(self, e);
         });

      self.mapContext = canvas[0].getContext('2d');
      self.overlayContext = overlay[0].getContext('2d');

      self._drawMap(self.mapContext);

      container.append(canvas);
      container.append(overlay);

      self.element.append(container);
   },

   _onMouseClick: function(view, e) {
      var self = view;

      if (self._suspended) {
         return;
      }

      var cellSize = self.options.cellSize;
      var cellX = Math.floor(e.offsetX / cellSize);
      var cellY = Math.floor(e.offsetY / cellSize);

      self.options.click(cellX, cellY);
      radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:ui:start_menu:sub_menu' });
   },

   _onMouseMove: function(view, e) {
      var self = view;

      if (self._suspended) {
         return;
      }

      var cellSize = self.options.cellSize;
      var cellX = Math.floor(e.offsetX / cellSize);
      var cellY = Math.floor(e.offsetY / cellSize);

      if (cellX != self.mouseCellX || cellY != self.mouseCellY) {
         self.mouseCellX = cellX;
         self.mouseCellY = cellY;

         self._drawCrosshairs(self.overlayContext, cellX, cellY);

         self.options.hover(cellX, cellY);
         radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:ui:action_hover'} );
      }
   },

   _drawCrosshairs: function(context, cellX, cellY) {
      var self = this;
      var cellSize = self.options.cellSize;

      self._clearCrosshairs(context);

      context.globalAlpha = 0.4;
      context.fillStyle = '#000000';
      context.fillRect(0, 0, self.mapWidth, self.mapHeight);

      var lineX = cellX*cellSize + cellSize/2
      var lineY = cellY*cellSize + cellSize/2

      // Clear the bounding box
      var boundingBoxRadius = cellSize * self.options.settlementRadius;
      context.clearRect(lineX - boundingBoxRadius, lineY - boundingBoxRadius,
            boundingBoxRadius * 2, boundingBoxRadius * 2
         );

      context.globalAlpha = 0.8;
      context.fillStyle = '#ffc000';
      context.fillRect(
         cellX * cellSize, cellY * cellSize,
         cellSize, cellSize
      );

      context.lineWidth = 1.0;
      context.setLineDash([2]);

      self._drawLine(
         context,
         0, lineY,
         lineX - cellSize/2, lineY
      );

      self._drawLine(
         context,
         lineX + cellSize/2, lineY,
         self.mapWidth, lineY
      );

      self._drawLine(
         context,
         lineX, 0,
         lineX, lineY - cellSize/2
      );

      self._drawLine(
         context,
         lineX, lineY + cellSize/2,
         lineX, self.mapHeight
      );

      context.globalAlpha = 1.0;
   },

   _clearCrosshairs: function(context) {
      var self = this;
      context.clearRect(0, 0, self.mapWidth, self.mapHeight);
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
   },

   _drawCell: function(context, cellX, cellY, cell) {
      var self = this;
      var cellSize = self.options.cellSize;
      var x = cellX * cellSize;
      var y = cellY * cellSize;

      // draw elevation
      var terrain_code = cell.terrain_code;
      var color = self.options.mapInfo.color_map[terrain_code];

      context.fillStyle = color ? color : '#000000';
      context.fillRect(
         x, y,
         cellSize, cellSize
      );

      //var cellHeight = self._heightAt(cellX, cellY)
      context.lineWidth = 0.4;

      // draw edges for elevation changes
      if(self._isHigher(cellX, cellY - 1, terrain_code)) {
         // north, line above me
         self._drawLine(
            context,
            x, y,
            x + cellSize, y
         );

         //xxx, shading above me
         context.globalAlpha = 0.3;
         context.fillStyle = '#000000';
         context.fillRect(
            x, y,
            cellSize, cellSize * -0.4
         );
         context.globalAlpha = 1.0;
      }
      if(self._isHigher(cellX, cellY + 1,terrain_code)) {
         // south, line below me
         self._drawLine(
            context,
            x, y + cellSize,
            x + cellSize, y + cellSize
         );
      }
      if(self._isHigher(cellX - 1, cellY,terrain_code)) {
         // east, line on my left
         self._drawLine(
            context,
            x, y,
            x, y + cellSize
         );
      }
      if(self._isHigher(cellX + 1, cellY,terrain_code)) {
         // west, line on my right
         self._drawLine(
            context,
            x + cellSize, y,
            x + cellSize, y + cellSize
         );
      }

      // overlay forest
      var forest_density = self._forestAt(cellX, cellY)

      if (forest_density > 0) {
         var margin = self.forestMargin[forest_density];
         context.fillStyle = self.options.mapInfo.color_map.trees;
         //context.fillStyle = '#223025';   // darker color
         context.globalAlpha = 0.6;

         context.fillRect(
            x + margin, y + margin,
            cellSize - margin*2, cellSize - margin*2
         );
         context.globalAlpha = 1.0;
      }
   },

   _isHigher: function(x, y, terrain_code){
      var self = this;
      if (!self._inBounds(x, y)) {
         return false;
      }
      var terrain_code_xy = self.options.mapGrid[y][x].terrain_code;
      if (terrain_code_xy == 'water') {
         return false;
      }
      var type_and_step = terrain_code.split("_");
      var type_and_step_xy = terrain_code_xy.split("_");
      var height = self.typeHeights[type_and_step[0]];
      var height_xy = self.typeHeights[type_and_step_xy[0]];
      if (height_xy > height) {
         return true;
      }
      var step = parseInt(type_and_step[1]);
      var step_xy = parseInt(type_and_step_xy[1]);
      if (height_xy == height && step_xy > step) {
         return true;
      }
      return false;
   },

   _drawLine: function(context, x1, y1, x2, y2) {
      context.beginPath();
      context.moveTo(x1, y1);
      context.lineTo(x2, y2);
      context.stroke();
   },

   _drawRect: function(context, x1, y1, width, height) {
      context.rect(x1, y1, width, height);
      context.stroke();
   },

   _enableCursor: function() {
      $('#overlay').removeClass('noCursor');
      $('#overlay').addClass('arrowCursor');
   },

   _disableCursor: function() {
      $('#overlay').removeClass('arrowCursor');
      $('#overlay').addClass('noCursor');
   },

   _terrainAt: function(cellX, cellY) {
      var self = this;

      if (!self._inBounds(cellX, cellY)) {
         return '';
      }
      return self.options.mapGrid[cellY][cellX].terrain_code;
   },

   _forestAt: function(cellX, cellY) {
      var self = this;

      if (!self._inBounds(cellX, cellY)) {
         return -1;
      }

      return self.options.mapGrid[cellY][cellX].forest_density;
   },

   _inBounds: function(cellX, cellY) {
      var self = this;

      if (cellX < 0 || cellY < 0) {
         return false;
      }

      if (cellX >= self.options.mapGrid[0].length || cellY >= self.options.mapGrid.length) {
         return false;
      }

      return true;
   },
});
