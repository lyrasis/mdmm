
require 'mdmm'

module Mdmm
  class Record
    attr_reader :coll # Mdmm::Collection to which record belongs
    attr_reader :json # the record as a JSON-derived hash
    attr_reader :fields # array of fields present in record
    attr_reader :reportfields # array of fields included in reporting
    attr_reader :id

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
    end

    private

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
        cleanfields.reject!{ |f| f.start_with?(prefix) }
      }
      @cleanfields = cleanfields
    end

  end # MigRecord

  class CleanRecord < Record
    
    def initialize(coll, path)
      super(coll, path)
    end

    def map
      Mdmm::RecordMapper.new(self)
    end
  end # CleanRecord
end # Mdmm
