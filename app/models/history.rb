class History
  include Mongoid::Document

  field :sha, :type => String
  field :json, :type => Hash

  index({sha: 1})

  def as_json(options={})
    val = {
      :sha => sha,
      :json => json
    }
  end
end  
