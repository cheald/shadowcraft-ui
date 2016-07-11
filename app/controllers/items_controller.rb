require 'csv'

class ItemsController < ApplicationController
  include WowArmory::Constants

  respond_to :json, :only => [:create]
  VALID_SLOTS = (1..28).to_a - [18, 19, 20, 24, 26, 27]
  VALID_CLASSES = %w"rogue"

  def index
    @klass = params[:class]
    @klass = nil unless VALID_CLASSES.include?(@klass)
    @klass ||= "rogue"

    @filename = "items-#{@klass}.js"
    case @klass
    when "rogue"
      index_rogue
    end
  end

  # Rebuild the item database based on the given character hash
  def rebuild
    char = Character.where(:id => params[:c]).first
    player_class = "unknown"
    unless char.nil? or char.properties['player_class'].nil?
      player_class = char.properties['player_class']
    end
    filename = "items-#{player_class.downcase}.js"
    first_item = Item.desc(:updated_at).first
    anchor = flash[:reload].blank? ? nil : "reload"
    f = File.join(Rails.root, "public", filename)
    # If file not exists or an Item from Database is newer then the file creation time
    if !File.exists?(f) or File.mtime(f) < first_item.updated_at
      # initiate indexing
      index
      # render everything to a file, whatever here happens?
      render_to_string :action => "index.js"
    end
    # finally go back to the character page
    redirect_to params[:c].blank? ? :back : character_path(character_options(char).merge(:anchor => anchor))
  end

  private

  # Get all items, gems, etc. and filter out not needed ones for rogues
  def index_rogue
    @alt_items = []
    VALID_SLOTS.each do |i|
      @alt_items += Item.where(:"properties.equip_location" => i, :item_level.gte => 530).desc(:item_level).all
    end

    # This is really haxy, but it's flexible.
    bad_keys = %w"intellect spell_power spirit parry dodge bonus_armor"
    bad_classes = %w"Plate Mail"
    @alt_items.reject! {|item| !(item.properties['stats'].keys & bad_keys).empty? }
    # don't reject trinkets with empty stats
    @alt_items.reject! {|item| item.properties['stats'].empty? and item.properties['equip_location'] != 12}
    # Reject plate and mail items altogether
    @alt_items.reject! {|item| bad_classes.include? item.properties['armor_class'] }
    # only allow cloth items in back slots (16 is the slot in API data for backs)
    @alt_items.reject! {|item| item.properties['armor_class'] == "Cloth" && item.properties['equip_location'] != 16 }
    # reject items which are upgraded versions but are not allowed
    @alt_items.reject! {|item| !item.properties['upgradable'] and [1,2,3,4,5,6].include? item.properties['upgrade_level'] }
    # reject blue items with an upgrade level >= 2
    @alt_items.reject! {|item| item.properties['quality'] == 3 and [2,3,4,5,6].include? item.properties['upgrade_level'] }

    # Get all gems, enchants, talents, and artifact relics
    @gems = Item.where(:is_gem => true, :item_level.gt => 87).all
    @gems.reject! {|g| !(g.properties['stats'].keys & bad_keys).empty? }
    @enchants = Enchant.all
    @talents = Talent.all
    @relics = Relic.all
    @artifacts = Artifact.all

    @item_bonuses = WowArmory::Item.item_bonuses
    @rand_prop_points = rand_prop_points
  end

  def rand_prop_points
    @@rand_prop_points ||= Hash.new.tap do |hash|
      CSV.foreach(File.join(Rails.root, 'lib', 'wow_armory', 'data', 'RandPropPoints.dbc.csv')) do |row|
        hash[row[0].to_i] = row
      end
    end
  end
end
