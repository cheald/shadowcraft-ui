class ApplicationController < ActionController::Base
  rescue_from Mongoid::Errors::DocumentNotFound, :with => :missing
  rescue_from ActionController::InvalidAuthenticityToken, :with => :cookie_warning
  
  before_filter :recompile_coffeescript

  # Render an error page on 500 Status code
  def error
    render :template => "errors/500"
  end

  # Render an error page on 404 Status code
  def missing
    render :template => "errors/404"
  end

  private

  # When cookie defect show an bad auth page
  def cookie_warning
    render :template => "errors/bad_auth"
  end

  # Returns normalized character data including char name, realm, and region
  def character_options(char)
    {:region => char.region.downcase, :realm => char.normalize_realm(char.realm), :name => char.normalize_character(char.name)}
  end

  # Recompiles the coffeescript files in development mode.
  # Production Mode uses the generated core.js file.
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
