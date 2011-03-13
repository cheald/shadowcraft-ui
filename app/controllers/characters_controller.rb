class CharactersController < ApplicationController
  def new
    @characters = Character.asc(:name).asc(:realm).paginate :page => params[:page], :per_page => 30
    @character ||= Character.new
    render :action => "new"
  end

  def create
    begin
      @character = Character.get!(params[:character][:region], params[:character][:realm], params[:character][:name])
      @character ||= Character.new(params[:character])
      unless @character.name.blank? or @character.realm.blank? or @character.region.blank?
        @character.update_from_armory! #(true)
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
    @character = Character.get!(params[:region], params[:realm], params[:name])
    if @character.nil?
      params[:character] = {
        :realm => params[:realm],
        :region => params[:region],
        :name => params[:name]
      }
      create
      return
    end
    @page_title = @character.fullname
    # @loadout = @character.loadout || Loadout.new(:character => @character)
  end

  def refresh
    @character = Character.get!(params[:region], params[:realm], params[:name])
    flash[:_reset] = true
    @character.update_from_armory!(true)
    redirect_to rebuild_items_path(:c => @character._id)
  end
end
