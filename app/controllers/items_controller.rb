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
      render_to_string :action => "items.js"
    end
    redirect_to params[:c].blank? ? :back : character_path(character_options(char).merge(:anchor => anchor))
  end

  private

  def index_rogue
    @alt_items = []
    VALID_SLOTS.each do |i|
      @alt_items += Item.where(:equip_location => i, :item_level.gte => 300).desc(:item_level).all
    end

    # This is really haxy, but it's flexible.
    bad_keys = %w"intellect spell_power spirit parry_rating dodge_rating"
    bad_classes = %w"Plate Mail"
    @alt_items.reject! {|item| !(item.stats.keys & bad_keys).empty? }
    @alt_items.reject! {|item| item.stats.empty? }
    @alt_items.reject! {|item| bad_classes.include? item.properties['armor_class'] }
    @alt_items.reject! {|item| item.properties['armor_class'] == "Cloth" && item.equip_location != 16 }
    @alt_items.reject! {|item| item.properties['name'].match(/DONTUSE/) }

    gems = Item.where(:has_stats => true, :is_gem => true, :item_level.gt => 70).all
    @gems = gems.select {|g| !g.properties["name"].match(/Stormjewel/) }
    @enchants = Enchant.all
    h = Hash.from_xml open(File.join(Rails.root, "app", "xml", "talent-tree.xml")).read
    @talents = h["page"]["talentTrees"]["tree"].sort {|a, b| a["order"].to_i <=> b["order"].to_i }
    @glyphs = Glyph.asc(:name).all
  end
end
