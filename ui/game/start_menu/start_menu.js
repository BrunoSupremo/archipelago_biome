App.StonehearthStartMenuView.reopen({
	init: function() {
		var self = this;

		self.menuActions.create_fish = function() {
			self.createFish();
		}

		self._super();
	},

	createFish: function() {
		var self = this;

		App.setGameMode('zones');
		var tip = App.stonehearthClient.showTip('archipelago_biome:ui.game.menu.zone_menu.items.create_fish.tip_title',
			'archipelago_biome:ui.game.menu.zone_menu.items.create_fish.tip_description', { i18n: true });

		return App.stonehearthClient._callTool('createFish', function(){
			return radiant.call('archipelago_biome:choose_new_fish_location')
			.done(function(response) {
				radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:place_structure'} );
				radiant.call('stonehearth:select_entity', response.field);
				self.createFish();
			})
			.fail(function(response) {
				App.stonehearthClient.hideTip(tip);
			});
		});
	}
});