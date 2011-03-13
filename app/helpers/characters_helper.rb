module CharactersHelper
  def char_link(char, options = {})
    character_path options.merge(char_options(char))
  end

  def char_options(char)
    {:region => char.region.downcase, :realm => char.normalize_realm(char.realm), :name => char.normalize_character(char.name)}
  end
end
