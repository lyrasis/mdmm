require 'mdmm'

module Mdmm
  class Cleanup < Thor
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

    desc 'recs_missing_objs', 'deletes all records which have no associated object files'
    long_desc <<-LONGDESC
`exe/mdmm recs_missing_objs` deletes clean, mig, and original metadata records that have no associated object file
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def recs_missing_objs
      get_colls.each{ |coll|
        puts "\n#{coll.name}"
        coll.clear_recs(coll.recs_missing_objs)
      }
    end

  end #class Cleanup

  class IngestPrep < Thor
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
    
    desc 'plan', 'produces an ingest package creation plan to review before actual ingest package creation'
    long_desc <<-LONGDESC
`exe/mdmm plan_ingest` produces `_ingest_plan.json` file in collection directory which specifies the intended directory structure of the ingest packages to be created.

This file is used to execute the actual ingest package creation, so you can edit it manually to account for any strange things.

This file is also used to reverse ingest package creation, if you need to re-run object validation or metadata cleaning/transformation steps
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def plan
      colls = get_colls
      colls.each{ |coll|
        puts "Planning ingest for collection: #{coll.name}"
        Mdmm::IngestPlanner.new(coll)
      }
    end

    desc 'print', 'prints ingest package plan for examination'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def print
      colls = get_colls
      colls.each{ |coll|
        Mdmm::IngestPlan.new(coll).print
      }
    end

    desc 'list_packages', 'prints list of packages that will be created'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def list_packages
      colls = get_colls
      colls.each{ |coll|
        Mdmm::IngestPlan.new(coll).list_packages
      }
    end

    desc 'list_omitted_objs', 'prints list of objects that are not included in the ingest packages'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def list_omitted_objs
      colls = get_colls
      colls.each{ |coll|
        Mdmm::IngestPlan.new(coll).list_omitted_objs
      }
    end

    desc 'execute_plan', 'executes the ingest package generation plan'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def execute_plan
      colls = get_colls
      colls.each{ |coll|
        Mdmm::IngestPlan.new(coll).execute_plan
      }
    end

    desc 'reverse_plan', 'reverses the ingest package generation plan, restoring original flat file structure'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def reverse_plan
      colls = get_colls
      colls.each{ |coll|
        Mdmm::IngestPlan.new(coll).reverse_plan
      }
    end

  end #class IngestPrep < Thor

  class Report < Thor
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

    desc 'colls', 'list directories that will be treated as collections'
    def colls
      puts "\nDirectories to be treated as collections:"
      Mdmm::CONFIG.colls.each { |c|
        puts c
      }
    end

    desc 'splits', 'pretty print the field-splitting configuration'
    def splits
      s = Mdmm::CONFIG.splits
      pp(s)
    end

    desc 'mappings', 'pretty print the MODS mappings for collections'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def mappings
      colls = get_colls
      colls.each{ |c|
        coll = c.name
        puts "\nMappings for: #{coll}"
        Mdmm::CONFIG.mappings[coll].each{ |m| puts m }
      }
    end

    desc 'collection_fields', 'get collection info per site, build coll dirs, save metadata'
    long_desc <<-LONGDESC
`exe/mdmm collection_fields` produces a csv file of the descriptive metadata fields used in item records for each collection.

This file is written to: `wrk_dir/_fields.csv` and lists the CDM collection (or Omeka site), followed by the metadata field name (Omeka) or nickname (CDM).

The data in this file is appropriate for incorporating into metadata mapping documents.

Assumes migration records have already been created using cdmtools or omeka-data-tools.
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def collection_fields
      colls = get_colls
      Mdmm::FieldLister.new(colls)
    end

    desc 'recs_missing_objs', 'list records having no object files'
    long_desc <<-LONGDESC
`exe/mdmm recs_missing_objs` prints a list of coll/id pairs where there is no object file for the record.

It is based on cleanrecs, because some external media records are only identified as such after being cleaned.

Records tagged as metadata only or external media are not reported, since these are known to lack objects. 
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def recs_missing_objs
      get_colls.each{ |coll|
        puts "\n#{coll.name}"
        coll.recs_missing_objs.each{ |i| puts "  #{i}" }
      }
    end

    desc 'objs_missing_recs', 'lists paths to objects not described by any record'
    long_desc <<-LONGDESC
`exe/mdmm objs_missing_recs` prints a list of paths to objects not described by any mig or clean record 
LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
def objs_missing_recs
  get_colls.each{ |coll|
    puts "\n#{coll.name}"
    puts coll.objs_missing_recs
  }
end

    desc 'object_type_hash', 'prints hash of objects by Islandora content model'
    long_desc <<-LONGDESC
`exe/mdmm object_type_hash` prints a hash of objects by Islandora content model
    LONGDESC
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def object_type_hash
      Mdmm::ObjectTypeHash.new(get_colls)
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
  end
  
  class CommandLine < Thor
    def initialize(*args)
      super(*args)
      Mdmm.const_set('CONFIG', Mdmm::ConfigReader.new(config: options[:config]))
    end
    
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

    class_option :config,
      desc: 'Path to YAML config file. If not specified, uses default value',
      type: 'string',
      default: 'config/config.yaml',
      aliases: '-c'
    
    map %w[--version -v] => :__version
    desc '--version, -v', 'print the version'
    def __version
      puts "MDMM version #{Mdmm::VERSION}, installed #{File.mtime(__FILE__)}"
    end

    map %w[show_config -s] => :__show_config
    desc 'show_config, -s', 'print out your config settings, including list of site names'
    def __show_config
      pp(Mdmm::CONFIG)
    end

    desc 'ingestprep SUBCOMMAND ...ARGS', 'create, test, execute, and reverse ingest plans for collections'
    subcommand 'ingestprep', IngestPrep
    
    desc 'report SUBCOMMAND ...ARGS', 'get stats, reports, other info'
    subcommand 'report', Report

    desc 'cleanup SUBCOMMAND ...ARGS', 'do various cleanup of records and objects'
    subcommand 'cleanup', Cleanup


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

    desc 'validate_mods', 'copies mods directory for each collection to a given directory, for sending to client'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    def validate_mods
      colls = get_colls
      colls.each{ |coll|
        coll.validate_mods
      }
    end

    desc 'compile_mods', 'copies mods directory for each collection to a given directory, for sending to client'
    option :coll, :desc => 'comma-separated list of coll names to include in processing', :default => ''
    option :path, :desc => 'path to directory in which to save collection MODS directories'
    def compile_mods
      colls = get_colls
      colls.each{ |coll|
        coll.compile_mods(options[:path])
      }
    end

  end # CommandLine

  
end # Mdmm
