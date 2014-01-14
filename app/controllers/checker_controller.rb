require 'net/http'

class CheckerController < ApplicationController
  def index
    if !params[:s].blank?
      matcher = (/^(?:(?:http|https):\/\/)?([а-яa-z0-9]+(?:[\-\.][а-яa-z0-9]+)*\.[а-яa-z]{2,5})(?::([0-9]{1,5}))?(?:\/.*)?$/ix).match(params[:s])
      if matcher.nil?
        redirect_to root_path
      else
        host = matcher[1]
        redirect_to "/#{CGI.escape host}"
      end
    elsif params[:from_form]
      redirect_to '/example.org'
    end
  end

  def check
    host = (/^(?:(?:http|https):\/\/)?([а-яa-z0-9]+(?:[\-\.][а-яa-z0-9]+)*\.[а-яa-z]{2,5})(?::([0-9]{1,5}))?(?:\/.*)?$/ix).match(params[:s])[1]

    @site = host
    cache = Rails.cache.read host
    logger.debug cache
    @cached = JSON.parse(cache) unless cache.blank?

    if @cached.blank?
      @cached = Hash.new

      http = Net::HTTP.new(SimpleIDN.to_ascii(host), 80)
      http.read_timeout = 0.5
      http.open_timeout = 1

      begin
        response = http.request_get('/')
        @cached['code'] = response.code
      rescue => e
        logger.debug e.to_s + SimpleIDN.to_ascii(host)
        @cached['code'] = -1
      end

      Rails.cache.write host, {:code => @cached['code'], :cached_at => Time.now.to_i}.to_json.to_s, :expires_in => 5.minutes
    end

    logger.debug @cached['cached_at']

    respond_to do |format|
      format.html
    end
  end

  private
# Using a private method to encapsulate the permissible parameters is just a good pattern
# since you'll be able to reuse the same permit list between create and update. Also, you
# can specialize this method with per-user checking of permissible attributes.
  def checker_params
    params.permit(:s, :from_form)
  end

end
