# standard library
require 'csv'
require 'date'
require 'fileutils'
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
  autoload :ConfigReader, 'mdmm/config_reader'
#  CONFIGPATH = ''
 # CONFIG = Mdmm::ConfigReader.new

  # This logfile is extremely verbose, so delete it every time the application starts
  #File.delete(Mdmm::CONFIG.logfile) if File::exist?(Mdmm::CONFIG.logfile)
  autoload :LOG, 'mdmm/log'

  autoload :CommandLine, 'mdmm/command_line'
  autoload :Collection, 'mdmm/collection'
  autoload :DateParser, 'mdmm/date_parser'

  # given array of collection objects, writes _fields.csv to WRK_DIR
  autoload :FieldLister, 'mdmm/field_lister'

  # given array of collection objects, writes _fieldvalues.csv to WRK_DIR
  autoload :FieldValueCompiler, 'mdmm/field_value_compiler'

  autoload :Record, 'mdmm/record'
  autoload :CleanRecord, 'mdmm/record'
  autoload :MigRecord, 'mdmm/record'
  
  autoload :RecordCleaner, 'mdmm/record_cleaner'
  autoload :RecordMapper, 'mdmm/record_mapper' #handles mapping of whole record
  autoload :Mapper, 'mdmm/mapper' #maps individual field
  autoload :DateFieldMapper, 'mdmm/mapper'
  autoload :OtherDateFieldMapper, 'mdmm/mapper'
  autoload :OrigininfoDateFieldMapper, 'mdmm/mapper'
  autoload :SingleFieldMapper, 'mdmm/mapper' #maps individual field
  autoload :MultiFieldMapper, 'mdmm/mapper' #maps individual field
  
  autoload :MappingChooser, 'mdmm/mapping_chooser'
  autoload :MappingChecker, 'mdmm/mapping_checker'
  autoload :ModsElementConsolidator, 'mdmm/mods_element_consolidator'
  autoload :ModsElementOrderer, 'mdmm/mods_element_orderer'

  autoload :IngestPlanner, 'mdmm/ingest_planner'
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


