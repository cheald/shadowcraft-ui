module CharactersHelper
  def char_link(char, options = {})
    character_path options.merge(char_options(char))
  end

  def char_options(char)
    {:region => char.region.downcase, :realm => char.normalize_realm(char.realm), :name => char.normalize_character(char.name)}
  end

  def patch(character)
    j = character.as_json
    j[:reload] = flash[:reload] unless flash[:reload].blank?
    j.to_json
  end
end
