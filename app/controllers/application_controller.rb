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
end
