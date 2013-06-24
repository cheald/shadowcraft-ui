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

  def create
    item = Item.find_or_create_by(:remote_id => params[:item][:remote_id])

    respond_with(item) do |format|
      format.html {
        flash[:notice] = "#{item.properties["name"]} added to the database"
        redirect_to :back
      }
    end
  end

  def rebuild
    char = Character.criteria.id(params[:c]).first
    filename = "items-#{char.properties['player_class'].downcase}.js"
    first_item = Item.desc(:created_at).first
    anchor = flash[:reload].blank? ? nil : "reload"
    f = File.join(Rails.root, "public", filename)
    if !File.exists?(f) or File.mtime(f) < first_item.created_at
      index
      render_to_string :action => "index.js"
    end
    redirect_to params[:c].blank? ? :back : character_path(character_options(char).merge(:anchor => anchor))
  end

  private

  def index_rogue
    @alt_items = []
    VALID_SLOTS.each do |i|
      @alt_items += Item.where(:equip_location => i, :item_level.gte => 430).desc(:item_level).all
    end

    # This is really haxy, but it's flexible.
    bad_keys = %w"intellect spell_power spirit parry dodge"
    bad_classes = %w"Plate Mail"
    @alt_items.reject! {|item| !(item.stats.keys & bad_keys).empty? }
    @alt_items.reject! {|item| item.stats.empty? and item.equip_location != 12 } # Don't reject trinkets with empty stats
    @alt_items.reject! {|item| bad_classes.include? item.properties['armor_class'] }
    @alt_items.reject! {|item| item.properties['armor_class'] == "Cloth" && item.equip_location != 16 }
    @alt_items.reject! {|item| item.properties['name'].match(/DONTUSE/) }
    @alt_items.reject! {|item| !item.properties['upgradable'] and [1,2,3,4].include? item.properties['upgrade_level'] } # reject items which are upgrades but are not allowed
    @alt_items.reject! {|item| item.properties['quality'] == 3 and [2,3,4].include? item.properties['upgrade_level'] } # reject blue items with upgrade_level >= 2

    gems = Item.where(:has_stats => true, :is_gem => true, :item_level.gt => 87).all
    @gems = gems.select {|g| !g.properties["name"].match(/Stormjewel/) }
    @gems.reject! {|g| !(g.stats.keys & bad_keys).empty? }
    @enchants = Enchant.all
    h = Hash.from_xml open(File.join(Rails.root, "app", "xml", "talents_mop.xml")).read
    @talents = h["page"]["talents"]
    h = Hash.from_xml open(File.join(Rails.root, "app", "xml", "talents_mop_52.xml")).read
    @talents_52 = h["page"]["talents"]
    @glyphs = Glyph.asc(:name).all
  end
end
