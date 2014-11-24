class ItemsController < ApplicationController
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

  # Create a new item
  # Is it used anywhere?
  def create
    item = Item.find_or_create_by(:remote_id => params[:item][:remote_id])

    respond_with(item) do |format|
      format.html {
        flash[:notice] = "#{item.properties["name"]} added to the database"
        redirect_to :back
      }
    end
  end

  # Rebuild the item database based on the given character hash
  def rebuild
    char = Character.criteria.id(params[:c]).first
    player_class = "unknown"
    unless char.nil? or char.properties['player_class'].nil?
      player_class = char.properties['player_class']
    end
    filename = "items-#{player_class.downcase}.js"
    first_item = Item.desc(:created_at).first
    anchor = flash[:reload].blank? ? nil : "reload"
    f = File.join(Rails.root, "public", filename)
    # If file not exists or an Item from Database is newer then the file creation time
    if !File.exists?(f) or File.mtime(f) < first_item.created_at
      # initiate indexing
      index
      # render everything to a file, whatever here happens?
      render_to_string :action => "index.js"
    end
    # finally go back to the character page
    redirect_to params[:c].blank? ? :back : character_path(character_options(char).merge(:anchor => anchor))
  end

  private

  SOCKET_MAP = {
      1 => 'Meta',
      2 => 'Red',
      8 => 'Blue',
      4 => 'Yellow',
      14 => 'Prismatic',
      16 => 'Hydraulic',
      32 => 'Cogwheel'
  }

  STAT_LOOKUP = {
      49 => :mastery,
      38 => :attack_power,
      5 => :intellect,
      44 => :armor_penetration,
      33 => :hit_avoidance,
      6 => :spirit,
      12 => :defense,
      45 => :power,
      34 => :critical_strike_avoidance,
      1 => :health,
      7 => :stamina,
      3 => :agility,
      2 => :mana,
      13 => :dodge,
      46 => :health_every_5_seconds,
      57 => :pvp_power,
      35 => :pvp_resilience,
      41 => :damage_done,
      14 => :parry,
      36 => :haste,
      47 => :penetration,
      31 => :hit,
      42 => :healing_done,
      4 => :strength,
      37 => :expertise,
      15 => :shield_block,
      48 => :block_value,
      32 => :crit,
      43 => :mana_every_5_seconds,
      71 => :agility,
      72 => :agility,
      73 => :agility,
      40 => :versatility,
      59 => :multistrike,
      58 => :amplify,
      50 => :bonus_armor,
      63 => :avoidance,
      67 => :versatility,
      61 => :speed,
      62 => :leech,
      64 => :indestructible,
  }

  # Get all items, gems, etc. and filter out not needed ones for rogues
  def index_rogue
    @alt_items = []
    VALID_SLOTS.each do |i|
      @alt_items += Item.where(:equip_location => i, :item_level.gte => 530).desc(:item_level).all
    end

    # This is really haxy, but it's flexible.
    bad_keys = %w"intellect spell_power spirit parry dodge bonus_armor"
    bad_classes = %w"Plate Mail"
    @alt_items.reject! {|item| !(item.stats.keys & bad_keys).empty? }
    @alt_items.reject! {|item| item.stats.empty? and (item.equip_location != 12 and item.remote_id != 88149) } # Don't reject trinkets with empty stats
    @alt_items.reject! {|item| bad_classes.include? item.properties['armor_class'] }
    @alt_items.reject! {|item| item.properties['armor_class'] == "Cloth" && item.equip_location != 16 }
    @alt_items.reject! {|item| item.properties['name'].match(/DONTUSE/) }
    @alt_items.reject! {|item| !item.properties['upgradable'] and [1,2,3,4,5,6].include? item.properties['upgrade_level'] } # reject items which are upgrades but are not allowed
    @alt_items.reject! {|item| item.properties['quality'] == 3 and [2,3,4,5,6].include? item.properties['upgrade_level'] } # reject blue items with upgrade_level >= 2

    gems = Item.where(:has_stats => true, :is_gem => true, :item_level.gt => 87).all
    @gems = gems.select {|g| !g.properties["name"].match(/Stormjewel/) }
    @gems.reject! {|g| !(g.stats.keys & bad_keys).empty? }
    @enchants = Enchant.all
    h = Hash.from_xml open(File.join(Rails.root, "app", "xml", "talents_wod.xml")).read
    @talents_wod = h["page"]["talents"]
    @glyphs = Glyph.asc(:name).all

    item_bonuses = {}
    FasterCSV.foreach(File.join(Rails.root, 'app', 'xml', 'WoD_ItemBonusIDs.csv'), { :col_sep => ';'}) do |row|
      unless item_bonuses.has_key? row[1].to_i
        item_bonuses[row[1].to_i] = []
      end
      entry = {
        :type => row[2].to_i,
        :val1 => row[3].to_i,
        :val2 => row[4].to_i
      }
      if entry[:type] == 5
        entry[:val1] = item_name_description[entry[:val1]]
      end
      if entry[:type] == 2
        if STAT_LOOKUP[entry[:val1]]
          entry[:val1] = STAT_LOOKUP[entry[:val1]]
        end
      end
      if entry[:type] == 6
        entry[:val2] = SOCKET_MAP[entry[:val2].to_i]
      end
      item_bonuses[row[1].to_i].push entry
    end
    @item_bonuses = item_bonuses
    @rand_prop_points = rand_prop_points
  end

  def item_name_description
    @@item_name_description ||= Hash.new.tap do |hash|
      FasterCSV.foreach(File.join(Rails.root, 'app', 'xml', 'WoD_ItemNameDescription.csv'), { :col_sep => ';'}) do |row|
        hash[row[0].to_i] = row[1]
      end
    end
  end

  def rand_prop_points
    @@rand_prop_points ||= Hash.new.tap do |hash|
      FasterCSV.foreach(File.join(Rails.root, 'app', 'xml', 'WoD_RandPropPoints.csv'), { :col_sep => ';'}) do |row|
        hash[row[0].to_i] = row
      end
    end
  end
end
