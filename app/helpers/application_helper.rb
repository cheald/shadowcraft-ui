module ApplicationHelper
  def mustache(name, &block)
    inner = capture(&block).gsub(/\s*\n\s*/, " ")
    concat raw "<script id='template-#{name}' type='text/x-mustache'>#{inner}</script>\n"
    nil
  end
  
  def cache_to(file, &block)
    content = ::JSMin.minify capture(&block)
    open(file, "w") {|f| f.write content }
    concat raw(content)
  end
end
