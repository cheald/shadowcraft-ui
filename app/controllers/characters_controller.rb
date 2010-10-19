class CharactersController < ApplicationController 
  def new
    @characters = Character.asc(:name).asc(:realm).paginate :page => params[:page], :per_page => 30
    @character ||= Character.new
    render :action => "new"
  end
  
  def create
    begin
      @character = Character.where(params[:character]).first
      @character ||= Character.new(params[:character])    
      unless @character.name.blank? or @character.realm.blank? or @character.region.blank?
        @character.update_from_armory!
      end
    rescue Character::NotFoundException
      @character.errors.add :base, "Character not found, or the Armory is offline"
      return new
    end
    if @character.save
      flash[:message] = "Character imported!"
      redirect_to rebuild_items_path(:c => @character._id)
    else
      return new
    end
  end
  
  def show
    @character = Character.find(params[:id])
    raise Mongoid::Errors::DocumentNotFound if @character.nil?
    @page_title = @character.fullname
    @loadout = @character.loadouts.first || Loadout.new(:character => @character)
  end  
  
  def refresh
    @character = Character.find(params[:id])
    @character.update_from_armory!(true)
    redirect_to rebuild_items_path(:c => @character._id)
  end
end
