require 'capybara/poltergeist'
require 'uri'

require './lib/util'

class Scraper
  include Util

  HOTEL_NAME = %w[
    トスラブ箱根ビオーレ
    トスラブ箱根和奏林
  ]
  TOP_URL = URI 'https://as.its-kenpo.or.jp/service_category/index'
  FIRST_LINK_TEXT = '直営・通年・夏季保養施設(空き照会)'

  def initialize(log:)
    @log = log
    raise 'cannot find phantomjs' unless command? 'phantomjs'
  end

  def setup
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new app, inspector: true
    end

    Capybara.configure do |config|
      config.run_server = false
      config.default_driver = :poltergeist
      config.app_host = TOP_URL.scheme + '://' + TOP_URL.host
    end

    @browser = Capybara::Session.new :poltergeist
    @browser.driver.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/601.6.17 (KHTML, like Gecko) Version/9.1.1 Safari/601.6.17'
  end

  def start
    @browser.visit TOP_URL
    @log.debug "show #{TOP_URL}"
    @browser.first(:link, FIRST_LINK_TEXT).click
    @log.debug "click #{FIRST_LINK_TEXT}"
  end

  def fetch_vacancies
    HOTEL_NAME.each_with_object({}) do |hotel, result|
      result[hotel] ||= []

      @browser.click_link hotel
      @log.debug "click #{hotel}"

      @browser.find_all(:xpath, "//a[contains(., '#{hotel}')]").map do |n|
        n.text
      end.each do |link_text|
        @browser.click_link link_text
        @log.debug "click #{link_text}"

        @browser.find_all(:xpath, '//select[@id="apply_join_time"]/option').each do |option|
          if option.text != '' && parsed_date = Date.strptime(option.text, '%Y年%m月%d日')
            result[hotel].push parsed_date
            @log.debug "found vacancy: #{hotel} - #{parsed_date.strftime '%Y-%m-%d'}"
          end
        end

        @browser.go_back
        @log.debug 'go back'
      end

      @browser.go_back
      @log.debug 'go back'
    end
  end
end
