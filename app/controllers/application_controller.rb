class ApplicationController < ActionController::Base
  rescue_from Mongoid::Errors::DocumentNotFound, :with => :missing
  rescue_from ActionController::InvalidAuthenticityToken, :with => :cookie_warning
  rescue_from Curl::Err::TimeoutError, :with => :error
  
  before_filter :recompile_coffeescript

  def error
    render :template => "errors/500"
  end

  def missing
    render :template => "errors/404"
  end

  def tini_calc
    result = Curl::Easy.http_post(url) do |curl|
      curl.timeout = 10
      curl.headers["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.A.B.C Safari/525.13"
    end
  end

  private

  def cookie_warning
    render :template => "errors/bad_auth"
  end

  def character_options(char)
    {:region => char.region.downcase, :realm => char.normalize_realm(char.realm), :name => char.normalize_character(char.name)}
  end
  
  def recompile_coffeescript
    return unless Rails.env.development?
    
    Dir.glob File.join(Rails.root, "app", "javascript", "**", "*.coffee") do |file|
      base = File.dirname(file)
      package = File.basename base
      out_package = File.join(Rails.root, "public", "javascripts", "#{package}.js")
      if !File.exists?(out_package) or File.mtime(out_package) < File.mtime(file)
        manifest = open(File.join(base, "MANIFEST")).read.split("\n").compact
        source = manifest.map do |line_item|
          line_item.strip!
          if line_item.blank?
            nil
          else
            open(File.join(base, "#{line_item}.coffee")).read
          end
        end.compact.join("\n")
        output = CoffeeScript.compile source
        File.open(out_package, "w") {|f| f.write output }
        break        
      end
    end
  end
end
