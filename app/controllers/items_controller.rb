class ItemsController < ApplicationController
  respond_to :json, :only => [:create]
  VALID_SLOTS = (1..28).to_a - [18, 19, 20, 24, 26, 27]
  
  def index
    @alt_items = []
    VALID_SLOTS.each do |i|
      @alt_items += Item.where(:equip_location => i, :item_level.gte => 200).desc(:item_level).all
    end
    gems = Item.where(:has_stats => true, "properties.classId" => "3", :item_level.gt => 70).all
    @gems = Hash[*gems.reject {|g| g.properties["name"].match(/Stormjewel/)}.map {|i| [i.remote_id, i] }.flatten]
    @enchants = Enchant.all
    h = Hash.from_xml open(File.join(Rails.root, "app", "xml", "talent-tree.xml")).read
    @talents = h["page"]["talentTrees"]["tree"].sort {|a, b| a["order"].to_i <=> b["order"].to_i }  
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
    Enchant.update!
    index
    render_to_string :action => "index.js"
    redirect_to Character.criteria.id(params[:c]).first
  end
end
