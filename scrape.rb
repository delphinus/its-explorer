#!/usr/bin/env ruby
require 'logger'
require 'optparse'
require 'pathname'

require './lib/scraper'
require './lib/vacancy_data'
require './lib/vacancy_mail'

class App
  SAVE_FILE_NAME = Pathname(__FILE__).expand_path.parent + 'data.json'

  def initialize
    params = ARGV.getopts 'v'

    @log = Logger.new STDOUT
    @log.level = if params['v']
                   Logger::DEBUG
                 else
                   Logger::INFO
                 end
    @scraper = Scraper.new log: @log
    @scraper.setup
  end

  def start
    previous_result = VacancyData.from_json read_data
    @scraper.start
    new_result = VacancyData.from_hash @scraper.fetch_vacancies

    if previous_result != new_result
      write_data new_result.to_json
      @log.debug 'mail sending...'
      VacancyMail.send <<EOF
data changed
before: #{previous_result.to_digest}
after:  #{new_result.to_digest}

#{new_result.diff_from previous_result}
EOF
      @log.debug 'finish!'
    end
  end

  def read_data
    begin
      SAVE_FILE_NAME.read
    rescue => e
      @log.warn e
      '{}'
    end
  end

  def write_data(data)
    begin
      SAVE_FILE_NAME.write data
    rescue => e
      @log.error e
      exit 1
    end
  end
end

App.new.start
