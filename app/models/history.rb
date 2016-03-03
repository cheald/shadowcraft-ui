class History
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sha, :type => String
  field :json, :type => Hash

  index({sha: 1})
  
  # This extra index causes items to be removed automatically by mongo
  # once they are greater than a certain age.
  index({created_at: 1}, {expire_after_seconds: 1.month})

  def as_json(options={})
    val = {
      :sha => sha,
      :json => json
    }
  end
end  
