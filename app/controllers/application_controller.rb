class ApplicationController < ActionController::Base
  protect_from_forgery
  
  rescue_from Mongoid::Errors::DocumentNotFound, :with => :missing
  
  private
  
  def missing
    render :template => "errors/404"
  end
end
