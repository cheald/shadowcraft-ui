class CharactersController < ApplicationController
  def new
    @character ||= Character.new :region => "US"
    render :action => "new"
  end

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

  def create
    @character = Character.get!(params[:character])
    @character ||= Character.new(params[:character])

    @character.update_from_armory! if @character.valid?

    if @character.save
      flash[:message] = "Character imported!"
      redirect_to rebuild_items_path(:c => @character._id)
    else
      return new
    end
  end

  def show
    @character = Character.get!(params[:region], params[:realm], params[:name])
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
    # @loadout = @character.loadout || Loadout.new(:character => @character)
  end

  def refresh
    @character = Character.get!(params[:region], params[:realm], params[:name])
    flash[:reload] = Time.now.to_i
    @character.update_from_armory!(true)
    redirect_to rebuild_items_path(:c => @character._id)
  end
end
