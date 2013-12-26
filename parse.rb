require 'faraday'
require 'yaml'
require 'connection_pool'


class Parse
  BASE_URL = 'https://docs.google.com/spreadsheet/ccc'
  OUTPUT_FORMAT = 'csv'
  CONFIG = YAML.load IO.read('config.yml')

  def pool
    @pool ||= ConnectionPool.new(size: 5, timeout: 20) { Faraday.new BASE_URL }
  end

  def run
    pool.with do |conn|
      conn.get nil, key: CONFIG['spreadsheet_key'], output: OUTPUT_FORMAT, ndplr: 1
    end
  end
end

response = Parse.new.run

puts response.env[:url]
puts response.body.inspect
