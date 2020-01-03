# standard library
require 'csv'
require 'date'
require 'json'
require 'logger'
require 'pp'
require 'yaml'

# external gems
require 'nokogiri'
require 'progressbar'
require 'thor'

module Mdmm
  require 'mdmm/version'
  require 'mdmm/config_reader'
  CONFIGPATH = ''
  CONFIG = Mdmm::ConfigReader.new

  # This logfile is extremely verbose, so delete it every time the application starts
  File.delete(Mdmm::CONFIG.logfile) if File::exist?(Mdmm::CONFIG.logfile)
  require 'mdmm/log'

  require 'mdmm/command_line'
  require 'mdmm/collection'
  require 'mdmm/config_reader'
  require 'mdmm/date_parser'

  # given array of collection objects, writes _fields.csv to WRK_DIR
  require 'mdmm/field_lister'

  # given array of collection objects, writes _fieldvalues.csv to WRK_DIR
  require 'mdmm/field_value_compiler'

  require 'mdmm/record'

  require 'mdmm/record_cleaner'
  require 'mdmm/record_mapper'
  require 'mdmm/mapping_chooser'
  require 'mdmm/mapping_checker'
  require 'mdmm/mapper'


  # -=-=-
  # Utility methods used across classes/etc
  # -=-=-
  def self.date_field?(fieldname)
    return true if Mdmm::CONFIG.date_fields.include?(fieldname)
  end

  def self.get_mapping_fields(string)
    string.scan(/%[^%]+%/).uniq.map{ |e| e.delete('%') }
  end

  
end


