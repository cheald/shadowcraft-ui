class CharactersController < ApplicationController

  # Generate a new Character
  def new
    @character ||= Character.new :region => "US"
    render :action => "new"
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

    if @character.properties.nil?
      return new
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

  # Retrieves a sha of a block of character json and stores it in to the database.
  # This is used as URLs now instead of generating a huge URL based on the data.
  def getsha
    # Create a sha1 hash of the json data of the character
    sha = Digest::SHA256.hexdigest(params[:data])

    # Store the sha and the matching data in mongo.
    history = History.find_or_initialize_by({:sha => sha})
    if history.new_record?
      history.json = JSON.parse(params[:data])
      history.save()
    end

    render :json => {"sha" => sha}
  end

  # Retrieves a character based on a sha hash created by getsha above.
  def getjson
    sha = params[:data]
    history = History.find_or_initialize_by({:sha => sha})
    if !history.new_record?
      render :json => history.json.to_json
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end
