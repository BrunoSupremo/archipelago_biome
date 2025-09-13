$(document).ready(function() {
	$(top).on('archipelago_biome:fishing_album', function (_, e) {
		if (!App.stonehearth.Fishing_AlbumView) {
			App.stonehearth.Fishing_AlbumView = App.gameView.addView(App.Fishing_AlbumView);
		}
	});
});

App.Fishing_AlbumView = App.View.extend({
	templateName: 'fishing_album',
	modal: false,
	closeOnEsc: true,

	didInsertElement: function() {
		var self = this;

		radiant.call('archipelago_biome:get_town_fished')
		.done(function(response) {
			let fish_list = []
			for (const fish_uri in response.fish_list) {
				let catalog = App.catalog.getCatalogData(fish_uri);
				if(catalog){
					fish_list.push({
						name: i18n.t(catalog.display_name),
						quantity: ""+response.fish_list[fish_uri].quantity,
						max_limit: response.fish_list[fish_uri].max_limit,
						image: catalog.icon
					})
				}
			}
			fish_list.sort(function(a, b){
				const diff = b.quantity - a.quantity
				if(diff == 0){
					const a_max = a.max_limit || 0;
					const b_max = b.max_limit || 0;
					const diff2 = b_max - a_max;
					if(diff2 == 0){
						if (a.name < b.name) {
							return -1;
						}
						if (a.name > b.name) {
							return 1;
						}
						return 0;
					}else{
						return diff2;
					}
				}else{
					return diff;
				}
			});
			self.set('fish_list', fish_list);
		});

		self.$().draggable();
	},

	destroy: function() {
		App.stonehearth.Fishing_AlbumView = null;

		this._super();
	}
});