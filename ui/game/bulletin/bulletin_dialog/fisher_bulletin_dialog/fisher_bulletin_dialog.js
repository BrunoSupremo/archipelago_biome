App.ArchipelagoFisherBulletinDialog = App.StonehearthBaseBulletinDialog.extend({
	templateName: 'fisherBulletinDialog',
	closeOnEsc: true,

	actions:{
		view_album: function() {
			$(top).trigger('archipelago_biome:fishing_album');
			this._autoDestroy();
		}
	}
});