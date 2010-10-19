class ApplicationController < ActionController::Base
  # protect_from_forgery
  
  rescue_from Mongoid::Errors::DocumentNotFound, :with => :missing
  rescue_from ActionController::InvalidAuthenticityToken, :with => :cookie_warning
  
  private
  
  def missing
    render :template => "errors/404"
  end
  
  def cookie_warning
    render :template => "errors/bad_auth"
  end
end
