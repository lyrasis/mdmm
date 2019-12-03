require 'mdmm'

module Mdmm
  class Record
    attr_reader :coll # Mdmm::Collection to which record belongs

    # initialize with Mdmm::Collection object and path to record file
    def initialize(coll, path)
      @coll = coll
    end
  end #Record class

  class MigRecord < Record
    attr_reader :rec # the record as a JSON-derived hash
    attr_reader :fields # array of fields present in record
    
    def initialize(coll, path)
      super(coll, path)
      @rec = JSON.parse(File.read(path))
      @fields = @rec.keys
    end
  end # MigRecord
end # Mdmm
