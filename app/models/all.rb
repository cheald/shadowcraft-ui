class All
  def self.populate()
    # Populates items and gems
    Item.populate
    Enchant.update_from_json
    Artifact.populate
    Relic.populate
    Talent.populate
  end
end
