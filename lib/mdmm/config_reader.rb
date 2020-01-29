require 'mdmm'

module Mdmm
  class ConfigReader
    attr_reader :path # path to config file
    attr_reader :config # the entire config hash
    attr_reader :colls # array of collection paths
    attr_reader :mappings # array of MODS mappings
    attr_reader :omitted_records # Hash. Keys = collections with records to omit. Values = Array of rec ids to omit

    def initialize(configpath = 'config/config.yaml')
      @path = configpath.is_a?(String) ? configpath : configpath[:config]
      @config = YAML.load_file(File.expand_path(@path))
      set_attributes
      @wrk_dirs.map!{ |dir| File.expand_path(dir) }
      set_colls
      @mappings = config['mappings'] ? get_mappings(config['mappings']) : {}
      set_omitted_records
      return @config
    end

    private

    def set_omitted_records
      or_config = config['omitted_records']
      unless or_config.nil? || or_config.empty?
        @omitted_records = or_config
      end
    end
    
    def set_attributes
      # reader attributes set verbatim from config are created and populated as
      #  empty arrays
      [
        'wrk_dirs',
        'logfile',
        'reporting_ignore_field_prefixes',
        'fieldvalues_file',
        'cleanup_ignore_field_prefixes',
        'date_fields',
        'prelim_replacements',
        'multivalue_delimiter',
        'splits',
        'constant_fields',
        'case_changes',
        'move_fields',
        'move_and_replaces',
        'derive_fields',
        'extractions',
        'replacements',
        'cross_multival_replacements',
        'single_mods_top_elements',
        'mods_schema'
      ].each{ |atr|
        self.class.instance_eval{ attr_reader atr.to_sym }
        instance_variable_set("@#{atr}", [])
      }

      # iterate through the config hash and set the verbatim values
      @config.each{ |k, v|
        next if k == 'mappings'
        instance_variable_set("@#{k}", v)
      }
    end
    
    def set_colls
      @colls = []
      @wrk_dirs.each{ |wrk_dir|
        wrk_dir = File.expand_path(wrk_dir)
        if Dir.exist?(wrk_dir)
        children = Dir.children(wrk_dir)
        colls = children.select{ |n| File.directory?("#{wrk_dir}/#{n}") }
        colls.each{ |collname| @colls << "#{wrk_dir}/#{collname}" }
        else
          puts "Directory #{wrk_dir} does not exist. Check your config file."
        end
      }
    end

    def get_mappings(path)
      maphash = {}
      path = File.expand_path(path)
      if File.exist?(path)
        CSV.foreach(path, headers: true) do |row|
          coll = row['coll']
          mapping = row['MODS']
          if maphash.has_key?(coll)
            maphash[coll] << mapping
          else
            maphash[coll] = [mapping]
          end
        end
        maphash
      else
        puts "Mapping file does not exist at #{path}. Check your config file."
      end
    end
    
      
  end

end
