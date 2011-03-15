class ApplicationController < ActionController::Base
  rescue_from Mongoid::Errors::DocumentNotFound, :with => :missing
  rescue_from ActionController::InvalidAuthenticityToken, :with => :cookie_warning
  rescue_from Curl::Err::TimeoutError, :with => :error

  def error
    render :template => "errors/500"
  end

  def missing
    render :template => "errors/404"
  end

  private

  def cookie_warning
    render :template => "errors/bad_auth"
  end

  def character_options(char)
    {:region => char.region.downcase, :realm => char.realm.downcase.gsub(/ /, "-"), :name => char.normalize_character(char.name)}
  end
end
