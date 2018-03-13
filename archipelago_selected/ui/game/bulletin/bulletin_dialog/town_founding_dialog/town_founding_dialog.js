App.StonehearthTownFoundingEncounterBulletinDialog = App.StonehearthBaseBulletinDialog.extend({
   templateName: 'townFoundingBulletinDialog',

   _updateChoices: function () {
      var self = this;
      self.set(
        'bannerChoices', 
        radiant.map_to_array(
            self.get('model.data.choices'), 
            function (choice_id, choice_data) {
                 choice_data.choice_id = choice_id;
                 return choice_data;
            }
        ).sort(function(l, r){
                return l['sort_order'] - r['sort_order'];
                }
              )
       );

      Ember.run.scheduleOnce('afterRender', self, function () {
         if (self.$()) {
            self.$('.bannersList .bannerChoice:first-child').click();  // Select the first one by default.
         }
      });
   }.observes('model.data.choices'),

   didInsertElement: function() {
      var self = this;
      self._super();

      // Generate the initial town name.
      radiant.call('archipelago_biome:generate_town_name')
         .done(function (o) {
            self.$('#name').val(o.result);
            self.$('#name').focus();
            self.set('townName', o.result);
         });

      // Hook up town name reroll button.
      self.$('.reroll').click(function () {
         radiant.call('archipelago_biome:generate_town_name')
            .done(function (o) {
               radiant.call('radiant:play_sound', { 'track': 'stonehearth:sounds:ui:start_menu:reroll' });
               self.$('#name').val(o.result);
               self.set('townName', o.result);
            })
            .fail(function () {
               radiant.call('radiant:play_sound', { 'track': 'stonehearth:sounds:banner_bounce' });
            });
      });

      // React to town name textbox changing.
      self.$('#name').bind('keyup change', function () {
         var townName = App.stonehearth.validator.enforceStringLength(self.$('#name'), 28);
         self.set('townName', townName);
      });

      // React to banner selection.
      self.$('.bannersList').on('click', '.bannerChoice', function () {
         radiant.call('radiant:play_sound', { 'track': 'stonehearth:sounds:ui:start_menu:focus' });
         self.$('.bannerChoice').removeClass('selected');
         $(this).addClass('selected');
         self.set('selectedChoiceId', $(this).attr('data-choice-id'));
      });

      // React to the final button click.
      self.dialog.on('click', '#completeButton', function () {
         var bulletin = self.get('model');
         var instance = bulletin.callback_instance;
         var method = bulletin.data['on_selection_finished'];
         radiant.call_obj(instance, method, self.get('townName'), self.get('selectedChoiceId'))
            .done(function () {
               App.stonehearthClient.settlementName(self.get('townName'));
            })
      });
   },

   isSelectionMade: function () {
      var self = this;
      return Boolean(self.get('townName') && self.get('townName').trim()) && Boolean(self.get('selectedChoiceId'));
   }.property('townName', 'selectedChoiceId'),
});
