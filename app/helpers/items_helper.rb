module ItemsHelper
  def squish_stats(items)
    map = []
    items.each do |item|
      item[:stats].each do |key, val|
        unless map.index(key)
          map.push key
        end
      end
    end

    items.each do |item|
      item[:s] = Array.new(map.length).fill(0).tap do |array|
        item[:stats].each do |key, val|
          array[map.index(key)] = val
        end
      end
      item.delete :stats
    end

    return map
  end
end
