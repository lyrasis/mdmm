require 'mdmm'

module Mdmm
  class CommandLine < Thor
    no_commands{
      def get_colls
        colls = CONFIG.colls.map{ |c| Mdmm::Collection.new(c) }

        if options[:coll].empty?
          # not specifying collections will return all collections
          return colls
        else
          # return only the specified collections
          collnames = colls.map{ |c| c.name }
          options[:coll].split(',').each{ |c|
            unless collnames.include?(c)
              puts "There is no directory named #{c} in #{Mdmm::WRK_DIR}"
              puts "Run `exe/mdmm list_colls` to see known collections in your config."
              exit
            end
            return colls.select{ |c| clist.include?(c.name) }
          }
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
    end

    desc 'list_colls', 'list directories that will be treated as collections'
    def list_colls
      puts "\nDirectories to be treated as collections:"
      Mdmm::CONFIG.colls.each { |c|
        puts "#{Mdmm::WRK_DIR}/#{c}"
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

  end # CommandLine
end # Mdmm
