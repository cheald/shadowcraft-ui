class CharactersController < ApplicationController 
  def new
    @characters = Character.all
    @character ||= Character.new
    render :action => "new"
  end
  
  def create
    begin
      @character = Character.new(params[:character])    
      @character.update_from_armory!
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
    @character = Character.criteria.id(params[:id]).first
    @page_title = @character.fullname
    @loadout = @character.loadouts.first || Loadout.new(:character => @character)
  end  
end
