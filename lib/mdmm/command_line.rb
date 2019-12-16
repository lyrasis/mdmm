require 'mdmm'

module Mdmm
  class CommandLine < Thor
    no_commands{
      def get_colls
        colls = CONFIG.colls.map{ |cpath| Mdmm::Collection.new(cpath) }

        if options[:coll].empty?
          # not specifying collections will return all collections
          puts "Will process all #{colls.length} collections."
          return colls
        else
          # return only the specified collections
          allcollnames = colls.map{ |c| c.name }
          enteredcollnames = options[:coll].split(',')
          enteredcollnames.each{ |c|
            unless allcollnames.include?(c)
              puts "There is no collection directory named #{c}"
              puts "Run `exe/mdmm list_colls` to see known collections in your config."
              exit
            end
          }
          docolls = colls.select{ |coll| enteredcollnames.include?(coll.name) }
          puts "Will process #{docolls.length} collection(s)."
          return docolls
        end
      end #get_colls
    }
    
    map %w[--version -v] => :__version
    desc '--version, -v', 'print the version'
    def __version
      puts "MDMM version #{Mdmm::VERSION}, installed #{File.mtime(__FILE__)}"
    end

    map %w[--config -c] => :__config
    desc '--config, -c', 'print out your config settings, including list of site names'
    def __config
      puts "\nYour project working directory:"
      puts Mdmm::WRK_DIR
      puts "\nLogfile path:"
      puts Mdmm::CONFIG.logfile
      puts "\nField prefixes ignored in reporting:"
      puts Mdmm::CONFIG.reporting_ignore_field_prefixes
    end

    desc 'list_colls', 'list directories that will be treated as collections'
    def list_colls
      puts "\nDirectories to be treated as collections:"
      Mdmm::CONFIG.colls.each { |c|
        puts c
      }
    end

    desc 'list_splits', 'pretty print the field-splitting configuration'
    def list_splits
      s = Mdmm::CONFIG.splits
      pp(s)
    end

    desc 'list_mappings', 'pretty print the MODS mappings for collections'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def list_mappings
      colls = get_colls
      colls.each{ |c|
        coll = c.name
        puts "\nMappings for: #{coll}"
        Mdmm::CONFIG.mappings[coll].each{ |m| puts m }
      }
    end

    desc 'list_collection_fields', 'get collection info per site, build coll dirs, save metadata'
    long_desc <<-LONGDESC
`exe/mdmm list_collection_fields` produces a csv file of the descriptive metadata fields used in item records for each collection.

This file is written to: `wrk_dir/_fields.csv` and lists the CDM collection (or Omeka site), followed by the metadata field name (Omeka) or nickname (CDM).

The data in this file is appropriate for incorporating into metadata mapping documents.

Assumes migration records have already been created using cdmtools or omeka-data-tools.
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def list_collection_fields
      colls = get_colls
      Mdmm::FieldLister.new(colls)
    end

    desc 'compile_field_values', 'get collection info per site, build coll dirs, save metadata'
    long_desc <<-LONGDESC
`exe/mdmm compile_field_values` produces a csv file of the raw data values in every field in every record in the specified collection(s). 

This file is written to: `wrk_dir/_fieldvalues.csv`.

Each row has the following data: collection name; field name; field value; record id.

The data in this file is appropriate for incorporating into loading into OpenRefine or another analysis tool.

Assumes migration records have already been created using cdmtools or omeka-data-tools.

TYPE: Specify whether you want the report created using migrecords (standardized form of original data) or clean records (where data has been cleaned/changed).

FORMAT: report format. `exploded` produces csv with one row per field per record. `compact` produces csv with one row per record and one column per field.
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    option :type, :desc => 'Record type to report on. Enter one of the following: mig or clean'
    option :format, :desc => 'Format of the output: compact or exploded', :default => 'compact'
    def compile_field_values
      colls = get_colls
      unless %w[clean mig].include?(options[:type])
        puts "Please enter one of the following for the type: mig or clean"
        exit
      end
      Mdmm::FieldValueCompiler.new(colls, options[:type], options[:format])
    end

    desc 'clean_records', 'cleans migrecords, saving them as cleanrecords'
    long_desc <<-LONGDESC
`exe/mdmm clean_records` does stuff... 
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def clean_records
      colls = get_colls
      colls.each{ |coll|
        puts "Cleaning records for collection: #{coll.name}"
        coll.clean_records
      }
    end

    desc 'map_records', 'maps cleanrecords to MODS'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def map_records
      colls = get_colls
      colls.each{ |coll|
        puts "Mapping records for collection: #{coll.name}"
        coll.map_records
      }
    end
  end # CommandLine
end # Mdmm
