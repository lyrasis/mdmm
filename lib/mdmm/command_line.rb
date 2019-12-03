require 'mdmm'

module Mdmm
  class CommandLine < Thor
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
      puts "\nYour Omeka sites:"
      Mdmm::CONFIG.sites.each { |s|
        site = Mdmm::Site.new(s)
        puts site.name
      }
    end
    
    desc 'get_coll_info', 'get collection info per site, build coll dirs, save metadata'
    long_desc <<-LONGDESC
Collection information is gathered via the ListSets OAI verb. A site may have one, many, or no collections.

If a site has no collections, a single collection is created with the same name as the site. This preserves the site>collection hierarchy for the rest of the processing. The collid assigned to this mock collection will be 0.

For each collection, a directory is created in the site directory. The collection directory name is `coll_{collid}`.

The collid value is the SetSpec number in OAI, and the `:id` value used in the REST API.

For each collection, the Dublin Core description is saved to `coll_dir/_{collid}_DC.xml`. If there is no Dublin Core description for the collection (and the collection in not a mock collection), a warning is written to the log.

_collections.json is written in each site directory to persist collection info.

If _collections.json exists in a site directory, calling `get_coll_info` without `--force=true` will display collection info from the persisted JSON.

If _collections.json does not exist for a site, an OAI request will generate it. 
    LONGDESC
    option :site, :desc => 'comma-separated list of site names to include in processing', :default => ''
    option :force, :desc => 'boolean (true, false) - whether to force refresh of data', :default => false
    def get_coll_info
      sites = get_sites
      sites.each { |site| site.process_colls(options[:force]) }
    end

  end # CommandLine
end # Mdmm
