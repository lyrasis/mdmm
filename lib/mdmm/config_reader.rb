require 'mdmm'

module Mdmm
  class ConfigReader
    attr_reader :wrk_dirs
    attr_reader :logfile
    attr_reader :colls # array of collection paths
    attr_reader :reporting_ignore_field_prefixes
    attr_reader :fieldvalues_file
    attr_reader :cleanup_ignore_field_prefixes
    attr_reader :mv_delimiter
    attr_reader :prelim_replacements
    attr_reader :replacements
    attr_reader :splits
    attr_reader :case_changes
    attr_reader :move_fields
    attr_reader :post_move_fields
    attr_reader :move_and_replaces
    attr_reader :derive_fields
    attr_reader :extractions
    attr_reader :constant_fields
    attr_reader :date_fields
    attr_reader :mappings
    
    def initialize
      config = YAML.load_file('config/config.yaml')
      @wrk_dirs = config['wrk_dirs']
      @logfile = config['logfile']
      @colls = []
      set_colls
      @reporting_ignore_field_prefixes = config['reporting_ignore_field_prefixes']
      @fieldvalues_file = config['fieldvalues_file']
      @cleanup_ignore_field_prefixes = config['cleanup_ignore_field_prefixes']
      @mv_delimiter = config['mv_delimiter']
      @prelim_replacements = config['prelim_replacements']
      @replacements = config['replacements']      
      @splits = config['splits']
      @case_changes = config['case_changes']
      @move_fields = config['move_fields']
      #      @post_move_fields = config['post_move_fields']
      @move_and_replaces = config['move_and_replaces']
      @derive_fields = config['derive_fields']
      @extractions = config['extractions']
      @constant_fields = config['constant_fields']
      @date_fields = config['date_fields']
      @mappings = get_mappings(config['mappings'])
    end

    private

    def set_colls
      @wrk_dirs.each{ |wrk_dir|
        children = Dir.children(wrk_dir)
        colls = children.select{ |n| File.directory?("#{wrk_dir}/#{n}") }
        colls.each{ |collname| @colls << "#{wrk_dir}/#{collname}" }
      }
    end

    def get_mappings(path)
      maphash = {}
      CSV.foreach(path, headers: true) do |row|
        coll = row['coll alias']
        mapping = row['MODS']
        if maphash.has_key?(coll)
          maphash[coll] << mapping
        else
          maphash[coll] = [mapping]
        end
      end
      maphash
    end
    
      
  end

    CONFIG = Mdmm::ConfigReader.new

end
