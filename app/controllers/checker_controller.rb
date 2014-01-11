require 'net/http'

class CheckerController < ApplicationController
  def index
    unless params[:s].blank?
      matcher = (/^(?:(?:http|https):\/\/)?([а-яa-z0-9]+(?:[\-\.][а-яa-z0-9]+)*\.[а-яa-z]{2,5})(?::([0-9]{1,5}))?(?:\/.*)?$/ix).match(params[:s])
      if matcher.nil?
        redirect_to root_path
      else
        host = matcher[1]
        logger.info 'Redirecting ************'
        redirect_to "/#{CGI.escape host}"
      end
    end
  end

  def check
    host = (/^(?:(?:http|https):\/\/)?([а-яa-z0-9]+(?:[\-\.][а-яa-z0-9]+)*\.[а-яa-z]{2,5})(?::([0-9]{1,5}))?(?:\/.*)?$/ix).match(params[:s])[1]

    @site = host
    @code = Rails.cache.read host

    if @code.blank?

      http = Net::HTTP.new(SimpleIDN.to_ascii(host), 80)
      http.read_timeout = 0.5
      http.open_timeout = 1

      begin
        response = http.request_get('/')
        @code = response.code
      rescue => e
        logger.debug e.to_s + SimpleIDN.to_ascii(host)
        @code = -1
      end

      Rails.cache.write host, @code, :timeToLive => 5.minutes
    end

    respond_to do |format|
      format.html
    end
  end

  private
  # Using a private method to encapsulate the permissible parameters is just a good pattern
  # since you'll be able to reuse the same permit list between create and update. Also, you
  # can specialize this method with per-user checking of permissible attributes.
  def checker_params
    params.permit(:s)
  end
end
