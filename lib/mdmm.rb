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
  autoload :VERSION, 'mdmm/version'
  autoload :CONFIG, 'mdmm/config_reader'
  autoload :LOG, 'mdmm/log'
  # silly way to make Mdmm::WRK_DIR act like a global variable

  autoload :CommandLine, 'mdmm/command_line'
  autoload :Collection, 'mdmm/collection'
  autoload :ConfigReader, 'mdmm/config_reader'
  autoload :DateCleaner, 'mdmm/date_cleaner'

  # given array of collection objects, writes _fields.csv to WRK_DIR
  autoload :FieldLister, 'mdmm/field_lister'

  # given array of collection objects, writes _fieldvalues.csv to WRK_DIR
  autoload :FieldValueCompiler, 'mdmm/field_value_compiler'

  autoload :CleanRecord, 'mdmm/record'
  autoload :MigRecord, 'mdmm/record'

  autoload :RecordCleaner, 'mdmm/record_cleaner'
  autoload :RecordMapper, 'mdmm/record_mapper'

  # This logfile is extremely verbose, so delete it every time the application starts
  File.delete(Mdmm::CONFIG.logfile) if File::exist?(Mdmm::CONFIG.logfile)
end


