App.StonehearthCreateCampView = App.View.extend({
	templateName: 'createCamp',
	classNames: ['flex', 'fullScreen'],

	didInsertElement: function() {
		var self = this;

		this._super();
		if (!this.first) {
			this.first = true;

			radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:ui:start_menu:loading_screen_success'} );

			this._bounceBanner();
		}

		App.stonehearthClient.showTip(i18n.t('stonehearth:ui.game.create_camp.click_banner_tip'));

		this.$('#bannerClick').click(function() {
			self._placeBanner();
		});

		radiant.call('stonehearth:dm_pause_game');
	},

	_placeBanner: function () {
		radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:banner_grab'});
		App.stonehearthClient.showTip(i18n.t('stonehearth:ui.game.create_camp.select_camp_tip'));
		var self = this;
		this._hideBanner();

		radiant.call('stonehearth:choose_camp_location')
		.done(function(o) {
			App.stonehearthClient.hideTip();
			if (o.result) {
				radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:banner_plant'} );
				App.gameView.addView(App.StonehearthNameCampView, {
					position: {
						my : 'center bottom',
						at : 'left+' + App.stonehearthClient.mouseX + " " + 'top+' + (App.stonehearthClient.mouseY - 100),
						of : $(document),
						collision : 'fit'
					},
					townName : o.townName
				});

				self.destroy();
			}
		})
		.fail(function() {
			self._showBanner();
			radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:banner_bounce'} );
		});
	},

	_bounceBanner: function() {
		var self = this
		if (!this._bannerPlaced) {
			radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:banner_bounce'} )
			$('#banner').effect( 'bounce', {
				'distance' : 15,
				'times' : 1,
				'duration' : 300
			});

			setTimeout(function(){
				self._bounceBanner();
			},1000)
		}
	},

	_showBanner: function() {
		this._bannerPlaced = false
		$('#banner').animate({ 'bottom' : -22 }, 100);
		$('#bannerClick').show();
	},

	_hideBanner: function() {
		this._bannerPlaced = true
		this.$('#banner').animate({ 'bottom' : -300 }, 100);
		$('#bannerClick').hide();
	},

	_finish: function() {
		radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:ui:start_menu:paper_menu'} );
		radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:ui:action_click'} );
		var self = this;
		$('#createCamp').animate({ 'bottom' : -300 }, 150, function() {
			App.gameView._addViews(App.gameView.views.complete);
			self.destroy();
		})
	}

});

App.StonehearthNameCampView = App.View.extend({
	templateName: 'nameCamp',

	didInsertElement: function() {
		var self = this;
		this._super();

		radiant.call('archipelago_biome:generate_town_name')
		.done(function(o) {
			self.$('#name').val(o.result);
		});

		this.$('#name').focus();

		this.$('#name').keydown(function (e) {
			if (e.keyCode == 13 && !e.originalEvent.repeat) {
				$(this).blur();
				self.$('.ok').click();
			}
		});

		this.$('.ok').click(function() {
			radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:ui:start_menu:submenu_select'} );
			var townName = self.$('#name').val()
			App.stonehearthClient.settlementName(townName);
			radiant.call_obj('stonehearth.town', 'set_town_name_command', townName);
			radiant.call('stonehearth:dm_resume_game');
			radiant.call('radiant:get_config', 'mods.stonehearth.tutorial')
			.done(function(o) {
				var tutorial_config = o['mods.stonehearth.tutorial'];
				if ((tutorial_config && !tutorial_config.hide_intro_tutorial) || !tutorial_config) {
					radiant.call_obj('stonehearth.tutorial', 'start');
				}
			});
			App.gameView._addViews(App.gameView.views.complete);

			self.destroy();

		});

		this.$('.reroll').click(function() {
			radiant.call('archipelago_biome:generate_town_name')
			.done(function(o) {
				radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:ui:start_menu:reroll'} );
				self.$('#name').val(o.result);
			})
			.fail(function() {
				radiant.call('radiant:play_sound', {'track' : 'stonehearth:sounds:banner_bounce'} );
			});
		});

		this.$('#nameCamp').pulse();
	},

});