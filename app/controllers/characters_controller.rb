class CharactersController < ApplicationController

  # Generate a new Character
  def new
    @character ||= Character.new :region => "US"
    render :action => "new"
  end

  # Persist a new Character
  # Is this used anyway?
  def persist
    if request.post?
      sha = Digest::SHA1.hexdigest(params[:data].to_json)
      Mongoid.master.collection("lookups").update({:sha => sha}, {:doc => params[:data]})
      render :json => {"h" => sha}
    elsif request.get?
      r = if doc = Mongoid.master.collection("lookups").find_one(:sha => sha)
        doc["doc"]
      else
        nil
      end
      render :json => {:doc => p}
    end
  end

  # Creates a new Character with params
  def create
    @character = Character.get!(params[:character])
    @character ||= Character.new(params[:character])

    # If character save was successful, redirect to rebuild_items_path
    if @character.save
      redirect_to rebuild_items_path(:c => @character._id)
    else
      return new
    end
  end

  # Shows a Character
  # Called on Route /:region/:realm/:name
  def show
    @character = Character.get!(params[:region], params[:realm], params[:name])
    raise Mongoid::Errors::DocumentNotFound.new(Character, {}) if @character.nil?

    begin
      @character.as_json
      @character.properties['race'].downcase
    rescue
      @character.update_from_armory!(true) unless @character.nil?
    end

    if @character.properties["player_class"] == "unknown"
      return new
    end

    if @character.nil? or !@character.valid?
      params[:character] = {
        :realm => params[:realm],
        :region => params[:region],
        :name => params[:name]
      }
      create
      return
    end
    @page_title = @character.fullname
  end

  # Refresh a Character, so that armory data gets reloaded from blizzards armory
  # Called on Route /:region/:realm/:name/refresh
  def refresh
    # Call the Character model get method with the given params from the route
    @character = Character.get!(params[:region], params[:realm], params[:name])
    @character ||= Character.new(params[:region], params[:realm], params[:name])
    # force the page to reload the new data from the update
    flash[:reload] = Time.now.to_i
    # Initiate an armory update
    @character.update_from_armory!(true)
    # Send a save request
    if @character.save
      # Call a redirect to rebuild the item data for client usage
      redirect_to rebuild_items_path(:c => @character._id)
    else
      return new
    end
  end
end
