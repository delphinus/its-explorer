require 'digest/sha2'
require 'tempfile'

require './lib/util'

class VacancyData
  include Util

  def self.from_json(json)
    parsed = JSON.parse json
    date = begin
             Time.strptime parsed['date'], '%F %T'
           rescue => e
             Time.now
           end
    self.new date: date, vacancies: parsed['vacancies'] || {}
  end

  def self.from_hash(hash)
    self.new vacancies: hash
  end

  def initialize(date: Time.now, vacancies: {})
    raise 'cannot execute `diff`' unless command? 'diff'
    @date = date
    @vacancies = vacancies
  end

  def to_digest
    Digest::SHA256.hexdigest JSON.generate @vacancies
  end

  def ==(vacancy_data)
    target = if vacancy_data.respond_to? :to_digest
               vacancy_data.to_digest
             else
               vacancy_data.to_s
             end
    self.to_digest == target
  end

  def to_s
    @vacancies.reduce(
      "fetched: #{@date.strftime '%F %T'}\n"
    ) do |str, (hotel, vacancies)|
      str += "#{hotel}\n"
      if vacancies.length == 0
        str += "  なし\n"
      else
        vacancies.each do |date|
          date_str = if date.respond_to? 'strftime'
                       date.strftime '%F (%a)'
                     else
                       date.to_s
                     end
          str += "  #{date_str}\n"
        end
      end
      str
    end
  end

  def to_json
    JSON.generate({
      date:      @date,
      vacancies: @vacancies
    })
  end

  def diff_from(previous)
    new_file = Tempfile.open 'new_result'
    new_file.write self
    new_file.close
    previous_file = Tempfile.open 'previous_result'
    previous_file.write previous
    previous_file.close
    `diff -u #{previous_file.path} #{new_file.path}`.force_encoding('UTF-8').scrub('?').sub /\A.*\n.*\n/, ''
  end
end
