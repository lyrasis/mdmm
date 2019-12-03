# standard library
require 'csv'
require 'json'
require 'logger'
require 'pp'
require 'yaml'

# external gems
require 'nokogiri'
require 'progressbar'
require 'thor'

module Mdmm
  autoload :VERSION, 'mdmm/version'
  autoload :CONFIG, 'mdmm/config_reader'
  autoload :LOG, 'mdmm/log'
  # silly way to make Mdmm::WRK_DIR act like a global variable
  autoload :WRK_DIR, 'mdmm/wrk_dir'

  autoload :CommandLine, 'mdmm/command_line'
  autoload :Collection, 'mdmm/collection'
  autoload :ConfigReader, 'mdmm/config_reader'

  # given array of collection objects, writes _fields.csv to WRK_DIR
  autoload :FieldLister, 'mdmm/field_lister'

  autoload :MigRecord, 'mdmm/record'
end
