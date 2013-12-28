require 'yaml'
require 'uri'
require 'open3'
require 'csv'

class Parse
  BASE_URL = 'https://docs.google.com/spreadsheet/ccc'
  OUTPUT_FORMAT = 'csv'
  CONFIG = YAML.load IO.read('config.yml')
  LOCALES_DIRECTORY = './locales'

  def self.run
    new.dump_yaml
  end

  # Create yaml dump of resulting locales hash. Separate .yml file
  #     fore each root locale key.
  def dump_yaml
    FileUtils.mkdir_p LOCALES_DIRECTORY
    hash = build_hash
    hash.each do |k, v|
      File.open Pathname.new(LOCALES_DIRECTORY).join(k + '.yml'), 'w' do |file|
        file.write YAML.dump({k => v})
      end
    end
  end

  private

  # Read CSV stream and store parsed key/values in a hash-map using assoc_in
  #     for deep nested keys.
  #
  # @return [Hash]
  def build_hash
    hash = Hash.new
    # array of locales. excluding keys column header.
    locales = csv.shift[1..-1]
    while line = csv.shift
      key = line[0]
      line[1..-1].each_with_index do |value, i|
        assoc_in hash, locales[i], *key.split(/\./), value
      end
    end
    hash
  end

  # @return [IO] child process stdout
  def io
    stdin, stdout, stderr = Open3.popen3("wget -S -O - '#{url}'")
    stdout
  end

  # @return [CSV] CSV wrapper on IO
  def csv
    @csv ||= CSV.new io
  end

  # @return [String] formed spreadsheet url
  def url
    uri = URI(BASE_URL)
    uri.query = [uri.query, "output=#{OUTPUT_FORMAT}", "key=#{CONFIG['spreadsheet_key']}"].compact.join '&'
    uri.to_s
  end


  # Associates a value in a nested associative structure, where *keys is a
  #     array of keys and value is the new value and returns a new nested structure.
  #     If any levels do not exist, hash-maps will be created.
  #
  # @return [Hash]
  def assoc_in(hash, *keys, value)
    # Recursion base case. assoc if there is just one key.
    if keys.length == 1
      hash[keys.first] = value
    else
      k = keys.shift
      # create nested hash-map if not exist yet.
      hash[k] = hash[k].is_a?(Hash) ? hash[k] : Hash.new
      assoc_in(hash[k], *keys, value)
    end
    hash
  end
end

Parse.run
