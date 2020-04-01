
require 'mdmm'

module Mdmm
  class Record
    attr_reader :coll # Mdmm::Collection to which record belongs
    attr_reader :json # the record as a JSON-derived hash
    attr_reader :fields # array of fields present in record
    attr_reader :reportfields # array of fields included in reporting
    attr_reader :id
    attr_reader :filetype # String. File type suffix
    attr_reader :contentmodel # String. Islandora content model assigned to record
    attr_reader :children # Array. List of pointers to child objects
    
    # initialize with Mdmm::Collection object and path to record file
    def initialize(coll, path)
      @coll = coll
      @json = JSON.parse(File.read(path))
      @fields = @json.keys
      @reportfields = get_reportfields
      if @json['migptr']
        @id = @json['migptr']
      else
        @id = @json['dmrecord']
      end
      @filetype = @json['migfiletype'].downcase if @json['migfiletype']
      @contentmodel = @json['islandora_content_model'] if @json['islandora_content_model']
      @children = set_children
      self
    end

    def has_field?(fieldname)
      return true if @json[fieldname] && !@json[fieldname].empty?
      return false
    end

    def is_compound?
      return true if @json['migobjcategory'] == 'compound'
      return false
    end
    
    def is_external_media?
      return true if @json['migobjcategory'] == 'external media'
      return true if @json['externalmedialink']
      return false
    end

    def in_subcollection?
      return true if @json['migcollectionset']
      return false
    end

    def subcollection
      @json['migcollectionset']
    end

    def mods_path
      "#{@coll.modsdir}/#{@id}.xml"
    end

    def has_mods?
      return true if File::exist?(mods_path)
    end

    def obj_path
      "#{@coll.objdir}/#{@id}.#{@filetype}"
    end

    def has_obj?
      return true if File::exist?(obj_path)
    end

    def tn_path
      jpgpath = "#{@coll.tndir}/#{@id}.jpg"
      return jpgpath if File::exist?(jpgpath)
      pngpath = "#{@coll.tndir}/#{@id}.png"
      return pngpath if File::exist?(pngpath)
      return nil
    end

    def has_tn?
      return true if tn_path && File::exist?(tn_path)
    end
    
    private

    def set_children
      if @json['migchildptrs']
        @children = @json['migchildptrs'] if @json['migchildptrs'].is_a?(Array)
        @children = @json['migchildptrs'].split(Mdmm::CONFIG.multivalue_delimiter) if @json['migchildptrs'].is_a?(String)
      else
        @children = []
      end
    end

    def get_reportfields
      rfields = @fields.clone
      Mdmm::CONFIG.reporting_ignore_field_prefixes.each{ |prefix|
        rfields.reject!{ |f| f.start_with?(prefix) }
      }
      @reportfields = rfields
    end

  end #Record class

  class MigRecord < Record
    attr_reader :cleanfields # array of fields included in cleaning
    
    def initialize(coll, path)
      super(coll, path)
      @cleanfields = get_cleanfields
    end

    def clean
      Mdmm::RecordCleaner.new(self)
    end
    
    private

    def get_cleanfields
      cleanfields = @fields.clone
      Mdmm::CONFIG.cleanup_ignore_field_prefixes.each{ |prefix|
        cleanfields = cleanfields.reject{ |f| f.start_with?(prefix)}
      }
      @cleanfields = cleanfields
    end

  end # MigRecord

  class CleanRecord < Record
    attr_reader :childrecs # Array of CleanRecords for child objects
    attr_reader :childtypes # Array of filetypes of child objects
    
    def initialize(coll, path)
      super(coll, path)
      @childrecs = []
      @childtypes = []
      if @children.length > 0
        populate_childrecs
        populate_childtypes
      end
    end

    def map
      Mdmm::RecordMapper.new(self, @coll.mappings)
    end

    private

    def populate_childrecs
      @children.each{ |childptr|
        @childrecs << Mdmm::CleanRecord.new(@coll, "#{@coll.cleanrecdir}/#{childptr}.json")
      }
    end

    def populate_childtypes
      h = {}
      @childrecs.each{ |child| h[child.filetype] = 0 }
      keys = h.keys
      
      keys = keys.sort unless keys.empty?
      @childtypes = keys
    end
    
  end # CleanRecord
end # Mdmm
